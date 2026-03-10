import SwiftUI
import Auth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange.gradient)
                    
                    if let email = authViewModel.session?.user.email {
                        Text(email)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SettingsManager.shared.localizedString(for: "Account Details"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            ProfileRow(title: SettingsManager.shared.localizedString(for: "Member Since"), value: "March 2026")
                            Divider().overlay(Color.white.opacity(0.06))
                            ProfileRow(title: SettingsManager.shared.localizedString(for: "Plan"), value: SettingsManager.shared.localizedString(for: "Free"))
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            // Dismiss the profile and settings flow first
                            dismiss()
                            
                            Task {
                                // Wait for animations to settle before clearing session
                                try? await Task.sleep(for: .milliseconds(400))
                                await authViewModel.signOut()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.subheadline.weight(.semibold))
                                Text(SettingsManager.shared.localizedString(for: "Log Out"))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text(SettingsManager.shared.localizedString(for: "Delete Account"))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                
            Spacer()
        }
        .navigationTitle(SettingsManager.shared.localizedString(for: "Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(SettingsManager.shared.localizedString(for: "Delete Account?"), isPresented: $showingDeleteAlert) {
            Button(SettingsManager.shared.localizedString(for: "Cancel"), role: .cancel) { }
            Button(SettingsManager.shared.localizedString(for: "Delete"), role: .destructive) {
                // Handle account deletion logic here
            }
        } message: {
            Text(SettingsManager.shared.localizedString(for: "This action is permanent and will delete all your financial data."))
        }
    }
}

private struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
}
