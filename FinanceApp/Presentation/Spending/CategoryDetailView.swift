import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    let transactions: [Transaction]
    let categoryName: String
    let categorySymbol: String
    let dateRangeText: String
    
    // Custom filter based on exactly the transactions shown in the SpendingView pie chart
    init(categoryName: String, categorySymbol: String, dateRangeText: String, filteredTransactions: [Transaction]) {
        self.categoryName = categoryName
        self.categorySymbol = categorySymbol
        self.dateRangeText = dateRangeText
        
        // We only want to display transactions from this timeframe & category
        self.transactions = filteredTransactions.filter { $0.categorySymbol == categorySymbol }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if transactions.isEmpty {
                ContentUnavailableView(
                    SettingsManager.shared.localizedString(for: "No Expenses"),
                    systemImage: categorySymbol,
                    description: Text("\(SettingsManager.shared.localizedString(for: "No expenses for")) \(categoryName) \(SettingsManager.shared.localizedString(for: "in this timeframe."))")
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
        .navigationTitle(categoryName)
        // Simplified modifiers for cross-platform compatibility
    }
}
