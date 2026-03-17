import SwiftUI

struct SubscriptionCard: View {
    var transaction: Transaction
    var nextPaymentDate: Date?
    var categoryColor: Color
    var onToggleRecurring: () -> Void
    
    @EnvironmentObject var settingsManager: SettingsManager

    var daysUntil: Int? {
        guard let date = nextPaymentDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: target)
        return components.day
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: transaction.categorySymbol)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(categoryColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let days = daysUntil {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(days == 0 ? settingsManager.localizedString(for: "Due today") : 
                                 days == 1 ? settingsManager.localizedString(for: "Due tomorrow") :
                                 String(format: settingsManager.localizedString(for: "Next in %d days"), days))
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(days <= 3 ? .red : .gray)
                    } else {
                        Text(transaction.date, format: .dateTime.day().month().year())
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(transaction.amount, format: .currency(code: settingsManager.appCurrency))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.primary)
                    
                    Text(settingsManager.localizedString(for: "Monthly"))
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contextMenu {
            Button(role: .destructive, action: onToggleRecurring) {
                Label(settingsManager.localizedString(for: "Remove from Recurring"), systemImage: "calendar.badge.minus")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onToggleRecurring) {
                Label(settingsManager.localizedString(for: "Remove"), systemImage: "calendar.badge.minus")
            }
        }
    }
}
