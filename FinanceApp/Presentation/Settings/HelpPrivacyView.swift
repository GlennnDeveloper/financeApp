import SwiftUI

struct HelpPrivacyView: View {
    var body: some View {
        List {
            Section(header: Text(SettingsManager.shared.localizedString(for: "Support"))) {
                Link(destination: URL(string: "https://financeapp.example.com/help")!) {
                    Label(SettingsManager.shared.localizedString(for: "Help Center"), systemImage: "questionmark.circle")
                }
                
                Link(destination: URL(string: "mailto:support@financeapp.example.com")!) {
                    Label(SettingsManager.shared.localizedString(for: "Contact Support"), systemImage: "envelope")
                }
            }
            
            Section(header: Text(SettingsManager.shared.localizedString(for: "Legal"))) {
                Link(destination: URL(string: "https://financeapp.example.com/privacy")!) {
                    Label(SettingsManager.shared.localizedString(for: "Privacy Policy"), systemImage: "lock.shield")
                }
                
                Link(destination: URL(string: "https://financeapp.example.com/terms")!) {
                    Label(SettingsManager.shared.localizedString(for: "Terms of Service"), systemImage: "doc.text")
                }
            }
            
            Section(header: Text(SettingsManager.shared.localizedString(for: "App Info"))) {
                HStack {
                    Text(SettingsManager.shared.localizedString(for: "Version"))
                    Spacer()
                    Text("1.0.0 (100)")
                        .foregroundStyle(.gray)
                }
            }
        }
        .navigationTitle(SettingsManager.shared.localizedString(for: "Help & Privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpPrivacyView()
    }
}
