import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    // Performance Optimization: Pre-calculated grouped state
    @State private var groupedTransactions: [(String, [Transaction])] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        NSLocalizedString("No Transactions", comment: ""),
                        systemImage: "tray.fill",
                        description: Text("Your bank movements will appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedTransactions, id: \.0) { monthYear, monthTransactions in
                            Section {
                                ForEach(monthTransactions) { transaction in
                                    TransactionRow(transaction: transaction, categories: categories)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .listSectionSeparator(.hidden)
                                        .padding(.vertical, 4)
                                }
                            } header: {
                                Text(monthYear)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 10)
                }
            }
            .navigationTitle("Transactions")
            .onAppear {
                recalculateGroups()
            }
            .onChange(of: transactions) { _, _ in
                recalculateGroups()
            }
        }
    }
    
    // MARK: - Performance Optimizations

    // Static formatter: created once, reused on every grouping call
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private func recalculateGroups() {
        Task(priority: .userInitiated) {
            let currentList = transactions
            let calendar = Calendar.current

            // 1. Group in background
            let grouped = Dictionary(grouping: currentList) { transaction -> String in
                return Self.monthYearFormatter.string(from: transaction.date).capitalized
            }

            // 2. Sort keys in background
            let sortedGroups = grouped.sorted { (first, second) -> Bool in
                guard let firstTransaction = first.value.first, let secondTransaction = second.value.first else {
                    return false
                }

                let components1 = calendar.dateComponents([.year, .month], from: firstTransaction.date)
                let components2 = calendar.dateComponents([.year, .month], from: secondTransaction.date)

                let date1 = calendar.date(from: components1) ?? Date()
                let date2 = calendar.date(from: components2) ?? Date()

                return date1 > date2
            }

            // 3. Update UI on Main thread
            await MainActor.run {
                withAnimation {
                    self.groupedTransactions = sortedGroups
                }
            }
        }
    }
}

#Preview {
    TransactionsView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
