import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
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
                Button {
                    let viewModel = FinanceViewModel()
                    viewModel.seedManyTransactions(context: modelContext, count: 200)
                } label: {
                    HStack {
                        Image(systemName: "plus.square.dashed")
                            .foregroundStyle(.blue)
                        Text(settingsManager.localizedString(for: "Generate Test Data (200)"))
                    }
                }
                
                Button {
                    let viewModel = FinanceViewModel()
                    viewModel.runSubscriptionAnalysis(context: modelContext, transactions: transactions)
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass.circle")
                            .foregroundStyle(.orange)
                        Text(settingsManager.localizedString(for: "Analyze Subscriptions"))
                    }
                }

                Button(role: .destructive) {
                    let viewModel = FinanceViewModel()
                    viewModel.clearTestData(context: modelContext)
                } label: {
                    HStack {
                        Image(systemName: "trash.circle")
                        Text(settingsManager.localizedString(for: "Clear Test Data"))
                    }
                }

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
        .id(settingsManager.appLanguageName + settingsManager.appThemeName)
        .environment(\.locale, settingsManager.locale)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: [Transaction.self, Category.self, Budget.self, Account.self], inMemory: true)
            .environmentObject(SettingsManager.shared)
    }
}
