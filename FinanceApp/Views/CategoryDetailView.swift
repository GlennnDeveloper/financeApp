import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    let transactions: [Transaction]
    let category: Category
    let dateRangeText: String
    
    // Custom filter based on exactly the transactions shown in the SpendingView pie chart
    init(category: Category, dateRangeText: String, filteredTransactions: [Transaction]) {
        self.category = category
        self.dateRangeText = dateRangeText
        
        // We only want to display transactions from this timeframe & category
        self.transactions = filteredTransactions.filter { $0.categorySymbol == category.symbol }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if transactions.isEmpty {
                ContentUnavailableView(
                    NSLocalizedString("No Expenses", comment: ""),
                    systemImage: category.symbol,
                    description: Text("No expenses for \(category.localizedName) in this timeframe.")
                )
            } else {
                List {
                    ForEach(transactions, id: \.id) { transaction in
                        TransactionRow(transaction: transaction, categories: categories)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(category.name)
        // Simplified modifiers for cross-platform compatibility
    }
}
