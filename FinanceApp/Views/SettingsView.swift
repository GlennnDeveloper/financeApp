import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section(NSLocalizedString("Appearance", comment: "")) {
                Picker(selection: $settingsManager.appThemeName) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.pink)
                        Text("App Theme")
                    }
                }
            }

            Section(NSLocalizedString("Preferences", comment: "")) {
                NavigationLink(destination: NotificationsView()) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.red)
                        Text("Notifications")
                    }
                }
                
                Picker(selection: $settingsManager.appLanguageName) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                        Text("Language")
                    }
                }
                
                Picker(selection: $settingsManager.appCurrency) {
                    ForEach(["USD", "EUR", "GBP", "JPY", "MXN"], id: \.self) { curr in
                        Text(curr).tag(curr)
                    }
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundStyle(.green)
                        Text("Primary Currency")
                    }
                }
            }
            
            Section(NSLocalizedString("Security", comment: "")) {
                Toggle(isOn: $settingsManager.useBiometrics) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(.purple)
                        Text("Use Face ID")
                    }
                }
            }
            
            Section(NSLocalizedString("Data Management", comment: "")) {
                Button(role: .destructive) {
                    // Action for clearing cache
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Clear Cache")
                    }
                }
                
                Button {
                    // Action for exporting data
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export My Data")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsManager.shared)
    }
}
