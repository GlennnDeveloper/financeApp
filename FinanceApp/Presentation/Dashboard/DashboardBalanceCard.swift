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
                    .foregroundStyle(.gray)
                
                Text(balance, format: .currency(code: "USD"))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settingsManager.localizedString(for: "MONTHLY SAVINGS"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                
                Text(monthlySavings, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(.red)
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}
