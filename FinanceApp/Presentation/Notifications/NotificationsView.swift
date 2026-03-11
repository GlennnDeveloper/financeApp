import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("budget_alerts") private var budgetAlerts = true
    @AppStorage("daily_summary") private var dailySummary = false
    @AppStorage("large_transaction_alert") private var largeTransactionAlert = true
    @AppStorage("recurring_reminders") private var recurringReminders = true
    
    var body: some View {
        Form {
                Section {
                    Toggle(settingsManager.localizedString(for: "Enable Notifications"), isOn: $notificationsEnabled)
                        .tint(.blue)
                } header: {
                    Text(settingsManager.localizedString(for: "General"))
                } footer: {
                    Text(settingsManager.localizedString(for: "Receive alerts and updates about your financial activity."))
                }
                
                Section {
                    Toggle(settingsManager.localizedString(for: "Budget Overrun Alerts"), isOn: $budgetAlerts)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle(settingsManager.localizedString(for: "Daily Summary"), isOn: $dailySummary)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle(settingsManager.localizedString(for: "Large Transaction Alerts"), isOn: $largeTransactionAlert)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle(settingsManager.localizedString(for: "Recurring Payment Reminders"), isOn: $recurringReminders)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                } header: {
                    Text(settingsManager.localizedString(for: "Alert Types"))
                }
                
                Section {
                    Button(settingsManager.localizedString(for: "Manage System Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle(settingsManager.localizedString(for: "Notifications"))
        }
    }


#Preview {
    NavigationStack {
    NotificationsView()
        .environmentObject(SettingsManager.shared)
    }
}
