import SwiftUI

struct RecentTransactionsSection: View {
    let transactions: [Transaction]
    let categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsManager.localizedString(for: "Recent Transactions")).font(.headline).foregroundStyle(.primary).padding(.horizontal)
            VStack(spacing: 12) {
                ForEach(transactions.prefix(5)) { TransactionRow(transaction: $0, categories: categories) }
                if transactions.isEmpty { Text(settingsManager.localizedString(for: "No transactions yet")).foregroundStyle(.gray).padding() }
            }.padding(.horizontal)
        }
    }
}
