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
}
