import SwiftData
import SwiftUI

struct RecurringView: View {
    @Query(filter: #Predicate<Transaction> { $0.isRecurring == true }, sort: \Transaction.date, order: .reverse) 
    private var recurringTransactions: [Transaction]
    
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
                        "No Subscriptions",
                        systemImage: "calendar.badge.minus",
                        description: Text("No recurring expenses were found.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(uniqueSubscriptions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 4)
                            }
                        } header: {
                            HStack {
                                Text("Active Subscriptions")
                                Spacer()
                                Text(totalMonthlyCost, format: .currency(code: "USD"))
                                    .foregroundStyle(.red)
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .environment(\.defaultMinListRowHeight, 10)
                }
            }
            .navigationTitle("Recurring")
            .background(Color.black.ignoresSafeArea())
        }
    }
}

#Preview {
    RecurringView()
}
