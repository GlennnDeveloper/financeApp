import SwiftUI
import SwiftData
import Charts


struct SpendingView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager
    @Binding var showSettings: Bool

    // Defaulting to "Month" timeframe for the analysis
    @State private var selectedTimeframe: Timeframe = .week
    @State private var dateOffset: Int = 0 // Negatives go back in time
    
    // Async State Properties
    @State private var filteredTransactions: [Transaction] = []
    @State private var chartData: [SpendingCategoryData] = []
    @State private var totalSpentFiltered: Double = 0
    
    // Asynchronous calculation of all spending data
    private func recalculateSpendingData() {
        // 0. CAPTURE metadata on MainActor before background work
        let currentTx = transactions
        let currentCategories = categories
        let currentOffset = dateOffset
        let currentTimeframe = selectedTimeframe
        let currentLocale = settingsManager.locale
        
        // Cache category info to avoid accessing @Models on background thread
        let categoryMetadata = currentCategories.map { (name: $0.localizedName, symbol: $0.symbol, color: $0.color) }
        
        Task(priority: .userInitiated) {
            var calendar = Calendar.current
            calendar.locale = currentLocale
            var today = calendar.startOfDay(for: .now)

            var offsetComponent: Calendar.Component = .day
            var offsetValue = 0

            switch currentTimeframe {
            case .week:
                offsetComponent = .day
                offsetValue = currentOffset * 7
            case .month:
                offsetComponent = .month
                offsetValue = currentOffset
            case .year:
                offsetComponent = .year
                offsetValue = currentOffset
            }

            if let adjustedAnchor = calendar.date(byAdding: offsetComponent, value: offsetValue, to: today) {
                today = adjustedAnchor
            }

            // 1. Filter Transactions (Expenses only)
            let newFilteredTransactions = currentTx.filter { tx in
                guard !tx.isIncome else { return false }

                switch currentTimeframe {
                case .week:
                    guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return false }
                    let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today)!
                    let startOfAgo = calendar.startOfDay(for: weekAgo)
                    return tx.date >= startOfAgo && tx.date <= endOfDay
                case .month:
                    return calendar.isDate(tx.date, equalTo: today, toGranularity: .month)
                case .year:
                    return calendar.isDate(tx.date, equalTo: today, toGranularity: .year)
                }
            }

            // 2. Map into plain data structures (Symbol-First Grouping)
            let groupedTxs = Dictionary(grouping: newFilteredTransactions, by: { $0.categorySymbol })
            let newTotalSpend = newFilteredTransactions.reduce(0) { $0 + $1.amount }
            
            // Build a lookup for existing categories
            let categoryMap = Dictionary(uniqueKeysWithValues: categoryMetadata.map { ($0.symbol, $0) })
            
            var categoryResults: [SpendingCategoryData] = []
            var processedSymbols = Set<String>()
            
            // First, process all categories that actually have transactions
            for (symbol, txs) in groupedTxs {
                let catTotal = txs.reduce(0) { $0 + $1.amount }
                let percentage = newTotalSpend > 0 ? (catTotal / newTotalSpend) : 0
                
                if let metadata = categoryMap[symbol] {
                    categoryResults.append(SpendingCategoryData(
                        name: metadata.name,
                        symbol: metadata.symbol,
                        color: metadata.color,
                        totalSpent: catTotal,
                        percentage: percentage
                    ))
                } else if let defaultMatch = Category.defaultData.first(where: { $0.symbol == symbol }) {
                    // Symbol not in DB yet, but recognized as a default category!
                    categoryResults.append(SpendingCategoryData(
                        name: defaultMatch.localizedName,
                        symbol: defaultMatch.symbol,
                        color: defaultMatch.color,
                        totalSpent: catTotal,
                        percentage: percentage
                    ))
                } else {
                    // Truly unknown symbol
                    categoryResults.append(SpendingCategoryData(
                        name: "\(settingsManager.localizedString(for: "Others")) (\(symbol))",
                        symbol: symbol,
                        color: .gray,
                        totalSpent: catTotal,
                        percentage: percentage
                    ))
                }
                processedSymbols.insert(symbol)
            }
            
            // Second, add categories from DB that have 0 spending (to keep the list complete)
            for cat in categoryMetadata {
                if !processedSymbols.contains(cat.symbol) {
                    categoryResults.append(SpendingCategoryData(
                        name: cat.name,
                        symbol: cat.symbol,
                        color: cat.color,
                        totalSpent: 0,
                        percentage: 0
                    ))
                }
            }

            // Sort by alphabetical name
            let sortedChartData = categoryResults.sorted { $0.name < $1.name }

            await MainActor.run {
                withAnimation {
                    self.filteredTransactions = newFilteredTransactions
                    self.totalSpentFiltered = newTotalSpend
                    self.chartData = sortedChartData
                }
            }
        }
    }
    
    // MARK: - Formatters
    private var weekRangeFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = settingsManager.locale
        f.dateFormat = "MMM d"
        return f
    }
    private var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = settingsManager.locale
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f
    }
    private var yearFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = settingsManager.locale
        f.dateFormat = "yyyy"
        return f
    }

    // Helper to render the specific timeline range
    private var dateRangeText: String {
        var calendar = Calendar.current
        calendar.locale = settingsManager.locale
        let baseDate = calendar.startOfDay(for: .now)

        switch selectedTimeframe {
        case .week:
            let offsetValue = dateOffset * 7
            if let adjustedAnchor = calendar.date(byAdding: .day, value: offsetValue, to: baseDate),
               let startOfWeek = calendar.date(byAdding: .day, value: -6, to: adjustedAnchor) {
                let startStr = weekRangeFormatter.string(from: startOfWeek)
                let endStr   = weekRangeFormatter.string(from: adjustedAnchor)
                return "\(startStr) - \(endStr)"
            }

        case .month:
            if let adjustedAnchor = calendar.date(byAdding: .month, value: dateOffset, to: baseDate) {
                return monthYearFormatter.string(from: adjustedAnchor)
            }

        case .year:
            if let adjustedAnchor = calendar.date(byAdding: .year, value: dateOffset, to: baseDate) {
                return yearFormatter.string(from: adjustedAnchor)
            }
        }

        return settingsManager.localizedString(for: "Unknown Date")
    }
    
    @ViewBuilder
    private func headerArea() -> some View {
        VStack(spacing: 20) {
            // Date Navigation Controls
            HStack {
                Button {
                    withAnimation {
                        dateOffset -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(8)
                }
                
                Spacer()
                
                Text(dateRangeText)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .id(dateRangeText) // Helps with transition animations
                    .transition(.opacity)
                
                Spacer()
                
                Button {
                    withAnimation {
                        if dateOffset < 0 { // Prevent going into the future unnecessarily
                            dateOffset += 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(dateOffset < 0 ? .primary : Color.gray.opacity(0.3)) // Visually disable future
                        .padding(8)
                }
                .disabled(dateOffset >= 0)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    @ViewBuilder
    private var chartArea: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Header
            HStack {
                Text(settingsManager.localizedString(for: "Distribution"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach(Timeframe.allCases, id: \.self) { tf in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTimeframe = tf
                                dateOffset = 0
                            }
                        } label: {
                            Text(tf.localizedName)
                                .font(.caption2.weight(selectedTimeframe == tf ? .bold : .medium))
                                .foregroundStyle(selectedTimeframe == tf ? .primary : .secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(selectedTimeframe == tf ? Color.white.opacity(0.12) : Color.clear, in: Capsule())
                        }
                    }
                }
                .background(Color.white.opacity(0.05), in: Capsule())
            }
            .padding(.bottom, 10)
            
            ZStack {
                Chart(chartData, id: \.symbol) { item in
                    SectorMark(
                        angle: .value("Spent", item.totalSpent),
                        innerRadius: .ratio(0.65),
                        angularInset: 2.0
                    )
                    .cornerRadius(6)
                    .foregroundStyle(by: .value("Category", item.name))
                }
                .chartForegroundStyleScale(domain: chartData.map(\.name)) { categoryName in
                    if let data = chartData.first(where: { $0.name == categoryName }) {
                        AnyShapeStyle(data.color.gradient)
                    } else {
                        AnyShapeStyle(Color.gray.gradient)
                    }
                }
                .chartLegend(.hidden)
                .frame(height: 240)
                
                // Center Label
                VStack(spacing: 4) {
                    Text(totalSpentFiltered, format: .currency(code: settingsManager.appCurrency))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .glassCard(cornerRadius: 24, padding: 20, lowRes: true)
        .drawingGroup()
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: chartData)
    }

    @ViewBuilder
    private var breakdownArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settingsManager.localizedString(for: "Breakdown"))
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                // Only show non-zero categories in the list
                ForEach(chartData.filter { $0.totalSpent > 0 }, id: \.symbol) { item in
                    NavigationLink {
                        CategoryDetailView(
                            categoryName: item.name,
                            categorySymbol: item.symbol,
                            dateRangeText: dateRangeText,
                            filteredTransactions: self.filteredTransactions // Pass exactly what is on the chart
                        )
                    } label: {
                        HStack(spacing: 16) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(item.color.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: item.symbol)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(item.color)
                            }
                            
                            // Label & Percentage bar
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(item.totalSpent, format: .currency(code: settingsManager.appCurrency))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                                
                                HStack {
                                    // Visual percentage bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color(uiColor: .systemGray5))
                                                .frame(height: 6)
                                            Capsule()
                                                .fill(item.color)
                                                .frame(width: geo.size.width * CGFloat(item.percentage), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    Text("\(Int(item.percentage * 100))%")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.6))
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        .glassCard(cornerRadius: 16, padding: 16, lowRes: true)
                        .drawingGroup()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.purple, .indigo, .blue])
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ViewHeader(title: "Spending Info", showSettings: $showSettings) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 24) {
                        headerArea()
                        
                        // Donut Chart Area
                        if totalSpentFiltered == 0 {
                            ContentUnavailableView(
                                settingsManager.localizedString(for: "No Data"),
                                systemImage: "chart.pie.fill",
                                description: Text(settingsManager.localizedString(for: "You have no expenses recorded for this timeframe."))
                            )
                            .frame(height: 300)
                            .foregroundStyle(.white)
                        } else {
                            chartArea
                            breakdownArea
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            recalculateSpendingData()
        }
        .onChange(of: settingsManager.appLanguageName) { _, _ in
            recalculateSpendingData()
        }
        .onChange(of: transactions) { _, _ in
            recalculateSpendingData()
        }
        .onChange(of: selectedTimeframe) { _, _ in
            recalculateSpendingData()
        }
        .onChange(of: dateOffset) { _, _ in
            recalculateSpendingData()
        }
        .onChange(of: categories) { _, _ in
            recalculateSpendingData()
        }
        .environment(\.locale, settingsManager.locale)
    }
}

#Preview {
    SpendingView(showSettings: .constant(false))
        .modelContainer(for: [Transaction.self], inMemory: true)
        .environmentObject(SettingsManager.shared)
}
