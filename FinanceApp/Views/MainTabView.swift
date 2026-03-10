import SwiftUI
import SwiftData
import Charts

enum Timeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Account.orderIndex) private var accounts: [Account]
    
    @State private var viewModel = FinanceViewModel()
    @StateObject private var bankViewModel = BankConnectionViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var showAddSheet = false
    @State private var showSettings = false
    @State private var selectedTimeframe: Timeframe = .week
    
    // Performance Optimization: Pre-calculated states
    @State private var totalBalance: Double = 0.0
    @State private var monthlySavings: Double = 0.0
    @State private var chartData: [ChartItem] = []
    
    var body: some View {
        SideMenuContainerView(isOpen: $showSettings) {
            // ── Side Menu ──
            SideMenuContent(isOpen: $showSettings)
                .environmentObject(authViewModel)
        } main: {
        TabView {
            // Dashboard Tab
            ZStack(alignment: .top) {
                // Background pure black
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
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

                            Text(Date.now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                                .font(.headline)
                                .foregroundStyle(.white)

                            Spacer()

                            // Placeholder right icon for visual balance
                            Image(systemName: "bell.fill")
                                .font(.title2)
                                .foregroundStyle(.gray.opacity(0.5))
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Main Balance Card
                        DashboardBalanceCard(
                            balance: totalBalance,
                            monthlySavings: monthlySavings
                        )
                        .padding(.horizontal)
                        
                        // Bank Accounts / Connect Section
                        if bankViewModel.isConnected {
                            // ── Connected: Show accounts ──
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Bank Accounts")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if bankViewModel.isLoading {
                                        ProgressView().tint(.blue)
                                    } else {
                                        HStack(spacing: 8) {
                                            Button {
                                                Task {
                                                    if let session = authViewModel.session {
                                                        await bankViewModel.preparePlaidLink(session: session)
                                                    }
                                                }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.blue)
                                                    .padding(6)
                                                    .background(.blue.opacity(0.15), in: Circle())
                                            }

                                            Button {
                                                bankViewModel.disconnectBank(context: modelContext)
                                            } label: {
                                                Text("Disconnect")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.red)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(.red.opacity(0.15), in: Capsule())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)

                                ForEach(accounts) { account in
                                    HStack {
                                        Image(systemName: account.symbol)
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                            .frame(width: 32)
                                        Text(account.name)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text(account.balance, format: .currency(code: "USD"))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    .padding()
                                    .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                }
                            }
                        } else {
                            // ── Not connected: Compact prompt ──
                            Button {
                                Task {
                                    if let session = authViewModel.session {
                                        await bankViewModel.preparePlaidLink(session: session)
                                    } else {
                                        bankViewModel.errorMessage = "Session expired. Please restart the app."
                                    }
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "building.columns.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Connect Your Bank")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text("Link an account to see balances & transactions")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.gray.opacity(0.5))
                                }
                                .padding(16)
                                .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                        
                        // Chart Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Analytics")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Spacer()
                                // Custom Timeframe Picker
                                HStack(spacing: 0) {
                                    ForEach(Timeframe.allCases, id: \.self) { tf in
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedTimeframe = tf
                                            }
                                        } label: {
                                            Text(tf.rawValue)
                                                .font(.caption2.weight(selectedTimeframe == tf ? .bold : .medium))
                                                .foregroundStyle(selectedTimeframe == tf ? .black : .gray)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(selectedTimeframe == tf ? Color.white : Color.clear, in: Capsule())
                                        }
                                    }
                                }
                                .background(Color(white: 0.15), in: Capsule())
                            }
                            .padding(.horizontal)
                            
                            DashboardBarChart(chartData: chartData)
                                .padding(.horizontal)
                        }
                        
                        // Recent Transactions Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(transactions.prefix(5)) { transaction in
                                    TransactionRow(transaction: transaction)
                                }
                                if transactions.isEmpty {
                                    Text("No transactions yet")
                                        .foregroundStyle(.gray)
                                        .padding()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Color.clear.frame(height: 100) // Space for FAB
                    }
                }
                
                // FAB - Glowing Blue Button
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
            .sheet(isPresented: $bankViewModel.isLinkActive) {
                if let token = bankViewModel.linkToken {
                    PlaidLinkView(linkToken: token) { publicToken, metadata in
                        Task {
                            if let session = authViewModel.session {
                                await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session)
                            }
                        }
                    } onExit: { error in
                        bankViewModel.handleError(error ?? NSError(domain: "Plaid", code: -1))
                    }
                } else {
                    PlaidLinkView(linkToken: "mock-token") { publicToken, metadata in
                        Task {
                            if let session = authViewModel.session {
                                await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session)
                            }
                        }
                    } onExit: { _ in }
                }
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            
            RecurringView()
                .tabItem {
                    Label("Recurring", systemImage: "calendar")
                }
            
            NetWorthView()
                .tabItem {
                    Label("Net Worth", systemImage: "chart.bar.fill")
                }
            
            SpendingView()
                .tabItem {
                    Label("Spending", systemImage: "wallet.pass")
                }
            
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAddSheet) {
            AddTransactionView()
        }
        .onAppear {
            // Clean up legacy default accounts (non-Plaid, zero balance)
            for account in accounts where account.balance == 0 && !account.name.hasPrefix("Plaid") {
                modelContext.delete(account)
            }
            viewModel.autoCategorizeTransactions(context: modelContext, transactions: transactions)
            recalculateDashboard()
        }
        .onChange(of: transactions) { _, _ in
            recalculateDashboard()
        }
        .onChange(of: accounts) { _, _ in
            recalculateDashboard()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            recalculateDashboard()
        }
        .alert("Bank Connection Error", isPresented: Binding(
            get: { bankViewModel.errorMessage != nil },
            set: { if !$0 { bankViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = bankViewModel.errorMessage {
                Text(error)
            }
        }
        } // SideMenuContainerView
    }
    
    // MARK: - Performance Optimizations
    private func recalculateDashboard() {
        Task(priority: .userInitiated) {
            let currentAccounts = accounts
            let currentTransactions = transactions
            let currentTimeframe = selectedTimeframe

            // Background calculations
            let newBalance = currentAccounts.reduce(0) { $0 + $1.balance }
            let newSavings = viewModel.calculateMonthlySavings(transactions: currentTransactions)
            let newChartData = generateChartData(transactions: currentTransactions, timeframe: currentTimeframe)

            // UI Update
            await MainActor.run {
                withAnimation {
                    self.totalBalance = newBalance
                    self.monthlySavings = newSavings
                    self.chartData = newChartData
                }
            }
        }
    }

    // Static formatters: DateFormatter is expensive to create; allocate once.
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

    private func generateChartData(transactions: [Transaction], timeframe: Timeframe) -> [ChartItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var items: [ChartItem] = []

        switch timeframe {
        case .week:
            for i in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
                let label = i == 0 ? "Today" : Self.dayFormatter.string(from: date)

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
                let label = Self.monthFormatter.string(from: date)

                let monthSpend = transactions.filter {
                    !$0.isIncome &&
                    calendar.isDate($0.date, equalTo: date, toGranularity: .month) &&
                    calendar.isDate($0.date, equalTo: date, toGranularity: .year)
                }.reduce(0) { $0 + $1.amount }

                items.append(ChartItem(label: label, amount: monthSpend, date: date))
            }
        }
        return items
    }
}

// MARK: - Subcomponents

struct DashboardBalanceCard: View {
    var balance: Double
    var monthlySavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Balance")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                
                Text(balance, format: .currency(code: "USD"))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MONTHLY SAVINGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                
                Text(monthlySavings, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(.red) // As shown in image
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
        )
    }
}

struct ChartItem: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let amount: Double
    let date: Date
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
                .fill(Color(red: 0.12, green: 0.12, blue: 0.12))
        )
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Transaction.self, Account.self], inMemory: true)
        .environmentObject(AuthViewModel())
}
