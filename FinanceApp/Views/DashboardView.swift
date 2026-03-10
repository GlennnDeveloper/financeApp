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
                    headerSection
                    
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
        .alert("Bank Error", isPresented: Binding(
            get: { bankViewModel.errorMessage != nil },
            set: { _ in bankViewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = bankViewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSettings.toggle()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(Date.now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().locale(settingsManager.locale))
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundStyle(.gray.opacity(0.5))
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private var fabSection: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.blue, in: Circle())
                        .shadow(color: .blue.opacity(0.6), radius: 15, x: 0, y: 5)
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

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()
    
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

        switch timeframe {
        case .week:
            for i in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                let label = i == 0 ? settingsManager.localizedString(for: "Today") : chartDayFormatter.string(from: date)
                let daySpend = transactions.filter {
                    !$0.isIncome && calendar.isDate($0.date, inSameDayAs: date)
                }.reduce(0) { $0 + $1.amount }
                items.append(ChartItem(label: label, amount: daySpend, date: date))
            }
        case .month:
            guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return [] }
            for week in 1...4 {
                let startDay = (week - 1) * 7
                guard let weekStart = calendar.date(byAdding: .day, value: startDay, to: startOfMonth),
                      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else { continue }
                let weekSpend = transactions.filter {
                    !$0.isIncome && $0.date >= weekStart && $0.date < weekEnd
                }.reduce(0) { $0 + $1.amount }
                items.append(ChartItem(label: "W\(week)", amount: weekSpend, date: weekStart))
            }
        case .year:
            for i in (0..<6).reversed() {
                guard let date = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
                let label = chartMonthFormatter.string(from: date)
                let monthSpend = transactions.filter {
                    !$0.isIncome && calendar.isDate($0.date, equalTo: date, toGranularity: .month) && calendar.isDate($0.date, equalTo: date, toGranularity: .year)
                }.reduce(0) { $0 + $1.amount }
                items.append(ChartItem(label: label, amount: monthSpend, date: date))
            }
        }
        return items
    }
}

// MARK: - Dashboard Subcomponents

private struct BankAccountsSection: View {
    let accounts: [Account]
    let bankViewModel: BankConnectionViewModel
    let authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if bankViewModel.isConnected {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(SettingsManager.shared.localizedString(for: "Bank Accounts"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if bankViewModel.isLoading {
                        ProgressView().tint(.blue)
                    } else {
                        HStack(spacing: 8) {
                            Button {
                                Task { await bankViewModel.syncRemoteData(context: modelContext) }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(6)
                                    .background(.blue.opacity(0.15), in: Circle())
                            }
                            Button {
                                Task { if let session = authViewModel.session { await bankViewModel.preparePlaidLink(session: session) } }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(6)
                                    .background(.blue.opacity(0.15), in: Circle())
                            }
                            Button { bankViewModel.disconnectBank(context: modelContext) } label: {
                                Text(SettingsManager.shared.localizedString(for: "Disconnect")).font(.caption.bold()).foregroundStyle(.red).padding(.horizontal, 12).padding(.vertical, 6).background(.red.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                ForEach(accounts) { account in
                    HStack {
                        Image(systemName: account.symbol).font(.title3).foregroundStyle(.blue).frame(width: 32)
                        Text(account.name).foregroundStyle(.primary)
                        Spacer()
                        Text(account.balance, format: .currency(code: "USD")).foregroundStyle(.primary.opacity(0.7))
                    }.padding().background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                }
            }
        } else {
            Button {
                Task {
                    if let session = authViewModel.session { await bankViewModel.preparePlaidLink(session: session) }
                    else { bankViewModel.errorMessage = "Session expired." }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "building.columns.fill").font(.title2).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SettingsManager.shared.localizedString(for: "Connect Your Bank")).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        Text(SettingsManager.shared.localizedString(for: "Link an account to see balances")).font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.gray.opacity(0.5))
                }.padding(16).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }.buttonStyle(.plain).padding(.horizontal)
        }
    }
}

private struct AnalyticsSection: View {
    let chartData: [ChartItem]
    @Binding var selectedTimeframe: Timeframe
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(SettingsManager.shared.localizedString(for: "Analytics")).font(.headline).foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(Timeframe.allCases, id: \.self) { tf in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTimeframe = tf } } label: {
                            Text(tf.localizedName).font(.caption2.weight(selectedTimeframe == tf ? .bold : .medium)).foregroundStyle(selectedTimeframe == tf ? .black : .gray).padding(.horizontal, 12).padding(.vertical, 6).background(selectedTimeframe == tf ? Color.white : Color.clear, in: Capsule())
                        }
                    }
                }.background(Color(white: 0.15), in: Capsule())
            }.padding(.horizontal)
            DashboardBarChart(chartData: chartData).padding(.horizontal)
        }
    }
}

private struct RecentTransactionsSection: View {
    let transactions: [Transaction]
    let categories: [Category]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SettingsManager.shared.localizedString(for: "Recent Transactions")).font(.headline).foregroundStyle(.primary).padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(transactions.prefix(5)) { TransactionRow(transaction: $0, categories: categories) }
                if transactions.isEmpty { Text(SettingsManager.shared.localizedString(for: "No transactions yet")).foregroundStyle(.gray).padding() }
            }.padding(.horizontal)
        }
    }
}

private struct PlaidLinkContainerView: View {
    @ObservedObject var bankViewModel: BankConnectionViewModel
    let authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        if let token = bankViewModel.linkToken {
            PlaidLinkView(linkToken: token) { publicToken, metadata in
                Task { if let session = authViewModel.session { await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session) } }
            } onExit: { error in bankViewModel.handleError(error ?? NSError(domain: "Plaid", code: -1)) }
        } else {
            PlaidLinkView(linkToken: "mock-token") { publicToken, metadata in
                Task { if let session = authViewModel.session { await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session) } }
            } onExit: { _ in }
        }
    }
}

struct DashboardBalanceCard: View {
    var balance: Double
    var monthlySavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(SettingsManager.shared.localizedString(for: "Total Balance"))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Text(balance, format: .currency(code: "USD"))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(SettingsManager.shared.localizedString(for: "MONTHLY SAVINGS"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                
                Text(monthlySavings, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(.red)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

struct DashboardBarChart: View {
    var chartData: [ChartItem]
    
    var body: some View {
        VStack {
            Chart(chartData) { item in
                BarMark(
                    x: .value("Period", item.label),
                    y: .value("Spend", item.amount)
                )
                .foregroundStyle(Color.orange.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                        .font(.caption2)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: chartData)
            .frame(height: 180)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}
