import SwiftUI
import SwiftData
import Charts

struct HistoricalNetWorth: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct NetWorthView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Account.orderIndex) private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @EnvironmentObject var settingsManager: SettingsManager

    // Partition accounts once, reference everywhere
    private var assets: [Account] { accounts.filter { !($0.isLiability ?? false) } }
    private var liabilities: [Account] { accounts.filter { $0.isLiability ?? false } }

    private var totalAssets: Double { assets.reduce(0) { $0 + $1.balance } }
    private var totalLiabilities: Double { liabilities.reduce(0) { $0 + $1.balance } }
    private var currentNetWorth: Double { totalAssets - totalLiabilities }
    
    @Binding var showSettings: Bool
    @State private var historicalData: [HistoricalNetWorth] = []
    
    // Asynchronous calculation of historical net worth over the last 6 months
    private func recalculateHistoricalData() {
        Task(priority: .userInitiated) {
            let currentTx = transactions // Capture snapshot
            let netWorthNow = currentNetWorth // Capture snapshot
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            var data: [HistoricalNetWorth] = []

            // 1. Pre-calculate monthly net flows for the last 6 months
            var monthlyNetFlows: [Date: Double] = [:]
            for i in 0...5 {
                if let monthDate = calendar.date(byAdding: .month, value: -i, to: today) {
                    let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
                    let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
                    
                    let netFlow = currentTx.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
                        .reduce(0) { $0 + ($1.isIncome ? $1.amount : -$1.amount) }
                    
                    monthlyNetFlows[startOfMonth] = netFlow
                }
            }

            // 2. Build the data points by stepping back from current net worth
            var runningNetWorth = netWorthNow
            data.append(HistoricalNetWorth(date: today, amount: runningNetWorth))

            for i in 1...5 {
                guard let previousMonthDate = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
                let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.date(byAdding: .month, value: -(i-1), to: today)!))!
                
                // Subtract current month's flow to get previous month's end balance
                let currentMonthFlow = monthlyNetFlows[startOfCurrentMonth] ?? 0
                runningNetWorth -= currentMonthFlow
                
                data.append(HistoricalNetWorth(date: previousMonthDate, amount: runningNetWorth))
            }

            let sortedData = data.sorted { $0.date < $1.date }
            
            await MainActor.run {
                withAnimation {
                    self.historicalData = sortedData
                }
            }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ViewHeader(title: "Net Worth", showSettings: $showSettings) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                
                VStack(spacing: 24) {
                    
                    // Header Box Network
                    VStack(spacing: 8) {
                        Text(settingsManager.localizedString(for: "Current Net Worth"))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        
                        Text(currentNetWorth, format: .currency(code: settingsManager.appCurrency))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }
                    .padding(.top, 20)
                    
                    // Historic Area Chart
                    VStack(alignment: .leading) {
                        Text(settingsManager.localizedString(for: "6 Month Trend"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal)
                        
                        Chart(historicalData) { item in
                            LineMark(
                                x: .value("Month", item.date, unit: .month),
                                y: .value("Net Worth", item.amount)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .foregroundStyle(Color.green)
                            .interpolationMethod(.monotone)
                            
                            AreaMark(
                                x: .value("Month", item.date, unit: .month),
                                y: .value("Net Worth", item.amount)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                               )
                            )
                            .interpolationMethod(.monotone)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).locale(settingsManager.locale))
                                    .foregroundStyle(.gray)
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis(.hidden)
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)
                    
                    // Breakdowns
                    VStack(spacing: 24) {
                        AccountSectionView(
                            title: settingsManager.localizedString(for: "Assets"),
                            accounts: assets,
                            total: totalAssets,
                            isLiability: false
                        )

                        AccountSectionView(
                            title: settingsManager.localizedString(for: "Liabilities"),
                            accounts: liabilities,
                            total: totalLiabilities,
                            isLiability: true
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .overlay(alignment: .top) {
            Color(uiColor: .systemGroupedBackground)
                .frame(height: 0)
                .ignoresSafeArea(edges: .top)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(\.locale, settingsManager.locale)
        .onAppear {
            recalculateHistoricalData()
        }
        .onChange(of: transactions) { _, _ in
            recalculateHistoricalData()
        }
        .onChange(of: accounts) { _, _ in
            recalculateHistoricalData()
        }
    }
}


// Reusable Section for Assets and Liabilities
struct AccountSectionView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    let title: String
    let accounts: [Account]
    let total: Double
    let isLiability: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(total, format: .currency(code: settingsManager.appCurrency))
                    .font(.headline)
                    .foregroundStyle(isLiability ? .red : .green)
            }
            
            if accounts.isEmpty {
                Text(settingsManager.localizedString(for: "No accounts added."))
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(accounts) { account in
                        HStack {
                            Image(systemName: account.symbol)
                                .font(.title3)
                                .foregroundStyle(isLiability ? .red : .blue)
                                .frame(width: 32)
                            
                            Text(account.name)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text(account.balance, format: .currency(code: settingsManager.appCurrency))
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
}

#Preview {
    NetWorthView(showSettings: .constant(false))
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
        .environmentObject(SettingsManager.shared)
}
