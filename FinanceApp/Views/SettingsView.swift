import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section(SettingsManager.shared.localizedString(for: "Appearance")) {
                Picker(selection: $settingsManager.appThemeName) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.localizedName).tag(theme.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.pink)
                        Text(SettingsManager.shared.localizedString(for: "App Theme"))
                    }
                }
            }

            Section(SettingsManager.shared.localizedString(for: "Preferences")) {
                NavigationLink(destination: NotificationsView()) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.red)
                        Text(SettingsManager.shared.localizedString(for: "Notifications"))
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
                        Text(SettingsManager.shared.localizedString(for: "Language"))
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
                        Text(SettingsManager.shared.localizedString(for: "Primary Currency"))
                    }
                }
            }
            
            Section(SettingsManager.shared.localizedString(for: "Security")) {
                Toggle(isOn: $settingsManager.useBiometrics) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(.purple)
                        Text(SettingsManager.shared.localizedString(for: "Use Face ID"))
                    }
                }
            }
            
            Section(SettingsManager.shared.localizedString(for: "Data Management")) {
                Button(role: .destructive) {
                    // Action for clearing cache
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text(SettingsManager.shared.localizedString(for: "Clear Cache"))
                    }
                }
                
                Button {
                    // Action for exporting data
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(SettingsManager.shared.localizedString(for: "Export My Data"))
                    }
                }
            }
        }
        .navigationTitle(SettingsManager.shared.localizedString(for: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsManager.shared)
    }
}
