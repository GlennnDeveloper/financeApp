import SwiftData
import SwiftUI

struct RecurringView: View {
    @Query(filter: #Predicate<Transaction> { $0.isRecurring == true }, sort: \Transaction.date, order: .reverse) 
    private var recurringTransactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager
    
    // Compute unique recurring expenses based on title
    var uniqueSubscriptions: [Transaction] {
        var seenTitles = Set<String>()
        var unique = [Transaction]()
        
        for tx in recurringTransactions {
            if !seenTitles.contains(tx.title) {
                seenTitles.insert(tx.title)
                unique.append(tx)
            }
        }
        
        return unique
    }
    
    // Calculate total monthly committed cost
    var totalMonthlyCost: Double {
        uniqueSubscriptions.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if uniqueSubscriptions.isEmpty {
                    ContentUnavailableView(
                        settingsManager.localizedString(for: "No Subscriptions"),
                        systemImage: "calendar.badge.minus",
                        description: Text(settingsManager.localizedString(for: "No recurring expenses were found."))
                    )
                } else {
                    List {
                        Section {
                            ForEach(uniqueSubscriptions) { transaction in
                                TransactionRow(transaction: transaction, categories: categories)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 4)
                            }
                        } header: {
                            HStack {
                                Text(settingsManager.localizedString(for: "Active Subscriptions"))
                                Spacer()
                                Text(totalMonthlyCost, format: .currency(code: settingsManager.appCurrency))
                                    .foregroundStyle(.red)
                            }
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                    .environment(\.defaultMinListRowHeight, 10)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(settingsManager.localizedString(for: "Recurring"))
            .environment(\.locale, settingsManager.locale)
        }
    }
}

#Preview {
    RecurringView()
}
