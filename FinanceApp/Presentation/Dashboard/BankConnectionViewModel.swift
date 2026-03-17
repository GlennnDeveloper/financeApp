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
                    headers: [
                        "apikey": Secrets.supabaseAnonKey,
                        "Authorization": "Bearer \(session.accessToken)"
                    ],
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
            
            struct ExchangeResponse: Decodable {
                let item_id: String
            }
            
            // 1. Exchange token via Supabase
            let response: ExchangeResponse = try await client.functions.invoke(
                "exchange-public-token",
                options: FunctionInvokeOptions(
                    headers: [
                        "apikey": Secrets.supabaseAnonKey,
                        "Authorization": "Bearer \(session.accessToken)"
                    ],
                    body: ExchangeTokenRequest(
                        public_token: publicToken,
                        user_id: user.id.uuidString
                    )
                )
            )
            
            // 2. Trigger initial sync
            struct SyncRequest: Encodable {
                let user_id: String
                let plaid_item_id: String
            }
            
            let _ = try await client.functions.invoke(
                "sync-plaid-data",
                options: FunctionInvokeOptions(
                    headers: [
                        "apikey": Secrets.supabaseAnonKey,
                        "Authorization": "Bearer \(session.accessToken)"
                    ],
                    body: SyncRequest(
                        user_id: user.id.uuidString,
                        plaid_item_id: response.item_id
                    )
                )
            )
            
            self.isConnected = true

            // 3. Fetch data into SwiftData
            await syncRemoteData(context: context)
            
        } catch {
            self.errorMessage = "Failed to connection: \(error.localizedDescription)"
        }
    }
    
    /// Step 3: Fetch and save real data from Supabase to SwiftData
    func syncRemoteData(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Fetch Accounts
            let remoteAccounts = try await SupabaseManager.shared.fetchAccounts()
            
            for remote in remoteAccounts {
                let extId = remote.externalId
                let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.externalId == extId })
                let existing = (try? context.fetch(descriptor)) ?? []
                
                if existing.isEmpty {
                    let newAccount = Account(
                        name: remote.name,
                        balance: remote.balance,
                        symbol: remote.symbol,
                        colorName: remote.colorName,
                        orderIndex: remote.orderIndex,
                        isLiability: remote.isLiability,
                        externalId: remote.externalId
                    )
                    context.insert(newAccount)
                } else if let account = existing.first {
                    account.balance = remote.balance
                    account.name = remote.name
                    account.symbol = remote.symbol
                    account.colorName = remote.colorName
                }
            }
            
            // 2. Fetch Transactions
            let remoteTransactions = try await SupabaseManager.shared.fetchTransactions()
            
            for remote in remoteTransactions {
                let extId = remote.externalId
                let descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.externalId == extId })
                let existing = (try? context.fetch(descriptor)) ?? []
                
                if existing.isEmpty {
                    let newTx = Transaction(
                        title: remote.title,
                        amount: remote.amount,
                        date: remote.date,
                        isIncome: remote.isIncome,
                        categorySymbol: remote.categorySymbol,
                        externalId: remote.externalId,
                        isRecurring: remote.isRecurring
                    )
                    context.insert(newTx)
                } else if let tx = existing.first {
                    tx.title = remote.title
                    tx.amount = remote.amount
                    tx.date = remote.date
                    tx.categorySymbol = remote.categorySymbol
                    tx.isRecurring = remote.isRecurring
                }
            }
            
            try context.save()
            self.isConnected = true
            
        } catch {
            self.errorMessage = "Sync failed: \(error.localizedDescription)"
        }
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
