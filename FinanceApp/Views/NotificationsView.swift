import SwiftUI

struct NotificationsView: View {
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("budget_alerts") private var budgetAlerts = true
    @AppStorage("daily_summary") private var dailySummary = false
    @AppStorage("large_transaction_alert") private var largeTransactionAlert = true
    @AppStorage("recurring_reminders") private var recurringReminders = true
    
    var body: some View {
        Form {
                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .tint(.blue)
                } header: {
                    Text("General")
                } footer: {
                    Text("Receive alerts and updates about your financial activity.")
                }
                
                Section {
                    Toggle("Budget Overrun Alerts", isOn: $budgetAlerts)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Daily Summary", isOn: $dailySummary)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Large Transaction Alerts", isOn: $largeTransactionAlert)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Recurring Payment Reminders", isOn: $recurringReminders)
                        .tint(.blue)
                        .disabled(!notificationsEnabled)
                } header: {
                    Text("Alert Types")
                }
                
                Section {
                    Button("Manage System Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Notifications")
        }
    }


#Preview {
    NavigationStack {
        NotificationsView()
    }
}
