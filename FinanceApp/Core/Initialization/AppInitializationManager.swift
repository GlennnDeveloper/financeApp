import SwiftUI
import Combine
import SwiftData
import Supabase

/// Manages the asynchronous initialization of core app services to keep the main thread unblocked.
final class AppInitializationManager: ObservableObject {
    static let shared = AppInitializationManager()
    
    @MainActor @Published var isInitialized = false
    @MainActor @Published var modelContainer: ModelContainer?
    @MainActor @Published var isUnlocked = false
    @MainActor @Published var authFailed = false
    
    private init() {}
    
    func initialize() async {
        // Prevent double initialization
        if await MainActor.run(body: { isInitialized }) { return }
        
        await performDataInitialization()
        
        await MainActor.run {
            self.isInitialized = true
        }
    }
    
    /// Performs only the data initialization (model container)
    private func performDataInitialization() async {
        let task = Task.detached(priority: .userInitiated) {
            do {
                let schema = Schema([Transaction.self, Account.self, Budget.self, Rule.self, Category.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("Failed to initialize ModelContainer: \(error)")
                // Fallback to memory
                return try! ModelContainer(for: Schema([Transaction.self, Account.self, Budget.self, Rule.self, Category.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            }
        }
        
        let container = await task.value
        
        await MainActor.run {
            self.modelContainer = container
        }
    }
    
    /// Performs only the biometric authentication
    func performAuthentication() async {
        // Reset failure state at start of retry
        await MainActor.run { self.authFailed = false }
        
        // 2. Handle Biometric Authentication if needed
        if SettingsManager.shared.useBiometrics {
            let success = await SecurityManager.shared.authenticate()
            await MainActor.run {
                self.isUnlocked = success
                self.authFailed = !success
                self.isInitialized = true
            }
        } else {
            await MainActor.run {
                self.isUnlocked = true
                self.isInitialized = true
                self.authFailed = false
            }
        }
    }
    
    /// Clears all data from the local SwiftData store
    func clearDatabase() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        
        do {
            try context.delete(model: Transaction.self)
            try context.delete(model: Account.self)
            try context.delete(model: Budget.self)
            try context.delete(model: Rule.self)
            try context.delete(model: Category.self)
            try context.save()
        } catch {
            print("Error clearing database: \(error)")
        }
    }
}
