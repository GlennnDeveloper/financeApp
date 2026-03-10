import SwiftUI
import Combine
import SwiftData
import Supabase

/// Manages the asynchronous initialization of core app services to keep the main thread unblocked.
final class AppInitializationManager: ObservableObject {
    @MainActor @Published var isInitialized = false
    @MainActor @Published var modelContainer: ModelContainer?
    
    func initialize() async {
        // Prevent double initialization
        if await MainActor.run(body: { isInitialized }) { return }
        
        // 1. Initialize SwiftData Container in a detached task to ENSURE it's not on the main thread
        let task = Task.detached(priority: .userInitiated) {
            do {
                let schema = Schema([Transaction.self, Account.self, Budget.self, Rule.self])
                let config = ModelConfiguration(isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("Failed to initialize ModelContainer: \(error)")
                // Fallback to memory
                return try! ModelContainer(for: Schema([Transaction.self, Account.self, Budget.self, Rule.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            }
        }
        
        let container = await task.value
        
        await MainActor.run {
            self.modelContainer = container
            self.isInitialized = true
        }
    }
}
