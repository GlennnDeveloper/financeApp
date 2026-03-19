import SwiftUI
import SwiftData
import Auth
import Charts

enum AnalyticsViewType: String, CaseIterable {
    case net = "Net"
    case expenses = "Expenses"
    case income = "Income"
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    // ... Queries ...
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
    @State private var previousPeriodSpend: Double = 0
    @State private var previousPeriodIncome: Double = 0
    @State private var topCategories: [SpendingCategoryData] = []
    @State private var showAddSheet = false
    @State private var recalculateTask: Task<Void, Never>? = nil
    @State private var analyticsType: AnalyticsViewType = .expenses
    @State private var chartYMax: Double = 0
    @State private var selectedChartItem: ChartItem? = nil
    
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
                            previousExpenses: previousPeriodSpend,
                            previousIncome: previousPeriodIncome,
                            topCategories: topCategories,
                            selectedTimeframe: $selectedTimeframe,
                            analyticsType: $analyticsType,
                            yMax: chartYMax,
                            selectedItem: $selectedChartItem
                        )
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        forecastSection
                        .padding(.horizontal)
                        .padding(.top, 4)
                        
                        SpendingCarouselCard(transactions: transactions, categories: categories)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    .frame(height: 414)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    
                    RecentTransactionsSection(
                        transactions: transactions,
                        categories: categories
                    )
                    
                    Color.clear.frame(height: 100)
                }
            }
            .scrollContentBackground(.hidden)
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        withAnimation {
                            selectedChartItem = nil
                        }
                    }
            )
            
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
        .onChange(of: analyticsType) { recalculateDashboard() }
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
        
        let currentAccounts = accounts.map { (balance: $0.balance, isLiability: $0.isLiability ?? false) }
        let currentTimeframe = selectedTimeframe
        let currentType = analyticsType
        
        recalculateTask = Task(priority: .userInitiated) {
            let newBalance = currentAccounts.reduce(0) { $0 + ($1.isLiability ? -$1.balance : $1.balance) }
            
            await MainActor.run {
                guard !Task.isCancelled else { return }
                
                withAnimation {
                    self.totalBalance = newBalance
                    self.monthlySavings = viewModel.calculateMonthlySavings(transactions: transactions)
                    self.savingsRate = viewModel.calculateSavingsRate(transactions: transactions)
                    self.chartData = generateChartData(transactions: transactions, timeframe: currentTimeframe, type: currentType)
                    
                    // Unified Y-axis scale across income AND expenses
                    let fullData = generateChartData(transactions: transactions, timeframe: currentTimeframe, type: .net)
                    let absoluteMax = fullData.map(\.amount).max() ?? 0
                    self.chartYMax = max(absoluteMax, 10) // Lower bound for safety
                    
                    // Specific trend calculations
                    self.previousPeriodSpend = calculatePreviousPeriodTotal(transactions: transactions, timeframe: currentTimeframe, isIncome: false)
                    self.previousPeriodIncome = calculatePreviousPeriodTotal(transactions: transactions, timeframe: currentTimeframe, isIncome: true)
                    
                    self.topCategories = viewModel.calculateTopCategories(transactions: transactions, categories: categories, timeframe: currentTimeframe)
                    
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

    private func generateChartData(transactions: [Transaction], timeframe: Timeframe, type: AnalyticsViewType) -> [ChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var items: [ChartItem] = []

        let expenses = transactions.filter { !$0.isIncome }
        let income = transactions.filter { $0.isIncome }

        switch timeframe {
        case .week:
            let last7Days = (0..<7).reversed().compactMap { i in
                calendar.date(byAdding: .day, value: -i, to: today)
            }
            let groupedExpenses = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
            let groupedIncome = Dictionary(grouping: income) { calendar.startOfDay(for: $0.date) }
            
            for date in last7Days {
                let label = calendar.isDateInToday(date) ? settingsManager.localizedString(for: "Today") : chartDayFormatter.string(from: date)
                
                if type == .expenses || type == .net {
                    let spend = groupedExpenses[date]?.reduce(0) { $0 + $1.amount } ?? 0
                    items.append(ChartItem(label: label, amount: spend, date: date, type: .expense))
                }
                
                if type == .income || type == .net {
                    let earn = groupedIncome[date]?.reduce(0) { $0 + $1.amount } ?? 0
                    items.append(ChartItem(label: label, amount: earn, date: date, type: .income))
                }
            }
        case .month:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return [] }
            for week in 1...4 {
                let startDay = (week - 1) * 7
                guard let weekStart = calendar.date(byAdding: .day, value: startDay, to: startOfMonth),
                      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                
                if type == .expenses || type == .net {
                    let weekSpend = expenses.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.amount }
                    items.append(ChartItem(label: "W\(week)", amount: weekSpend, date: weekStart, type: .expense))
                }
                
                if type == .income || type == .net {
                    let weekEarn = income.filter { $0.date >= weekStart && $0.date < weekEnd }.reduce(0) { $0 + $1.amount }
                    items.append(ChartItem(label: "W\(week)", amount: weekEarn, date: weekStart, type: .income))
                }
            }
        case .year:
            let last6Months = (0..<6).reversed().compactMap { i in
                calendar.date(byAdding: .month, value: -i, to: today)
            }
            for date in last6Months {
                let label = chartMonthFormatter.string(from: date)
                
                if type == .expenses || type == .net {
                    let monthSpend = expenses.filter { 
                        calendar.isDate($0.date, equalTo: date, toGranularity: .month) && 
                        calendar.isDate($0.date, equalTo: date, toGranularity: .year) 
                    }.reduce(0) { $0 + $1.amount }
                    items.append(ChartItem(label: label, amount: monthSpend, date: date, type: .expense))
                }
                
                if type == .income || type == .net {
                    let monthEarn = income.filter { 
                        calendar.isDate($0.date, equalTo: date, toGranularity: .month) && 
                        calendar.isDate($0.date, equalTo: date, toGranularity: .year) 
                    }.reduce(0) { $0 + $1.amount }
                    items.append(ChartItem(label: label, amount: monthEarn, date: date, type: .income))
                }
            }
        }
        return items
    }

    private func calculatePreviousPeriodTotal(transactions: [Transaction], timeframe: Timeframe, isIncome: Bool) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let filtered = transactions.filter { $0.isIncome == isIncome }
        
        switch timeframe {
        case .week:
            let startOfLastWeek = calendar.date(byAdding: .day, value: -14, to: today) ?? today
            let endOfLastWeek = calendar.date(byAdding: .day, value: -7, to: today) ?? today
            return filtered.filter { $0.date >= startOfLastWeek && $0.date < endOfLastWeek }.reduce(0) { $0 + $1.amount }
            
        case .month:
            guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
                  let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth) else { return 0 }
            let endOfLastMonth = calendar.date(byAdding: .day, value: 28, to: startOfLastMonth) ?? startOfCurrentMonth
            return filtered.filter { $0.date >= startOfLastMonth && $0.date < endOfLastMonth }.reduce(0) { $0 + $1.amount }
            
        case .year:
            let startOfPrevious6Months = calendar.date(byAdding: .month, value: -12, to: today) ?? today
            let endOfPrevious6Months = calendar.date(byAdding: .month, value: -6, to: today) ?? today
            return filtered.filter { $0.date >= startOfPrevious6Months && $0.date < endOfPrevious6Months }.reduce(0) { $0 + $1.amount }
        }
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
        .padding(.bottom, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 24, padding: 20, lowRes: true)
        .drawingGroup()
    }
}
