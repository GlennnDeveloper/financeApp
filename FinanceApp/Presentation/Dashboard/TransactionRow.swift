import SwiftUI

/// Individual shared transaction row (Extracted for global use)
struct TransactionRow: View {
    var transaction: Transaction
    var categories: [Category]

    private var categoryColor: Color {
        categories.first(where: { $0.symbol == transaction.categorySymbol })?.color ?? .gray
    }

    var body: some View {
        HStack(spacing: 16) {
            // Smooth circular icon with category color
            ZStack {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: transaction.categorySymbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(transaction.date, format: .dateTime.day().month().year())
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Monospaced amount for perfect digit alignment
            Text(transaction.amount, format: .currency(code: "USD"))
                .font(.headline.monospacedDigit())
                .foregroundStyle(transaction.isIncome ? Color.green : Color.white)
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    TransactionRow(
        transaction: Transaction(title: "Preview Example", amount: 120.0, isIncome: false, categorySymbol: "cart.fill"),
        categories: []
    )
}
