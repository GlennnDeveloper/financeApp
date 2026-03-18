import SwiftUI

struct DashboardBalanceCard: View {
    @EnvironmentObject var settingsManager: SettingsManager
    var balance: Double
    var monthlySavings: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsManager.localizedString(for: "Total Balance"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                
                Text(balance, format: .currency(code: settingsManager.appCurrency))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsManager.localizedString(for: "MONTHLY SAVINGS"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(monthlySavings, format: .currency(code: settingsManager.appCurrency))
                    .font(.headline)
                    .foregroundStyle(.red)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 24, lowRes: true)
        .drawingGroup()
    }
}
