import SwiftUI
import SwiftData
import Auth
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    // Queries
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    // View Models
    @StateObject private var bankViewModel = BankConnectionViewModel()
    @State private var viewModel = FinanceViewModel()
    
    // State
    @Binding var showSettings: Bool
    @State private var selectedTimeframe: Timeframe = .week
    @State private var totalBalance: Double = 0
    @State private var monthlySavings: Double = 0
    @State private var chartData: [ChartItem] = []
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    ViewHeader(title: "Dashboard", showSettings: $showSettings) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    
                    DashboardBalanceCard(
                        balance: totalBalance,
                        monthlySavings: monthlySavings
                    )
                    .padding(.horizontal)
                    
                    BankAccountsSection(
                        accounts: accounts,
                        bankViewModel: bankViewModel,
                        authViewModel: authViewModel
                    )
                    
                    AnalyticsSection(
                        chartData: chartData,
                        selectedTimeframe: $selectedTimeframe
                    )
                    
                    RecentTransactionsSection(
                        transactions: transactions,
                        categories: categories
                    )
                    
                    Color.clear.frame(height: 100)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            
            fabSection
        }
        .environment(\.locale, settingsManager.locale)
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView()
        }
        .sheet(isPresented: $bankViewModel.isLinkActive) {
            PlaidLinkContainerView(bankViewModel: bankViewModel, authViewModel: authViewModel)
        }
        .onAppear { recalculateDashboard() }
        .onChange(of: transactions) { recalculateDashboard() }
        .onChange(of: accounts) { recalculateDashboard() }
        .onChange(of: selectedTimeframe) { recalculateDashboard() }
        .alert(settingsManager.localizedString(for: "Bank Error"), isPresented: Binding(
            get: { bankViewModel.errorMessage != nil },
            set: { _ in bankViewModel.errorMessage = nil }
        )) {
            Button(settingsManager.localizedString(for: "OK"), role: .cancel) { }
        } message: {
            if let error = bankViewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    
    private var fabSection: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue, in: Circle())
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func recalculateDashboard() {
        Task(priority: .userInitiated) {
            let currentAccounts = accounts
            let currentTransactions = transactions
            let currentTimeframe = selectedTimeframe

            let newBalance = currentAccounts.reduce(0) { $0 + $1.balance }
            let newSavings = viewModel.calculateMonthlySavings(transactions: currentTransactions)
            let newChartData = generateChartData(transactions: currentTransactions, timeframe: currentTimeframe)

            await MainActor.run {
                withAnimation {
                    self.totalBalance = newBalance
                    self.monthlySavings = newSavings
                    self.chartData = newChartData
                }
            }
        }
    }

    private var chartDayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = settingsManager.locale
        f.dateFormat = "EEE"
        return f
    }

    private var chartMonthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = settingsManager.locale
        f.dateFormat = "MMM"
        return f
    }

    private func generateChartData(transactions: [Transaction], timeframe: Timeframe) -> [ChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var items: [ChartItem] = []

        // Optimization: Pre-filter expenses
        let expenses = transactions.filter { !$0.isIncome }

        switch timeframe {
        case .week:
            let last7Days = (0..<7).reversed().compactMap { i in
                calendar.date(byAdding: .day, value: -i, to: today)
            }
            let groupedByDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            
            for date in last7Days {
                let label = calendar.isDateInToday(date) ? settingsManager.localizedString(for: "Today") : chartDayFormatter.string(from: date)
                let daySpend = groupedByDay[date]?.reduce(0) { $0 + $1.amount } ?? 0
                items.append(ChartItem(label: label, amount: daySpend, date: date))
            }
        case .month:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return [] }
            for week in 1...4 {
                let startDay = (week - 1) * 7
                guard let weekStart = calendar.date(byAdding: .day, value: startDay, to: startOfMonth),
                      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                let weekSpend = expenses.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.amount }
                items.append(ChartItem(label: "W\(week)", amount: weekSpend, date: weekStart))
            }
        case .year:
            let last6Months = (0..<6).reversed().compactMap { i in
                calendar.date(byAdding: .month, value: -i, to: today)
            }
            for date in last6Months {
                let label = chartMonthFormatter.string(from: date)
                let monthSpend = expenses.filter { 
                    calendar.isDate($0.date, equalTo: date, toGranularity: .month) && 
                    calendar.isDate($0.date, equalTo: date, toGranularity: .year) 
                }.reduce(0) { $0 + $1.amount }
                items.append(ChartItem(label: label, amount: monthSpend, date: date))
            }
        }
        return items
    }
}
