import SwiftUI
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var session: Session? = nil
    @Published var isNewUser = false
    
    private let client = SupabaseManager.shared.client
    
    init() {
    }
    
    func startListening() async {
        for await (_, session) in client.auth.authStateChanges {
            self.session = session
            SettingsManager.shared.isLoggedIn = session != nil
            
            // Sync profile when session is established
            if let session = session {
                await syncProfile(session: session)
            }
        }
    }
    
    func checkSession() async {
        self.session = try? await client.auth.session
        SettingsManager.shared.isLoggedIn = self.session != nil
        
        // Sync profile if session exists
        if let session = self.session {
            await syncProfile(session: session)
        }
    }
    
    // Ahora recibe los datos directamente desde la vista
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Reset settings and clear database for new user
        SettingsManager.shared.reset()
        AppInitializationManager.shared.clearDatabase()
        
        do {
            try await client.auth.signUp(email: email, password: password)
            await checkSession()
            self.isNewUser = true
            AppInitializationManager.shared.isUnlocked = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            self.session = session
            self.isNewUser = false
            AppInitializationManager.shared.isUnlocked = true
            
            // --- FIX: Sync profile to skip onboarding ---
            await syncProfile(session: session)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Private Helpers
    
    private func syncProfile(session: Session) async {
        do {
            if let profile = try await SupabaseManager.shared.fetchProfile(id: session.user.id) {
                SettingsManager.shared.userName = "\(profile.firstName) \(profile.lastName)".trimmingCharacters(in: .whitespaces)
                SettingsManager.shared.userAge = profile.age
                SettingsManager.shared.financialGoals = profile.financialGoals
                
                // If we found a profile, the user has completed onboarding
                SettingsManager.shared.hasCompletedOnboarding = true
            }
        } catch {
            // If profile fetch fails (e.g., no profile yet), we don't set hasCompletedOnboarding
            print("Profile sync failed or not found: \(error)")
        }
    }
    
    func signOut() async {
        try? await client.auth.signOut()
        SettingsManager.shared.reset()
        AppInitializationManager.shared.clearDatabase()
        AppInitializationManager.shared.isUnlocked = false
        self.session = nil
        self.isNewUser = false
    }
}
