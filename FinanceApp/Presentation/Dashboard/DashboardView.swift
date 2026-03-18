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
    @State private var savingsRate: Double = 0
    @State private var chartData: [ChartItem] = []
    @State private var forecastData: [ChartItem] = []
    @State private var showAddSheet = false
    @State private var recalculateTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack(alignment: .top) {
            PremiumBackground(colors: [.orange, .green, .blue])
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    ViewHeader(title: "Dashboard", showSettings: $showSettings) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
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
                    
                    TabView {
                        AnalyticsSection(
                            chartData: chartData,
                            selectedTimeframe: $selectedTimeframe
                        )
                        .padding(.horizontal)
                        
                        forecastSection
                            .padding(.horizontal)
                        
                        SpendingCarouselCard(transactions: transactions, categories: categories)
                            .padding(.horizontal)
                    }
                    .frame(height: 340)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    
                    RecentTransactionsSection(
                        transactions: transactions,
                        categories: categories
                    )
                    
                    Color.clear.frame(height: 100)
                }
            }
            .scrollContentBackground(.hidden)
            
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
        recalculateTask?.cancel()
        
        // 1. Capture plain data on the MainActor
        let currentAccounts = accounts.map { (balance: $0.balance, isLiability: $0.isLiability ?? false) }
        let currentTimeframe = selectedTimeframe
        
        recalculateTask = Task(priority: .userInitiated) {
            // 2. Perform calculations on a background thread using plain data
            let newBalance = currentAccounts.reduce(0) { $0 + ($1.isLiability ? -$1.balance : $1.balance) }
            
            // Note: Since FinanceViewModel methods currently take [Transaction] objects, 
            // we'll run the legacy calls on the MainActor for now to avoid crashes,
            // while we plan a deeper refactor of the ViewModel.
            await MainActor.run {
                guard !Task.isCancelled else { return }
                
                withAnimation {
                    self.totalBalance = newBalance
                    self.monthlySavings = viewModel.calculateMonthlySavings(transactions: transactions)
                    self.savingsRate = viewModel.calculateSavingsRate(transactions: transactions)
                    self.chartData = generateChartData(transactions: transactions, timeframe: currentTimeframe)
                    self.forecastData = viewModel.calculateCashFlowForecast(transactions: transactions, currentBalance: newBalance)
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

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsManager.localizedString(for: "Cash Flow Forecast"))
                        .font(.headline)
                    Text(settingsManager.localizedString(for: "Projection based on recurring items"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.blue)
            }
            
            Chart {
                ForEach(forecastData) { item in
                    LineMark(
                        x: .value("Day", item.label),
                        y: .value("Balance", item.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    
                    AreaMark(
                        x: .value("Day", item.label),
                        y: .value("Balance", item.amount)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine().foregroundStyle(.white.opacity(0.05))
                    AxisValueLabel().foregroundStyle(.white.opacity(0.4))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel().foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 24, padding: 20, lowRes: true)
        .drawingGroup()
    }
}
