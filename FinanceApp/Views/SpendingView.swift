import SwiftUI
import SwiftData
import Charts

struct SpendingCategoryData: Identifiable, Equatable {
    var id: String { category.name } // Use stable ID to prevent jumping segments
    let category: Category
    let totalSpent: Double
    let percentage: Double
}

struct SpendingView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    // Defaulting to "Month" timeframe for the analysis
    @State private var selectedTimeframe: Timeframe = .month
    @State private var dateOffset: Int = 0 // Negatives go back in time
    
    // 1. Filter transactions based on timeframe and exclude income
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        var today = calendar.startOfDay(for: .now)

        var offsetComponent: Calendar.Component = .day
        var offsetValue = 0

        switch selectedTimeframe {
        case .week:
            offsetComponent = .day
            offsetValue = dateOffset * 7
        case .month:
            offsetComponent = .month
            offsetValue = dateOffset
        case .year:
            offsetComponent = .year
            offsetValue = dateOffset
        }

        if let adjustedAnchor = calendar.date(byAdding: offsetComponent, value: offsetValue, to: today) {
            today = adjustedAnchor
        }

        return transactions.filter { tx in
            guard !tx.isIncome else { return false }

            switch selectedTimeframe {
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else { return false }
                let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today)!
                let startOfAgo = calendar.startOfDay(for: weekAgo)
                return tx.date >= startOfAgo && tx.date <= endOfDay
            case .month:
                return calendar.isDate(tx.date, equalTo: today, toGranularity: .month) &&
                       calendar.isDate(tx.date, equalTo: today, toGranularity: .year)
            case .year:
                return calendar.isDate(tx.date, equalTo: today, toGranularity: .year)
            }
        }
    }
    
    // 2. Prepare visual chart data
    private var chartData: [SpendingCategoryData] {
        let currentFilteredTransactions = self.filteredTransactions
        
        // Group by category symbol
        let grouped = Dictionary(grouping: currentFilteredTransactions, by: { $0.categorySymbol })
        
        let totalSpend = currentFilteredTransactions.reduce(0) { $0 + $1.amount }
        

        
        // 3. Initialize result with ALL default categories (zero-padded)
        var result: [SpendingCategoryData] = Category.defaults.map { category in
            SpendingCategoryData(category: category, totalSpent: 0, percentage: 0)
        }
        
        // 4. Update totals for categories that have transactions
        for i in 0..<result.count {
            if let txs = grouped[result[i].category.symbol] {
                let catTotal = txs.reduce(0) { $0 + $1.amount }
                result[i] = SpendingCategoryData(
                    category: result[i].category,
                    totalSpent: catTotal,
                    percentage: totalSpend > 0 ? (catTotal / totalSpend) : 0
                )
            }
        }
        
        // 5. Sort by alphabetical category name for a fixed, stable order
        return result.sorted { $0.category.name < $1.category.name }
    }
    
    // Static formatters — created once for the app lifetime
    private static let weekRangeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
    }()
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f
    }()
    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()

    // Helper to render the specific timeline range
    private var dateRangeText: String {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: .now)

        switch selectedTimeframe {
        case .week:
            let offsetValue = dateOffset * 7
            if let adjustedAnchor = calendar.date(byAdding: .day, value: offsetValue, to: baseDate),
               let startOfWeek = calendar.date(byAdding: .day, value: -6, to: adjustedAnchor) {
                let startStr = Self.weekRangeFormatter.string(from: startOfWeek)
                let endStr   = Self.weekRangeFormatter.string(from: adjustedAnchor)
                return "\(startStr) - \(endStr)"
            }

        case .month:
            if let adjustedAnchor = calendar.date(byAdding: .month, value: dateOffset, to: baseDate) {
                return Self.monthYearFormatter.string(from: adjustedAnchor)
            }

        case .year:
            if let adjustedAnchor = calendar.date(byAdding: .year, value: dateOffset, to: baseDate) {
                return Self.yearFormatter.string(from: adjustedAnchor)
            }
        }

        return "Unknown Date"
    }
    
    // Helper para el centro del Donut
    private var totalSpentFiltered: Double {
        chartData.reduce(0) { $0 + $1.totalSpent }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Header and Timeframe Picker
                        HStack {
                            Text("Spending Info")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            
                            HStack(spacing: 0) {
                                ForEach(Timeframe.allCases, id: \.self) { tf in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTimeframe = tf
                                            dateOffset = 0 // Reset when mode changes
                                        }
                                    } label: {
                                        Text(tf.rawValue)
                                            .font(.caption2.weight(selectedTimeframe == tf ? .bold : .medium))
                                            .foregroundStyle(selectedTimeframe == tf ? .black : .gray)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedTimeframe == tf ? Color.white : Color.clear, in: Capsule())
                                    }
                                }
                            }
                            .background(Color(white: 0.15), in: Capsule())
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
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
                                    .foregroundStyle(dateOffset < 0 ? .white : .gray.opacity(0.3)) // Visually disable future
                                    .padding(8)
                            }
                            .disabled(dateOffset >= 0)
                        }
                        .padding(.horizontal)
                        
                        // Donut Chart Area
                        if totalSpentFiltered == 0 {
                            ContentUnavailableView(
                                "No Data",
                                systemImage: "chart.pie.fill",
                                description: Text("You have no expenses recorded for this timeframe.")
                            )
                            .frame(height: 300)
                        } else {
                            ZStack {
                                Chart(chartData, id: \.category.name) { item in
                                    SectorMark(
                                        angle: .value("Spent", item.totalSpent),
                                        innerRadius: .ratio(0.65),
                                        angularInset: 2.0
                                    )
                                    .cornerRadius(6)
                                    .foregroundStyle(by: .value("Category", item.category.name))
                                }
                                .chartForegroundStyleScale(
                                    domain: Category.defaults.map { $0.name },
                                    range: Category.defaults.map { AnyShapeStyle($0.color.gradient) }
                                )
                                .chartLegend(.hidden)
                                .frame(height: 280)
                                
                                // Center Label
                                VStack(spacing: 4) {
                                    Text("Total Spent")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray)
                                    Text(totalSpentFiltered, format: .currency(code: "USD"))
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: chartData)
                            .padding(.vertical)
                            
                            // Category Breakdown List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Breakdown")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    // Only show non-zero categories in the list
                                    ForEach(chartData.filter { $0.totalSpent > 0 }, id: \.category.name) { item in
                                        NavigationLink {
                                            CategoryDetailView(
                                                category: item.category,
                                                dateRangeText: dateRangeText,
                                                filteredTransactions: self.filteredTransactions // Pass exactly what is on the chart
                                            )
                                        } label: {
                                            HStack(spacing: 16) {
                                                // Icon
                                                ZStack {
                                                    Circle()
                                                        .fill(item.category.color.opacity(0.15))
                                                        .frame(width: 48, height: 48)
                                                    
                                                    Image(systemName: item.category.symbol)
                                                        .font(.title3.weight(.semibold))
                                                        .foregroundStyle(item.category.color)
                                                }
                                                
                                                // Label & Percentage bar
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text(item.category.name)
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(.white)
                                                        Spacer()
                                                        Text(item.totalSpent, format: .currency(code: "USD"))
                                                            .font(.subheadline.weight(.semibold))
                                                            .foregroundStyle(.white)
                                                    }
                                                    
                                                    HStack {
                                                        // Visual percentage bar
                                                        GeometryReader { geo in
                                                            ZStack(alignment: .leading) {
                                                                Capsule()
                                                                    .fill(Color(white: 0.2))
                                                                    .frame(height: 6)
                                                                Capsule()
                                                                    .fill(item.category.color)
                                                                    .frame(width: geo.size.width * CGFloat(item.percentage), height: 6)
                                                            }
                                                        }
                                                        .frame(height: 6)
                                                        
                                                        Text("\(Int(item.percentage * 100))%")
                                                            .font(.caption2.monospacedDigit())
                                                            .foregroundStyle(.gray)
                                                            .frame(width: 30, alignment: .trailing)
                                                    }
                                                }
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.gray.opacity(0.5))
                                            }
                                            .padding(16)
                                            .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

#Preview {
    SpendingView()
        .modelContainer(for: [Transaction.self], inMemory: true)
}
