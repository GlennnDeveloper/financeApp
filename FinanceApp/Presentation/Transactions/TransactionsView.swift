import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @Binding var showSettings: Bool
    
    // Performance Optimization: Pre-calculated grouped state
    @State private var groupedTransactions: [(String, [Transaction])] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ViewHeader(title: "Transactions", showSettings: $showSettings)
            
            Group {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        SettingsManager.shared.localizedString(for: "No Transactions"),
                        systemImage: "tray.fill",
                        description: Text(SettingsManager.shared.localizedString(for: "Your bank movements will appear here."))
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedTransactions, id: \.0) { monthYear, monthTransactions in
                                Section {
                                    VStack(spacing: 12) {
                                        ForEach(monthTransactions) { transaction in
                                            TransactionRow(transaction: transaction, categories: categories)
                                                .padding(.horizontal)
                                        }
                                    }
                                } header: {
                                    HStack {
                                        Text(monthYear)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal)
                                            .padding(.vertical, 12)
                                        Spacer()
                                    }
                                    .background(Color(uiColor: .systemGroupedBackground))
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            recalculateGroups()
        }
        .onChange(of: transactions) { _, _ in
            recalculateGroups()
        }
    }
    
    // MARK: - Performance Optimizations

    // Static formatter: created once, reused on every grouping call
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private func recalculateGroups() {
        Task(priority: .userInitiated) {
            let currentList = transactions
            let calendar = Calendar.current

            // 1. Group in background
            let grouped = Dictionary(grouping: currentList) { transaction -> String in
                let formatter = Self.monthYearFormatter
                formatter.locale = SettingsManager.shared.locale
                return formatter.string(from: transaction.date).capitalized
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
    TransactionsView(showSettings: .constant(false))
        .modelContainer(for: Transaction.self, inMemory: true)
        .environmentObject(SettingsManager.shared)
}
