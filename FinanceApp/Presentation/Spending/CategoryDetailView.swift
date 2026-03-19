import SwiftUI
import SwiftData

struct CategoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
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
            PremiumBackground(colors: [.orange, .red, .purple])
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .glassCard(cornerRadius: 18, padding: 0, lowRes: true)
                    }
                    
                    Spacer()
                    
                    Text(categoryName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Invisible placeholder for alignment
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if transactions.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        settingsManager.localizedString(for: "No Expenses"),
                        systemImage: categorySymbol,
                        description: Text("\(settingsManager.localizedString(for: "No expenses for")) \(categoryName) \(settingsManager.localizedString(for: "in this timeframe."))")
                    )
                    .foregroundStyle(.white)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(transactions, id: \.id) { transaction in
                                TransactionRow(transaction: transaction, categories: categories)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
