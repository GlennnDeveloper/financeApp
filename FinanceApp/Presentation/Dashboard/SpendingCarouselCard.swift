import SwiftUI
import Charts
import SwiftData

struct SpendingCarouselCard: View {
    let transactions: [Transaction]
    let categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager
    
    private var chartData: [SpendingCategoryData] {
        let calendar = Calendar.current
        let now = Date.now
        
        // Filter expenses for current month
        let monthlyExpenses = transactions.filter {
            !$0.isIncome &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        
        let totalSpend = monthlyExpenses.reduce(0) { $0 + $1.amount }
        let grouped = Dictionary(grouping: monthlyExpenses, by: { $0.categorySymbol })
        
        return grouped.compactMap { (symbol, txs) -> SpendingCategoryData? in
            let catTotal = txs.reduce(0) { $0 + $1.amount }
            let category = categories.first(where: { $0.symbol == symbol }) ?? Category.defaultData.first(where: { $0.symbol == symbol })
            
            return SpendingCategoryData(
                name: category?.localizedName ?? symbol,
                symbol: symbol,
                color: category?.color ?? .gray,
                totalSpent: catTotal,
                percentage: totalSpend > 0 ? (catTotal / totalSpend) : 0
            )
        }.sorted { $0.totalSpent > $1.totalSpent }
    }
    
    private var totalMonthlySpend: Double {
        chartData.reduce(0) { $0 + $1.totalSpent }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsManager.localizedString(for: "Monthly Spending"))
                        .font(.headline)
                    Text(settingsManager.localizedString(for: "Distribution by category"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.purple)
            }
            
            ZStack {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Spent", item.totalSpent),
                        innerRadius: .ratio(0.65),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", item.name))
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale(domain: chartData.map(\.name)) { name in
                    chartData.first(where: { $0.name == name })?.color ?? .gray
                }
                
                VStack {
                    Text(totalMonthlySpend, format: .currency(code: settingsManager.appCurrency))
                        .font(.title3.bold())
                    Text(settingsManager.localizedString(for: "Total"))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(height: 200)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 24, padding: 20, lowRes: true)
        .drawingGroup()
    }
}
