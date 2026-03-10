import SwiftUI
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var session: Session? = nil
    
    private let client = SupabaseManager.shared.client
    
    init() {}
    
    func startListening() async {
        // Escuchamos cambios en el estado de autenticación (login, logout, refresco de sesión)
        for await (_, session) in client.auth.authStateChanges {
            self.session = session
        }
    }
    
    func checkSession() async {
        self.session = try? await client.auth.session
    }
    
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await client.auth.signUp(email: email, password: password)
            // After signup, we might need to wait for email confirmation depending on Supabase settings
            await checkSession()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            self.session = session
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() async {
        try? await client.auth.signOut()
        self.session = nil
    }
}
