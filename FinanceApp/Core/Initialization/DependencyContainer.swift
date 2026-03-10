import Foundation
import SwiftUI
import Combine

/// A simple dependency container to manage service instances and injection.
class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    // Services
    @Published private(set) var supabaseManager: SupabaseManager
    @Published private(set) var settingsManager: SettingsManager
    @Published private(set) var categorizationService: CategorizationService
    
    private init() {
        // Initialize concrete implementations
        self.supabaseManager = SupabaseManager.shared
        self.settingsManager = SettingsManager.shared
        self.categorizationService = CategorizationService()
    }
    
    // Factories for ViewModels (optional, but cleaner)
    func makeAuthViewModel() -> AuthViewModel {
        return AuthViewModel()
    }
    
    func makeFinanceViewModel() -> FinanceViewModel {
        return FinanceViewModel()
    }
    
    func makeBankViewModel() -> BankConnectionViewModel {
        return BankConnectionViewModel()
    }
}
