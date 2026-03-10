import SwiftUI
import Auth

struct SettingsMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    greetingSection
                    quickActionsSection
                    accountSection
                    preferencesSection
                    signOutButton
                    versionLabel
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(SettingsManager.shared.localizedString(for: "Hi there 👋"))
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            if let email = authViewModel.session?.user.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var quickActionsSection: some View {
        SettingsSection {
            SettingsRow(icon: "gift.fill", iconColor: .purple, title: SettingsManager.shared.localizedString(for: "Refer a Friend"))
            Divider().overlay(Color.white.opacity(0.06))
            SettingsRow(icon: "bubble.left.and.bubble.right.fill", iconColor: .blue, title: SettingsManager.shared.localizedString(for: "Chat"))
            Divider().overlay(Color.white.opacity(0.06))
            SettingsRow(icon: "play.circle.fill", iconColor: .green, title: SettingsManager.shared.localizedString(for: "Enter Demo Mode"))
        }
    }

    private var accountSection: some View {
        SettingsSection {
            NavigationLink(destination: ProfileView()) {
                SettingsRowContent(icon: "person.fill", iconColor: .orange, title: SettingsManager.shared.localizedString(for: "Profile"))
            }
            Divider().overlay(Color.white.opacity(0.06))
            
            ShareLink(item: URL(string: "https://financeapp.example.com/invite")!, message: Text(SettingsManager.shared.localizedString(for: "Join me on FinanceApp to manage our budget together!"))) {
                SettingsRowContent(icon: "person.2.fill", iconColor: .cyan, title: SettingsManager.shared.localizedString(for: "Share Account"))
            }
            Divider().overlay(Color.white.opacity(0.06))
            
            NavigationLink(destination: BudgetView()) {
                SettingsRowContent(icon: "dollarsign.circle.fill", iconColor: .green, title: SettingsManager.shared.localizedString(for: "Manage Budget"))
            }
            Divider().overlay(Color.white.opacity(0.06))
            
            NavigationLink(destination: CategoryRulesView()) {
                SettingsRowContent(icon: "square.grid.2x2.fill", iconColor: .indigo, title: SettingsManager.shared.localizedString(for: "Categories, Tags & Rules"))
            }
            Divider().overlay(Color.white.opacity(0.06))
            
            NavigationLink(destination: LinkedAccountsView()) {
                SettingsRowContent(icon: "building.columns.fill", iconColor: .blue, title: SettingsManager.shared.localizedString(for: "Linked Accounts"))
            }
        }
    }

    private var preferencesSection: some View {
        SettingsSection {
            SettingsRow(icon: "crown.fill", iconColor: .yellow, title: SettingsManager.shared.localizedString(for: "Premium Membership"))
            Divider().overlay(Color.white.opacity(0.06))
            
            NavigationLink(destination: SettingsView()) {
                SettingsRowContent(icon: "gearshape.fill", iconColor: .gray, title: SettingsManager.shared.localizedString(for: "Settings"))
            }
            Divider().overlay(Color.white.opacity(0.06))
            
            SettingsRow(icon: "questionmark.circle.fill", iconColor: .gray, title: SettingsManager.shared.localizedString(for: "Help & Privacy"))
        }
    }

    private var signOutButton: some View {
        Button {
            dismiss()
            // Wait for sheet dismiss animation, then sign out
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                await authViewModel.signOut()
            }
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.body.weight(.semibold))
                Text(SettingsManager.shared.localizedString(for: "Log Out"))
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal)
    }

    private var versionLabel: some View {
        Text("MyFinance v1.0")
            .font(.caption2)
            .foregroundStyle(.gray.opacity(0.5))
            .padding(.bottom, 24)
    }
}

// MARK: - Subcomponents

/// Rounded card that groups rows
private struct SettingsSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, 4)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }
}

/// Individual settings row with icon, title, and chevron
private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        Button {
            // Placeholder — each setting will be wired up individually later
        } label: {
            SettingsRowContent(icon: icon, iconColor: iconColor, title: title)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.gray.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsMenuView()
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsManager.shared)
}
