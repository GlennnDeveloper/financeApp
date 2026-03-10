import SwiftUI
import Combine
import SwiftData
import Supabase
import LinkKit

/// Manages the connection to Plaid and syncing of bank data
@MainActor
class BankConnectionViewModel: ObservableObject {
    @Published var isLinkActive = false
    @Published var linkToken: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isConnected: Bool = UserDefaults.standard.bool(forKey: "isBankConnected") {
        didSet {
            UserDefaults.standard.set(isConnected, forKey: "isBankConnected")
        }
    }
    
    /// Step 1: Fetch a link_token from Supabase Edge Function
    func preparePlaidLink(session: Session) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let client = SupabaseManager.shared.client
        let user = session.user
        
        struct LinkTokenRequest: Encodable {
            let user_id: String
        }
        
        struct TokenResponse: Decodable {
            let link_token: String
        }
        
        do {
            let tokenData: TokenResponse = try await client.functions.invoke(
                "create-link-token",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(session.accessToken)"],
                    body: LinkTokenRequest(user_id: user.id.uuidString)
                )
            )
            
            self.linkToken = tokenData.link_token
            self.isLinkActive = true
            
        } catch {
            if let functionsError = error as? FunctionsError {
                switch functionsError {
                case .httpError(let code, let data):
                    let dataStr = String(data: data, encoding: .utf8) ?? ""
                    self.errorMessage = "Edge Fnc Http \(code): \(dataStr)"
                case .relayError:
                    self.errorMessage = "Edge Fnc Relay Error"
                }
                return
            }
            self.errorMessage = "Function execution failed: \(error.localizedDescription)"
        }
    }
    
    /// Step 2: Exchange public_token for access_token
    func handleSuccess(publicToken: String, metadata: Any, context: ModelContext, session: Session) async {
        self.isLinkActive = false // Cierra la ventana inmediatamente
        isLoading = true
        defer { 
            isLoading = false
        }
        
        do {
            let client = SupabaseManager.shared.client
            let user = session.user
            
            struct ExchangeTokenRequest: Encodable {
                let public_token: String
                let user_id: String
            }
            
            // Exchange token via Supabase
            let _ = try await client.functions.invoke(
                "exchange-public-token",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(session.accessToken)"],
                    body: ExchangeTokenRequest(
                        public_token: publicToken,
                        user_id: user.id.uuidString
                    )
                )
            )
            
            self.isConnected = true

            // Extract selected accounts from Plaid metadata
            var selectedAccountNames: [(name: String, subtype: String)] = []
            if let meta = metadata as? SuccessMetadata {
                selectedAccountNames = meta.accounts.map { (name: $0.name, subtype: String(describing: $0.subtype)) }
            }

            // Trigger initial sync with the selected accounts
            await syncMockTransactions(context: context, plaidAccounts: selectedAccountNames)
            
            // In a full implementation, the Edge Function would trigger a webhook 
            // or return initial data. For now, we rely on Supabase realtime or 
            // manual fetch if needed. We'll leave the local sync disabled until 
            // the full remote sync is ready.
            
        } catch {
            self.errorMessage = "Failed to exchange token: \(error.localizedDescription)"
        }
    }
    
    /// Step 3: Fetch and save transactions to SwiftData
    func syncMockTransactions(context: ModelContext, plaidAccounts: [(name: String, subtype: String)] = []) async {
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: today)!
        
        // Mock data from Plaid API - extended to 3 months with recurring flags
        // Tuple: (Title, Amount, Date, Categories, isRecurring)
        let mockData: [(String, Double, Date, [String], Bool)] = [
            // Current Month
            ("Netflix", 15.99, calendar.date(byAdding: .day, value: -2, to: today)!, ["Entertainment", "Subscription"], true),
            ("Starbucks Coffee", 5.45, calendar.date(byAdding: .day, value: -5, to: today)!, ["Food and Drink", "Coffee Shop"], false),
            ("Uber Trip", 14.20, calendar.date(byAdding: .day, value: -10, to: today)!, ["Travel", "Taxi"], false),
            ("Salary Deposit", 2500.00, calendar.date(byAdding: .day, value: -15, to: today)!, ["Income", "Payroll"], false),
            ("Gym Membership", 40.00, calendar.date(byAdding: .day, value: -20, to: today)!, ["Personal Care", "Gym"], true),
            ("Whole Foods", 120.50, calendar.date(byAdding: .day, value: -25, to: today)!, ["Food and Drink", "Groceries"], false),
            
            // Last Month
            ("Netflix", 15.99, calendar.date(byAdding: .day, value: -2, to: lastMonth)!, ["Entertainment", "Subscription"], true),
            ("Apple Music", 10.99, calendar.date(byAdding: .day, value: -4, to: lastMonth)!, ["Entertainment", "Music"], true),
            ("Salary Deposit", 2500.00, calendar.date(byAdding: .day, value: -15, to: lastMonth)!, ["Income", "Payroll"], false),
            ("Gym Membership", 40.00, calendar.date(byAdding: .day, value: -20, to: lastMonth)!, ["Personal Care", "Gym"], true),
            ("Amazon Prime", 14.99, calendar.date(byAdding: .day, value: -22, to: lastMonth)!, ["Shopping", "Subscription"], true),
            ("Restaurant Meal", 65.00, calendar.date(byAdding: .day, value: -28, to: lastMonth)!, ["Food and Drink", "Restaurant"], false),

            // Two Months Ago
            ("Netflix", 15.99, calendar.date(byAdding: .day, value: -2, to: twoMonthsAgo)!, ["Entertainment", "Subscription"], true),
            ("Apple Music", 10.99, calendar.date(byAdding: .day, value: -4, to: twoMonthsAgo)!, ["Entertainment", "Music"], true),
            ("Salary Deposit", 2500.00, calendar.date(byAdding: .day, value: -15, to: twoMonthsAgo)!, ["Income", "Payroll"], false),
            ("Gym Membership", 40.00, calendar.date(byAdding: .day, value: -20, to: twoMonthsAgo)!, ["Personal Care", "Gym"], true),
            ("Amazon Prime", 14.99, calendar.date(byAdding: .day, value: -22, to: twoMonthsAgo)!, ["Shopping", "Subscription"], true),
            ("Gas Station", 45.00, calendar.date(byAdding: .day, value: -25, to: twoMonthsAgo)!, ["Travel", "Gas"], false)
        ]
        
        for (title, amount, date, categories, isRecurring) in mockData {
            let externalId = "plaid_\(title.replacingOccurrences(of: " ", with: "_"))_\(date.timeIntervalSince1970)"
            
            // Check for duplicates
            let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.externalId == externalId })
            if let existing = try? context.fetch(descriptor), !existing.isEmpty {
                continue // Already imported
            }
            
            let isIncome = title.contains("Salary")
            let symbol = CategorizationService.mapCategory(title: title, plaidCategories: categories)
            
            let newTransaction = Transaction(
                title: title,
                amount: amount,
                date: date,
                isIncome: isIncome,
                categorySymbol: symbol,
                externalId: externalId,
                isRecurring: isRecurring
            )
            
            context.insert(newTransaction)
        }
        
        // Create accounts based on what Plaid returned
        // Map Plaid subtypes to symbols and mock balances
        let subtypeConfig: [String: (symbol: String, color: String, balance: Double, isLiability: Bool)] = [
            "checking":    ("building.columns.fill", "blue",  4500.50,  false),
            "savings":     ("leaf.fill",             "green", 12500.00, false),
            "credit card": ("creditcard.fill",       "red",   1250.25,  true),
            "money market": ("dollarsign.circle.fill","green", 8000.00,  false),
            "cd":          ("lock.circle.fill",      "purple",5000.00,  false)
        ]

        for (idx, plaidAccount) in plaidAccounts.enumerated() {
            let config = subtypeConfig[plaidAccount.subtype.lowercased()]
                ?? ("banknote.fill", "gray", 0.0, false)

            let accountName = plaidAccount.name
            let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.name == accountName })
            let existing = (try? context.fetch(descriptor)) ?? []

            if existing.isEmpty {
                let newAccount = Account(
                    name: accountName,
                    balance: config.balance,
                    symbol: config.symbol,
                    colorName: config.color,
                    orderIndex: idx + 10,
                    isLiability: config.isLiability
                )
                context.insert(newAccount)
            } else if let account = existing.first {
                account.balance = config.balance
            }
        }
        
        do {
            try context.save()
        } catch {
            self.errorMessage = "Save error: \(error.localizedDescription)"
        }
        
        self.isConnected = true
    }
    
    func disconnectBank(context: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        // Batch-delete all transactions
        try? context.delete(model: Transaction.self)

        // Reset ALL account balances to 0
        let accountDescriptor = FetchDescriptor<Account>()
        if let allAccounts = try? context.fetch(accountDescriptor) {
            for account in allAccounts {
                account.balance = 0.0
            }
        }

        try? context.save()

        self.linkToken = nil
        self.isConnected = false
    }
    
    func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
    }
}
