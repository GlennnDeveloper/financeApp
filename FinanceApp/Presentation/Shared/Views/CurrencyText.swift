import SwiftUI

/// A reusable text component for displaying currency with consistent formatting and styling.
struct CurrencyText: View {
    let amount: Double
    let currencyCode: String
    var showColor: Bool = true
    var isIncome: Bool? = nil
    var font: Font = .headline
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    private var textColor: Color {
        guard showColor else { return .white }
        if let isIncome = isIncome {
            return isIncome ? .green : .white
        }
        return amount >= 0 ? .green : .white
    }
    
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = settingsManager.locale
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    var body: some View {
        Text(amount, format: .currency(code: currencyCode))
            .font(font.monospacedDigit())
            .foregroundStyle(textColor)
    }
}

#Preview {
    VStack(spacing: 10) {
        CurrencyText(amount: 1250.50, currencyCode: "USD", isIncome: true)
        CurrencyText(amount: -45.00, currencyCode: "USD", isIncome: false)
        CurrencyText(amount: 500.00, currencyCode: "USD", showColor: false)
    }
    .padding()
    .background(Color.black)
    .environmentObject(SettingsManager.shared)
}
