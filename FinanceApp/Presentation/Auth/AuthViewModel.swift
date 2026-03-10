import SwiftUI
import Combine
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var session: Session? = nil
    
    private let client = SupabaseManager.shared.client
    
    init() {}
    
    func startListening() async {
        for await (_, session) in client.auth.authStateChanges {
            self.session = session
        }
    }
    
    func checkSession() async {
        self.session = try? await client.auth.session
    }
    
    // Ahora recibe los datos directamente desde la vista
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await client.auth.signUp(email: email, password: password)
            await checkSession()
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
