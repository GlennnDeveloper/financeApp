import SwiftData
import SwiftUI

struct RecurringView: View {
    @Query(filter: #Predicate<Transaction> { $0.isRecurring == true }, sort: \Transaction.date, order: .reverse) 
    private var recurringTransactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var viewModel = FinanceViewModel()
    @Binding var showSettings: Bool
    
    // Compute unique recurring expenses based on title
    private var uniqueSubscriptions: [Transaction] {
        var seenTitles = Set<String>()
        var unique = [Transaction]()
        
        // Use a stable sort to ensure consistency
        let sorted = recurringTransactions.sorted { $0.date > $1.date }
        
        for tx in sorted {
            let normalizedTitle = tx.title.lowercased().trimmingCharacters(in: .whitespaces)
            if !seenTitles.contains(normalizedTitle) {
                seenTitles.insert(normalizedTitle)
                unique.append(tx)
            }
        }
        
        return unique
    }
    
    // Derived subscriptions with metadata
    private var subscriptionsWithDates: [(transaction: Transaction, nextDate: Date?)] {
        uniqueSubscriptions.map { tx in
            let nextDate = viewModel.calculateNextBillingDate(for: tx.title, from: recurringTransactions)
            return (tx, nextDate)
        }
    }
    
    private var totalMonthlyCost: Double {
        uniqueSubscriptions.reduce(0) { $0 + $1.amount }
    }
    
    private var upcomingSubscriptions: [(transaction: Transaction, nextDate: Date?)] {
        subscriptionsWithDates
            .filter { data in
                guard let next = data.nextDate else { return false }
                let days = Calendar.current.dateComponents([.day], from: .now, to: next).day ?? 100
                return days >= 0 && days <= 14 // Next 2 weeks
            }
            .sorted { ($0.nextDate ?? .distantFuture) < ($1.nextDate ?? .distantFuture) }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ViewHeader(title: "Recurring", showSettings: $showSettings) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                .padding(.bottom, 16)
                
                if uniqueSubscriptions.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 24) {
                        summaryCards
                        
                        if !upcomingSubscriptions.isEmpty {
                            upcomingSection
                        }
                        
                        allSubscriptionsSection
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .environment(\.locale, settingsManager.locale)
    }
    
    private var summaryCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                summaryCard(
                    title: "Total Monthly", 
                    value: totalMonthlyCost, 
                    icon: "calendar.badge.clock", 
                    color: .blue
                )
                
                summaryCard(
                    title: "Active Subs", 
                    value: Double(uniqueSubscriptions.count), 
                    icon: "app.badge.checkmark.fill", 
                    color: .green,
                    isCurrency: false
                )
                
                summaryCard(
                    title: "Average Cost", 
                    value: uniqueSubscriptions.isEmpty ? 0 : (totalMonthlyCost / Double(uniqueSubscriptions.count)), 
                    icon: "chart.line.uptrend.xyaxis", 
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func summaryCard(title: String, value: Double, icon: String, color: Color, isCurrency: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if isCurrency {
                    Text(value, format: .currency(code: settingsManager.appCurrency))
                        .font(.title3.weight(.bold))
                } else {
                    Text(value, format: .number)
                        .font(.title3.weight(.bold))
                }
                
                Text(settingsManager.localizedString(for: title))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsManager.localizedString(for: "Upcoming Payments"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(upcomingSubscriptions, id: \.transaction.id) { data in
                    SubscriptionCard(
                        transaction: data.transaction,
                        nextPaymentDate: data.nextDate,
                        categoryColor: getCategoryColor(for: data.transaction),
                        onToggleRecurring: {
                            viewModel.toggleRecurring(transaction: data.transaction, context: modelContext)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var allSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsManager.localizedString(for: "All Subscriptions"))
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(subscriptionsWithDates, id: \.transaction.id) { data in
                    SubscriptionCard(
                        transaction: data.transaction,
                        nextPaymentDate: data.nextDate,
                        categoryColor: getCategoryColor(for: data.transaction),
                        onToggleRecurring: {
                            viewModel.toggleRecurring(transaction: data.transaction, context: modelContext)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView(
            settingsManager.localizedString(for: "No Subscriptions"),
            systemImage: "calendar.badge.minus",
            description: Text(settingsManager.localizedString(for: "No recurring expenses were found."))
        )
        .padding(.top, 100)
    }
    
    private func getCategoryColor(for transaction: Transaction) -> Color {
        categories.first(where: { $0.symbol == transaction.categorySymbol })?.color ?? .blue
    }
}

#Preview {
    RecurringView(showSettings: .constant(false))
        .environmentObject(SettingsManager.shared)
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
