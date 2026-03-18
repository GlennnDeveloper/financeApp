import SwiftUI

struct AnalyticsSection: View {
    let chartData: [ChartItem]
    @Binding var selectedTimeframe: Timeframe
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(settingsManager.localizedString(for: "Analytics")).font(.headline).foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 0) {
                    ForEach(Timeframe.allCases, id: \.self) { tf in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTimeframe = tf } } label: {
                            Text(tf.localizedName).font(.caption2.weight(selectedTimeframe == tf ? .bold : .medium)).foregroundStyle(selectedTimeframe == tf ? Color.primary : Color.secondary).padding(.horizontal, 12).padding(.vertical, 6).background(selectedTimeframe == tf ? Color(uiColor: .systemBackground) : Color.clear, in: Capsule())
                        }
                    }
                }.background(Color.primary.opacity(0.06), in: Capsule())
            }.padding(.horizontal)
            
            VStack {
                DashboardBarChart(chartData: chartData)
                    .padding()
            }
            .glassCard(cornerRadius: 24, lowRes: true)
            .drawingGroup()
            .padding(.horizontal)
        }
    }
}
