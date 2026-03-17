import SwiftUI
import SwiftData

@Observable
final class FinanceViewModel {

    // Calcula el balance total (Ingresos - Gastos)
    func calculateTotalBalance(transactions: [Transaction]) -> Double {
        transactions.reduce(0) { total, transaction in
            total + (transaction.isIncome ? transaction.amount : -transaction.amount)
        }
    }

    // Calcula el ahorro del mes actual
    func calculateMonthlySavings(transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let now = Date.now

        let monthTransactions = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }

        return calculateTotalBalance(transactions: monthTransactions)
    }

    // Calcula los gastos (solo expenses) del mes actual
    func calculateCurrentMonthSpend(transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let now = Date.now

        let monthExpenses = transactions.filter {
            !$0.isIncome &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }

        return monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Generador de cuentas iniciales (para la vista de "ACCOUNTS")
    func insertDefaultAccountsIfNeeded(context: ModelContext, existingAccounts: [Account]) {
        // Migration: Fix any existing accounts stuck with the old invalid symbol
        var didMigrate = false
        for account in existingAccounts where account.symbol == "piggybank" {
            account.symbol = "dollarsign.circle"
            didMigrate = true
        }

        guard existingAccounts.isEmpty else {
            if didMigrate { try? context.save() }
            return
        }

        let defaults = [
            Account(name: "Checking", balance: 5848.0, symbol: "building.columns.circle", colorName: "purple", orderIndex: 0, isLiability: false),
            Account(name: "Savings", balance: 2267.0, symbol: "dollarsign.circle", colorName: "purple", orderIndex: 1, isLiability: false),
            Account(name: "Investments", balance: 10400.0, symbol: "chart.bar.xaxis", colorName: "purple", orderIndex: 2, isLiability: false),
            Account(name: "Credit Card", balance: 2001.0, symbol: "creditcard.circle", colorName: "purple", orderIndex: 3, isLiability: true)
        ]

        defaults.forEach { context.insert($0) }
        try? context.save()
    }
    
    // Seed initial categories
    func seedDefaultCategoriesIfNeeded(context: ModelContext, existingCategories: [Category]) {
        let existingSymbols = Set(existingCategories.map { $0.symbol })
        var didAdd = false
        
        for defaultCat in Category.defaultData {
            if !existingSymbols.contains(defaultCat.symbol) {
                context.insert(Category(
                    name: defaultCat.name,
                    symbol: defaultCat.symbol,
                    colorName: defaultCat.colorName,
                    isDefault: defaultCat.isDefault,
                    orderIndex: defaultCat.orderIndex
                ))
                didAdd = true
            }
        }
        
        if didAdd {
            try? context.save()
        }
    }
    
    // Auto-categorize existing transactions using custom rules and CategorizationService
    func autoCategorizeTransactions(context: ModelContext, transactions: [Transaction], rules: [Rule], categories: [Category]) {
        var didUpdate = false
        
        for transaction in transactions {
            var newSymbol: String?
            
            // 1. Check custom rules (User preferences take priority)
            for rule in rules {
                if transaction.title.lowercased().contains(rule.pattern.lowercased()) {
                    newSymbol = rule.categorySymbol
                    break
                }
            }
            
            // 2. Fallback to default categorization service
            if newSymbol == nil {
                newSymbol = CategorizationService.mapCategory(title: transaction.title, plaidCategories: nil)
            }
            
            if let newSymbol = newSymbol, transaction.categorySymbol != newSymbol {
                // Ensure the symbol actually exists in our categories (optional but good)
                transaction.categorySymbol = newSymbol
                didUpdate = true
            }
        }
        
        if didUpdate {
            try? context.save()
        }
    }

    // Seed many transactions for testing purposes
    func seedManyTransactions(context: ModelContext, count: Int = 100) {
        let calendar = Calendar.current
        let today = Date()
        
        let recurringTitles = [
            "Netflix", "Spotify", "Apple One", "iCloud Storage", 
            "YouTube Premium", "Disney+", "HBO Max", "Amazon Prime",
            "Gym Membership", "Internet Service", "Utility Bill", "Rent Payment"
        ]
        
        let normalTitles = [
            "Uber Trip", "Amazon Store", "Starbucks", "Gas Station", 
            "Grocery Store", "Salary", "Restaurant", "Apple Store", 
            "Steam", "Pharmacy"
        ]
        
        let symbols = Category.defaultData.map { $0.symbol }
        
        // 1. Generate real recurring patterns (Sequences)
        for title in recurringTitles {
            let amount = Double.random(in: 10...500).rounded(toPlaces: 2)
            let dayOfMonth = Int.random(in: 1...28)
            let symbol = symbols.randomElement() ?? "cart.fill"
            
            // For the last 6 months
            for monthOffset in 0...5 {
                if let date = calendar.date(byAdding: .month, value: -monthOffset, to: today),
                   let finalDate = calendar.date(bySetting: .day, value: dayOfMonth, of: date) {
                    
                    let transaction = Transaction(
                        title: title,
                        amount: amount,
                        date: finalDate,
                        isIncome: false,
                        categorySymbol: symbol,
                        externalId: "test-id-\(UUID().uuidString)",
                        isRecurring: true 
                    )
                    context.insert(transaction)
                }
            }
        }
        
        // 2. Generate random non-recurring transactions
        for i in 0..<count {
            let title = normalTitles.randomElement() ?? "Transaction \(i)"
            let randomDays = Int.random(in: 0...180) 
            let date = calendar.date(byAdding: .day, value: -randomDays, to: today) ?? today
            
            // Use wider range and more decimals to avoid accidental matches
            let amount = Double.random(in: 3...800).rounded(toPlaces: Int.random(in: 0...2))
            let isIncome = title == "Salary"
            let symbol = symbols.randomElement() ?? "cart.fill"
            
            let transaction = Transaction(
                title: title,
                amount: amount,
                date: date,
                isIncome: isIncome,
                categorySymbol: symbol,
                externalId: "test-id-\(UUID().uuidString)",
                isRecurring: false
            )
            context.insert(transaction)
        }
        
        try? context.save()
    }

    // Safely remove only generated test data
    func clearTestData(context: ModelContext) {
        let descriptor = FetchDescriptor<Transaction>()
        do {
            let allTransactions = try context.fetch(descriptor)
            let testTransactions = allTransactions.filter { $0.externalId?.hasPrefix("test-id-") ?? false }
            
            for tx in testTransactions {
                context.delete(tx)
            }
            try context.save()
        } catch {
            print("Failed to clear test data: \(error)")
        }
    }
    
    // Pattern Recognition for all transactions
    func runSubscriptionAnalysis(context: ModelContext, transactions: [Transaction]) {
        let recurringIds = SubscriptionDetectionService.detectRecurringPatterns(in: transactions)
        
        var didUpdate = false
        for transaction in transactions {
            let shouldBeRecurring = recurringIds.contains(transaction.id)
            if transaction.isRecurring != shouldBeRecurring {
                transaction.isRecurring = shouldBeRecurring
                didUpdate = true
            }
        }
        
        if didUpdate {
            try? context.save()
        }
    }
    
    // Toggle recurring status
    func toggleRecurring(transaction: Transaction, context: ModelContext) {
        transaction.isRecurring.toggle()
        try? context.save()
    }
    
    // Calculate estimated next billing date based on history
    func calculateNextBillingDate(for title: String, from transactions: [Transaction]) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        
        let filtered = transactions
            .filter { $0.title.lowercased() == title.lowercased() && $0.isRecurring }
            .sorted { $0.date > $1.date }
        
        guard let lastTx = filtered.first else { return nil }
        
        // If the last transaction is ALREADY in the future, that's our next payment
        if calendar.startOfDay(for: lastTx.date) >= today {
            return lastTx.date
        }
        
        // Determine frequency (default to month)
        var frequencyUnit: Calendar.Component = .month
        var frequencyValue = 1
        
        if filtered.count >= 2 {
            let tx2 = filtered[1]
            let diff = calendar.dateComponents([.day], from: tx2.date, to: lastTx.date).day ?? 30
            if diff >= 6 && diff <= 8 {
                frequencyUnit = .day
                frequencyValue = 7
            }
        }
        
        // Iterate until we find a date in the future
        var nextDate = lastTx.date
        while calendar.startOfDay(for: nextDate) < today {
            guard let calculated = calendar.date(byAdding: frequencyUnit, value: frequencyValue, to: nextDate) else { break }
            nextDate = calculated
        }
        
        return nextDate
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
