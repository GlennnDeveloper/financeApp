import SwiftUI

struct AnalyticsSection: View {
    let chartData: [ChartItem]
    let previousExpenses: Double
    let previousIncome: Double
    let topCategories: [SpendingCategoryData] // Moved up to match order
    @Binding var selectedTimeframe: Timeframe
    @Binding var analyticsType: AnalyticsViewType
    let yMax: Double
    @Binding var selectedItem: ChartItem?
    @EnvironmentObject var settingsManager: SettingsManager
    
    private var currentTotalIncome: Double {
        chartData.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var currentTotalExpenses: Double {
        chartData.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var percentageChange: Double? {
        let current = analyticsType == .income ? currentTotalIncome : currentTotalExpenses
        let previous = analyticsType == .income ? previousIncome : previousExpenses
        guard previous > 0 else { return nil }
        return ((current - previous) / previous) * 100
    }
    
    private var insightMessage: String? {
        if let top = topCategories.first, analyticsType != .income {
            let amountStr = top.totalSpent.formatted(.currency(code: settingsManager.appCurrency))
            let categoryName = top.name
            let timeStr = settingsManager.localizedString(for: selectedTimeframe.rawValue.lowercased())
            
            let template = settingsManager.localizedString(for: "Your biggest expense this %@ was in %@ (%@)")
            // Simple replacement if template has placeholders, otherwise fallback to concatenation
            if template.contains("%@") {
                return String(format: template, timeStr, categoryName, amountStr)
            } else {
                // Fallback to Spanish if it's the current locale and we don't have the template
                if settingsManager.appLanguage == .spanish {
                    return "Tu mayor gasto esta \(timeStr) fue en \(categoryName) (\(amountStr))"
                }
                return "Your biggest expense this \(timeStr) was in \(categoryName) (\(amountStr))"
            }
        } else if let change = percentageChange, change < -10, analyticsType == .expenses {
            return settingsManager.localizedString(for: "You're on the right track! You've spent significantly less than during the last period.")
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(settingsManager.localizedString(for: "Analytics"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    trendIndicator
                }
                
                Spacer()
                
                
                CustomTimeframeSelector(selectedTimeframe: $selectedTimeframe)
            }
            .padding(.top, 8)
            
            typeSelector
            
            insightView
            
            DashboardBarChart(
                chartData: chartData,
                yMax: yMax,
                selectedItem: $selectedItem
            )
        }
        .padding(.bottom, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .glassCard(cornerRadius: 24, padding: 12, lowRes: true)
    }
    private var typeSelector: some View {
        HStack(spacing: 4) {
            ForEach(AnalyticsViewType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.snappy(duration: 0.2, extraBounce: 0.1)) {
                        analyticsType = type
                    }
                } label: {
                    Text(settingsManager.localizedString(for: type.rawValue))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(analyticsType == type ? Color.white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background {
                            if analyticsType == type {
                                switch type {
                                case .expenses: Color.orange
                                case .income: Color.green
                                case .net: Color.blue
                                }
                            } else {
                                Color.clear
                            }
                        }
                        .clipShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }
    
    @ViewBuilder
    private var insightView: some View {
        let message = insightMessage
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
                .font(.system(size: 15, weight: .bold))
            
            ZStack(alignment: .topLeading) {
                Text(message ?? " ") // Space to keep height
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .id(message ?? "empty")
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60) // Unified height for stability
        .background(Color.yellow.opacity(message == nil ? 0 : 0.06), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.yellow.opacity(message == nil ? 0 : 0.15), lineWidth: 1)
        )
        .padding(.vertical, 4)
        .opacity(message == nil ? 0 : 1)
    }
    
    @ViewBuilder
    private var trendIndicator: some View {
        if let change = percentageChange {
            let isIncrease = change > 0
            let absChange = abs(change)
            let isIncome = analyticsType == .income
            
            HStack(spacing: 4) {
                Image(systemName: isIncrease ? "arrow.up.right" : "arrow.down.right")
                Text("\(absChange.rounded(toPlaces: 1).formatted())% \(isIncrease ? settingsManager.localizedString(for: "more") : settingsManager.localizedString(for: "less"))")
                Text(settingsManager.localizedString(for: "than last \(selectedTimeframe.rawValue.lowercased())"))
                    .foregroundStyle(.secondary)
            }
            .font(.caption2.bold())
            .foregroundStyle(isIncome ? (isIncrease ? .green : .red) : (isIncrease ? .red : .green))
        } else {
            Text(settingsManager.localizedString(for: "No data for previous period"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
