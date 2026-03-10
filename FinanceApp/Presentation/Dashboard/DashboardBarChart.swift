import SwiftUI
import Charts

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
