import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section(settingsManager.localizedString(for: "Appearance")) {
                Picker(selection: $settingsManager.appThemeName) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.localizedName).tag(theme.rawValue)
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundStyle(.pink)
                        Text(settingsManager.localizedString(for: "App Theme"))
                    }
                }
            }

            Section(settingsManager.localizedString(for: "Preferences")) {
                NavigationLink(destination: NotificationsView()) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.red)
                        Text(settingsManager.localizedString(for: "Notifications"))
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
                        Text(settingsManager.localizedString(for: "Language"))
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
                        Text(settingsManager.localizedString(for: "Primary Currency"))
                    }
                }
            }
            
            Section(settingsManager.localizedString(for: "Security")) {
                Toggle(isOn: $settingsManager.useBiometrics) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(.purple)
                        Text(settingsManager.localizedString(for: "Use Face ID"))
                    }
                }
            }
            
            Section(settingsManager.localizedString(for: "Data Management")) {
                Button(role: .destructive) {
                    // Action for clearing cache
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text(settingsManager.localizedString(for: "Clear Cache"))
                    }
                }
                
                Button {
                    // Action for exporting data
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(settingsManager.localizedString(for: "Export My Data"))
                    }
                }
            }
        }
        .navigationTitle(settingsManager.localizedString(for: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(SettingsManager.shared)
    }
}
