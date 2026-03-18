import SwiftUI

struct HelpPrivacyView: View {
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.blue, .black, .indigo])
            
            ScrollView {
                VStack(spacing: 28) {
                    // Support Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SettingsManager.shared.localizedString(for: "Support"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Link(destination: URL(string: "https://financeapp.example.com/help")!) {
                                HelpRow(icon: "questionmark.circle", title: SettingsManager.shared.localizedString(for: "Help Center"))
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06)).padding(.horizontal, 16)
                            
                            Link(destination: URL(string: "mailto:support@financeapp.example.com")!) {
                                HelpRow(icon: "envelope", title: SettingsManager.shared.localizedString(for: "Contact Support"))
                            }
                        }
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                    
                    // Legal Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SettingsManager.shared.localizedString(for: "Legal"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Link(destination: URL(string: "https://financeapp.example.com/privacy")!) {
                                HelpRow(icon: "lock.shield", title: SettingsManager.shared.localizedString(for: "Privacy Policy"))
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06)).padding(.horizontal, 16)
                            
                            Link(destination: URL(string: "https://financeapp.example.com/terms")!) {
                                HelpRow(icon: "doc.text", title: SettingsManager.shared.localizedString(for: "Terms of Service"))
                            }
                        }
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                    
                    // App Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SettingsManager.shared.localizedString(for: "App Info"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        HStack {
                            Text(SettingsManager.shared.localizedString(for: "Version"))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("1.0.0 (100)")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(SettingsManager.shared.localizedString(for: "Help & Privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Helper struct for consistent row styling
struct HelpRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24)
                .foregroundStyle(.white.opacity(0.8))
            Text(title)
                .font(.body)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        HelpPrivacyView()
    }
}
