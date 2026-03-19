import SwiftUI

/// Individual shared transaction row (Moved to Shared for global use)
struct TransactionRow: View {
    var transaction: Transaction
    var categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager

    private var categoryColor: Color {
        categories.first(where: { $0.symbol == transaction.categorySymbol })?.color ?? .gray
    }

    var body: some View {
        HStack(spacing: 16) {
            CategoryIcon(symbol: transaction.categorySymbol, color: categoryColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(transaction.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            CurrencyText(
                amount: transaction.amount,
                currencyCode: settingsManager.appCurrency,
                isIncome: transaction.isIncome
            )
        }
        .glassCard(cornerRadius: 20, padding: 16, lowRes: true)
    }
}

#Preview {
    TransactionRow(
        transaction: Transaction(title: "Preview Example", amount: 120.0, isIncome: false, categorySymbol: "cart.fill"),
        categories: []
    )
    .environmentObject(SettingsManager.shared)
}
