import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @Binding var showSettings: Bool
    
    @State private var groupedTransactions: [(String, [Transaction])] = []
    
    // Filter State
    @State private var searchText = ""
    @State private var selectedYear: Int? = nil
    @State private var selectedMonth: Int? = nil
    @State private var selectedDay: Int? = nil
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    private var availableYears: [Int] {
        let years = Set(transactions.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }
    
    private var availableMonths: [Int] {
        let months = Set(transactions.filter { t in
            if let y = selectedYear { return Calendar.current.component(.year, from: t.date) == y }
            return true
        }.map { Calendar.current.component(.month, from: $0.date) })
        return months.sorted()
    }
    
    private var availableDays: [Int] {
        let days = Set(transactions.filter { t in
            let c = Calendar.current
            if let y = selectedYear, c.component(.year, from: t.date) != y { return false }
            if let m = selectedMonth, c.component(.month, from: t.date) != m { return false }
            return true
        }.map { Calendar.current.component(.day, from: $0.date) })
        return days.sorted()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ViewHeader(title: "Transactions", showSettings: $showSettings) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    
                    // Search & Filter Row
                    VStack(spacing: 16) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField(settingsManager.localizedString(for: "Search transactions"), text: $searchText)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                            
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                        // Granular Filters: Year, Month, Day
                        HStack(spacing: 8) {
                            filterMenu(
                                label: settingsManager.localizedString(for: "Year"),
                                selection: selectedYear,
                                options: availableYears,
                                formatter: { String($0) },
                                onSelect: { selectedYear = $0 },
                                onClear: { selectedYear = nil }
                            )
                            
                            filterMenu(
                                label: settingsManager.localizedString(for: "Month"),
                                selection: selectedMonth,
                                options: availableMonths,
                                formatter: { Calendar.current.monthSymbols[$0 - 1].capitalized },
                                onSelect: { selectedMonth = $0 },
                                onClear: { selectedMonth = nil }
                            )
                            
                            filterMenu(
                                label: settingsManager.localizedString(for: "Day"),
                                selection: selectedDay,
                                options: availableDays,
                                formatter: { String($0) },
                                onSelect: { selectedDay = $0 },
                                onClear: { selectedDay = nil }
                            )
                            
                            Spacer()
                            
                            if selectedYear != nil || selectedMonth != nil || selectedDay != nil {
                                Button {
                                    withAnimation {
                                        selectedYear = nil
                                        selectedMonth = nil
                                        selectedDay = nil
                                    }
                                } label: {
                                    Text(settingsManager.localizedString(for: "Clear"))
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 24) // Added space below header
                    .padding(.bottom, 16)
                    
                    if transactions.isEmpty {
                        ContentUnavailableView(
                            settingsManager.localizedString(for: "No Transactions"),
                            systemImage: "tray.fill",
                            description: Text(settingsManager.localizedString(for: "Your bank movements will appear here."))
                        )
                        .padding(.top, 100)
                    } else if groupedTransactions.isEmpty {
                        ContentUnavailableView(
                            settingsManager.localizedString(for: "No Results"),
                            systemImage: "magnifyingglass",
                            description: Text(settingsManager.localizedString(for: "Try adjusting your filters or search terms."))
                        )
                        .padding(.top, 100)
                    } else {
                        ForEach(groupedTransactions, id: \.0) { monthYear, monthTransactions in
                            Section(header: 
                                HStack {
                                    Text(monthYear)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal)
                                        .padding(.vertical, 14)
                                    Spacer()
                                }
                                .background(Color(uiColor: .systemGroupedBackground))
                            ) {
                                VStack(spacing: 12) {
                                    ForEach(monthTransactions) { transaction in
                                        TransactionRow(transaction: transaction, categories: categories)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                            }
                        }
                        
                        Color.clear.frame(height: 100)
                    }
                }
            }
            
            // Opaque shield for the status bar
            Color(uiColor: .systemGroupedBackground)
                .frame(height: 1)
                .ignoresSafeArea(edges: .top)
                .zIndex(10)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            recalculateGroups()
        }
        .onChange(of: transactions) { _, _ in
            recalculateGroups()
        }
        .onChange(of: searchText) { _, _ in
            recalculateGroups()
        }
        .onChange(of: selectedYear) { _, _ in
            recalculateGroups()
        }
        .onChange(of: selectedMonth) { _, _ in
            recalculateGroups()
        }
        .onChange(of: selectedDay) { _, _ in
            recalculateGroups()
        }
    }
    
    // MARK: - Components
    
    private func filterMenu<T: Hashable>(
        label: String,
        selection: T?,
        options: [T],
        formatter: @escaping (T) -> String,
        onSelect: @escaping (T) -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        Menu {
            Button(settingsManager.localizedString(for: "All"), action: onClear)
            Divider()
            ForEach(options, id: \.self) { option in
                Button(formatter(option)) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection != nil ? formatter(selection!) : label)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(selection != nil ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground)))
            .foregroundStyle(selection != nil ? .white : .primary)
            .transaction { $0.animation = nil }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Performance Optimizations

    // Static formatter: created once, reused on every grouping call
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private func recalculateGroups() {
        let currentLocale = settingsManager.locale
        Task(priority: .userInitiated) {
            let currentList = transactions
            let calendar = Calendar.current
            let query = searchText.lowercased()
            let yearFilter = selectedYear
            let monthFilter = selectedMonth
            let dayFilter = selectedDay

            // 1. Filter
            let filtered = currentList.filter { transaction in
                let matchesSearch = query.isEmpty || transaction.title.lowercased().contains(query) || String(format: "%.2f", transaction.amount).contains(query)
                let c = calendar
                let matchesYear = yearFilter == nil || c.component(.year, from: transaction.date) == yearFilter
                let matchesMonth = monthFilter == nil || c.component(.month, from: transaction.date) == monthFilter
                let matchesDay = dayFilter == nil || c.component(.day, from: transaction.date) == dayFilter
                
                return matchesSearch && matchesYear && matchesMonth && matchesDay
            }

            // 2. Group in background
            let grouped = Dictionary(grouping: filtered) { transaction -> String in
                let formatter = Self.monthYearFormatter
                formatter.locale = currentLocale
                return formatter.string(from: transaction.date).capitalized
            }

            // 3. Sort groups by date and ensure items WITHIN groups are also sorted
            let sortedGroups = grouped.compactMap { key, transactions -> (String, [Transaction])? in
                let sortedTxs = transactions.sorted { $0.date > $1.date }
                return (key, sortedTxs)
            }.sorted { (first, second) -> Bool in
                guard let d1 = first.1.first?.date, let d2 = second.1.first?.date else { return false }
                return d1 > d2
            }

            // 4. Update UI on Main thread
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
