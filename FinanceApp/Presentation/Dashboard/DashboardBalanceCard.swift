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
                
                CurrencyText(
                    amount: balance,
                    currencyCode: settingsManager.appCurrency,
                    showColor: false,
                    font: .system(size: 40, weight: .bold)
                )
                .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsManager.localizedString(for: "MONTHLY SAVINGS"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.6))
                
                CurrencyText(
                    amount: monthlySavings,
                    currencyCode: settingsManager.appCurrency,
                    isIncome: false,
                    font: .headline
                )
                .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(padding: 24, lowRes: true)
        .drawingGroup()
    }
}
