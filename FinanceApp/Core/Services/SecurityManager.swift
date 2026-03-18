import Foundation
import LocalAuthentication
import SwiftUI
import Combine

class SecurityManager {
    static let shared = SecurityManager()
    
    private init() {}
    
    /// Authenticates the user using biometrics (Face ID/Touch ID)
    /// - Returns: Boolean indicating success
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Allow fallback to passcode/password
        let policy = LAPolicy.deviceOwnerAuthentication
        
        // Check if authentication is available (biometrics OR passcode)
        if context.canEvaluatePolicy(policy, error: &error) {
            let reason = "Desbloquea MyFinance para acceder a tus datos."
            
            do {
                let success = try await context.evaluatePolicy(
                    policy,
                    localizedReason: reason
                )
                return success
            } catch {
                print("Authentication failed: \(error.localizedDescription)")
                return false
            }
        } else {
            print("Authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            return false
        }
    }
}
