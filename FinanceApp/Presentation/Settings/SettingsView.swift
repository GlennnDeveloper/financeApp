import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.blue, .black, .indigo])
            
                ScrollView {
                VStack(spacing: 24) {
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settingsManager.localizedString(for: "Preferences"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: NotificationsView()) {
                                SettingsRow(icon: "bell.badge.fill", color: .red, title: "Notifications")
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06)).padding(.leading, 44)
                            
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                Text(settingsManager.localizedString(for: "Language"))
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.appLanguageName) {
                                    ForEach(AppLanguage.allCases) { lang in
                                        Text(lang.rawValue).tag(lang.rawValue)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            Divider().overlay(Color.white.opacity(0.06)).padding(.leading, 44)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 24)
                                Text(settingsManager.localizedString(for: "Primary Currency"))
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("", selection: $settingsManager.appCurrency) {
                                    ForEach(["USD", "EUR", "GBP", "JPY", "MXN"], id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                    
                    // Security
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settingsManager.localizedString(for: "Security"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            Text(settingsManager.localizedString(for: "Use Face ID"))
                                .foregroundStyle(.white)
                            Spacer()
                            Toggle("", isOn: $settingsManager.useBiometrics)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                    
                    // Diagnostics
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settingsManager.localizedString(for: "Diagnostics"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        HStack {
                            Image(systemName: "gauge.with.needle.fill")
                                .foregroundStyle(.purple)
                                .frame(width: 24)
                            Text(settingsManager.localizedString(for: "Show FPS Counter"))
                                .foregroundStyle(.white)
                            Spacer()
                            Toggle("", isOn: $settingsManager.showDiagnostics)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                    
                    // Data Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text(settingsManager.localizedString(for: "Data Management"))
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Button {
                                let viewModel = FinanceViewModel()
                                viewModel.runSubscriptionAnalysis(context: modelContext, transactions: transactions)
                            } label: {
                                ActionRow(icon: "magnifyingglass.circle", color: .orange, title: "Analyze Subscriptions")
                            }

                            Divider().overlay(Color.white.opacity(0.06)).padding(.horizontal, 16)

                            Button(role: .destructive) {
                                let viewModel = FinanceViewModel()
                                viewModel.clearTestData(context: modelContext)
                            } label: {
                                ActionRow(icon: "trash.circle", color: .red, title: "Clear Test Data")
                            }

                            Divider().overlay(Color.white.opacity(0.06)).padding(.horizontal, 16)

                            Button(role: .destructive) { } label: {
                                ActionRow(icon: "trash.fill", color: .red, title: "Clear Cache")
                            }
                            
                            Divider().overlay(Color.white.opacity(0.06)).padding(.horizontal, 16)
                            
                            Button { } label: {
                                ActionRow(icon: "square.and.arrow.up", color: .gray, title: "Export My Data")
                            }
                        }
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(settingsManager.localizedString(for: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .id(settingsManager.appLanguageName)
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

// MARK: - Helpers

private struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(SettingsManager.shared.localizedString(for: title))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ActionRow: View {
    let icon: String
    let color: Color
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(SettingsManager.shared.localizedString(for: title))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
