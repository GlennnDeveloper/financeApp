import SwiftUI
import Charts

struct DashboardBarChart: View {
    var chartData: [ChartItem]
    var yMax: Double
    @Binding var selectedItem: ChartItem?
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Chart(chartData) { item in
            BarMark(
                x: .value("Period", item.label),
                y: .value("Amount", item.amount)
            )
            .foregroundStyle(by: .value("Type", item.type.rawValue))
            .position(by: .value("Type", item.type.rawValue))
            .cornerRadius(4)
            .opacity(selectedItem == nil || selectedItem?.label == item.label ? 1 : 0.5)
        }
        .chartForegroundStyleScale([
            ChartItemType.income.rawValue: Color.green.gradient,
            ChartItemType.expense.rawValue: Color.orange.gradient
        ])
        .chartYScale(domain: 0...max(yMax * 1.05, 10))
        .chartLegend(.hidden)
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
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { location in
                        guard let label: String = proxy.value(atX: location.x) else {
                            selectedItem = nil
                            return
                        }
                        if let item = chartData.first(where: { $0.label == label }) {
                            if selectedItem?.label == item.label {
                                selectedItem = nil
                            } else {
                                selectedItem = item
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                    }
                    .simultaneousGesture(
                        TapGesture(count: 1)
                            .onEnded { _ in
                                // Immediate hide on any tap
                                if selectedItem != nil {
                                    selectedItem = nil
                                }
                            }
                    )
            }
        }
        .clipped()
        .overlay {
            if let item = selectedItem {
                chartTooltip(item: item)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: chartData)
        .frame(height: 160)
        .drawingGroup()
    }
    
    @ViewBuilder
    private func chartTooltip(item: ChartItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Text(item.amount.formatted(.currency(code: settingsManager.appCurrency)))
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: .systemBackground).opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .offset(y: -70)
    }
}
