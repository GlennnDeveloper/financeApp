import Foundation
import Combine
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    // MARK: - Auth
    
    func getCurrentUser() async -> User? {
        try? await client.auth.session.user
    }
    
    // MARK: - Accounts
    
    func fetchAccounts() async throws -> [RemoteAccount] {
        try await client
            .from("accounts")
            .select()
            .execute()
            .value
    }
    
    // MARK: - Transactions
    
    func fetchTransactions() async throws -> [RemoteTransaction] {
        try await client
            .from("transactions")
            .select()
            .order("date", ascending: false)
            .execute()
            .value
    }
    
    // MARK: - Profiles
    
    func upsertProfile(_ profile: RemoteProfile) async throws {
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }
}

// MARK: - Remote Data Models
// Estos modelos coinciden con la base de datos de Supabase

struct RemoteAccount: Codable, Identifiable {
    let id: UUID
    let name: String
    let balance: Double
    let symbol: String
    let colorName: String
    let orderIndex: Int
    let isLiability: Bool
    let externalId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, balance, symbol
        case colorName = "color_name"
        case orderIndex = "order_index"
        case isLiability = "is_liability"
        case externalId = "external_id"
    }
}

struct RemoteTransaction: Codable, Identifiable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let isIncome: Bool
    let categorySymbol: String
    let externalId: String?
    let isRecurring: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, amount, date
        case isIncome = "is_income"
        case categorySymbol = "category_symbol"
        case externalId = "external_id"
        case isRecurring = "is_recurring"
    }
}

struct RemoteProfile: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let age: Int
    let financialGoals: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case age
        case financialGoals = "financial_goals"
    }
}
