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
    
    private var totalAssets: Double {
        accounts.filter { !($0.isLiability ?? false) }.reduce(0) { $0 + $1.balance }
    }
    
    private var totalLiabilities: Double {
        accounts.filter { $0.isLiability ?? false }.reduce(0) { $0 + $1.balance }
    }
    
    private var currentNetWorth: Double {
        totalAssets - totalLiabilities
    }
    
    // Calculates historical net worth over the last 6 months
    private var historicalData: [HistoricalNetWorth] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var data: [HistoricalNetWorth] = []
        
        // Empezamos con el Net Worth actual
        var runningNetWorth = currentNetWorth
        data.append(HistoricalNetWorth(date: today, amount: runningNetWorth))
        
        // Iteramos hacia atrás mes a mes
        for i in 1...5 {
            guard let previousMonthDate = calendar.date(byAdding: .month, value: -i, to: today) else { continue }
            
            // Queremos saber el NetWorth al inicio del mes anterior.
            // Para eso, tomamos el runningNetWorth y le RESTAMOS el flujo de caja neto que ocurrió en ese mes.
            // Flujo = Ingresos - Gastos
            let transactionsInMonth = transactions.filter {
                calendar.component(.month, from: $0.date) == calendar.component(.month, from: calendar.date(byAdding: .month, value: -(i-1), to: today)!) &&
                calendar.component(.year, from: $0.date) == calendar.component(.year, from: calendar.date(byAdding: .month, value: -(i-1), to: today)!)
            }
            
            let netCashFlow = transactionsInMonth.reduce(0) { total, tx in
                total + (tx.isIncome ? tx.amount : -tx.amount)
            }
            
            // Revertir el flujo de caja
            runningNetWorth -= netCashFlow
            
            // Guardar el punto en el tiempo
            data.append(HistoricalNetWorth(date: previousMonthDate, amount: runningNetWorth))
        }
        
        return data.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Header Box Network
                        VStack(spacing: 8) {
                            Text("Current Net Worth")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            
                            Text(currentNetWorth, format: .currency(code: "USD"))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        .padding(.top, 20)
                        
                        // Historic Area Chart
                        VStack(alignment: .leading) {
                            Text("6 Month Trend")
                                .font(.headline)
                                .foregroundStyle(.white)
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
                                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                                        .foregroundStyle(.gray)
                                        .font(.caption2)
                                }
                            }
                            .chartYAxis(.hidden)
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                        
                        // Breakdowns
                        VStack(spacing: 24) {
                            AccountSectionView(
                                title: "Assets",
                                accounts: accounts.filter { !($0.isLiability ?? false) },
                                total: totalAssets,
                                isLiability: false
                            )
                            
                            AccountSectionView(
                                title: "Liabilities",
                                accounts: accounts.filter { $0.isLiability ?? false },
                                total: totalLiabilities,
                                isLiability: true
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Net Worth")
            .navigationBarTitleDisplayMode(.inline)
            // Make the inline title invisible so it doesn't clutter the top, but keeps nav layout
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// Reusable Section for Assets and Liabilities
struct AccountSectionView: View {
    let title: String
    let accounts: [Account]
    let total: Double
    let isLiability: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(total, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(isLiability ? .red : .green)
            }
            
            if accounts.isEmpty {
                Text("No accounts added.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(accounts) { account in
                        HStack {
                            Image(systemName: account.symbol)
                                .font(.title3)
                                .foregroundStyle(isLiability ? .red : .blue)
                                .frame(width: 32)
                            
                            Text(account.name)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Text(account.balance, format: .currency(code: "USD"))
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
}

#Preview {
    NetWorthView()
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
}
