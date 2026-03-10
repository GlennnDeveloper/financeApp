import SwiftUI
import SwiftData
import Observation

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
        let currentMonth = calendar.component(.month, from: .now)
        let currentYear = calendar.component(.year, from: .now)
        
        let monthTransactions = transactions.filter {
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
        
        return calculateTotalBalance(transactions: monthTransactions)
    }
    
    // Calcula los gastos (solo expenses) del mes actual
    func calculateCurrentMonthSpend(transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: .now)
        let currentYear = calendar.component(.year, from: .now)
        
        let monthExpenses = transactions.filter {
            !$0.isIncome && 
            calendar.component(.month, from: $0.date) == currentMonth &&
            calendar.component(.year, from: $0.date) == currentYear
        }
        
        return monthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Generador de cuentas iniciales (para la vista de "ACCOUNTS")
    func insertDefaultAccountsIfNeeded(context: ModelContext, existingAccounts: [Account]) {
        // Migration: Fix any existing accounts stuck with the old invalid symbol
        for account in existingAccounts where account.symbol == "piggybank" {
            account.symbol = "dollarsign.circle"
        }
        
        guard existingAccounts.isEmpty else {
            try? context.save()
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
    
    // Auto-categorize existing transactions using the updated CategorizationService
    func autoCategorizeTransactions(context: ModelContext, transactions: [Transaction]) {
        var didUpdate = false
        
        for transaction in transactions {
            let newSymbol = CategorizationService.mapCategory(title: transaction.title, plaidCategories: nil)
            
            if transaction.categorySymbol != newSymbol {
                transaction.categorySymbol = newSymbol
                didUpdate = true
            }
        }
        
        if didUpdate {
            try? context.save()
        }
    }
}
