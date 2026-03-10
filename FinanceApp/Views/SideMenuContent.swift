import SwiftUI
import Auth

/// Side menu content — adapted from SettingsView for the 3D drawer layout
struct SideMenuContent: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    quickActionsSection
                    accountSection
                    preferencesSection
                    logoutButton
                    versionLabel
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("Hi there 👋", comment: ""))
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            if let email = authViewModel.session?.user.email {
                Text(email)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 28)
    }

    private var quickActionsSection: some View {
        MenuSection {
            MenuRow(icon: "gift.fill", iconColor: .purple, title: NSLocalizedString("Refer a Friend", comment: ""))
            MenuRow(icon: "bubble.left.and.bubble.right.fill", iconColor: .blue, title: NSLocalizedString("Chat", comment: ""))
            MenuRow(icon: "play.circle.fill", iconColor: .green, title: NSLocalizedString("Demo Mode", comment: ""))
        }
    }

    private var accountSection: some View {
        MenuSection {
            Button { withAnimation { isOpen = false } } label: {
                NavigationLink(destination: ProfileView()) {
                    MenuRowContent(icon: "person.fill", iconColor: .orange, title: NSLocalizedString("Profile", comment: ""))
                }
            }
            
            ShareLink(item: URL(string: "https://financeapp.example.com/invite")!, message: Text(NSLocalizedString("Join me on FinanceApp to manage our budget together!", comment: ""))) {
                MenuRowContent(icon: "person.2.fill", iconColor: .cyan, title: NSLocalizedString("Share Account", comment: ""))
            }
            
            Button { withAnimation { isOpen = false } } label: {
                NavigationLink(destination: BudgetView()) {
                    MenuRowContent(icon: "dollarsign.circle.fill", iconColor: .green, title: NSLocalizedString("Manage Budget", comment: ""))
                }
            }
            
            Button { withAnimation { isOpen = false } } label: {
                NavigationLink(destination: CategoryRulesView()) {
                    MenuRowContent(icon: "square.grid.2x2.fill", iconColor: .indigo, title: NSLocalizedString("Categories & Rules", comment: ""))
                }
            }
            
            Button { withAnimation { isOpen = false } } label: {
                NavigationLink(destination: LinkedAccountsView()) {
                    MenuRowContent(icon: "building.columns.fill", iconColor: .blue, title: NSLocalizedString("Linked Accounts", comment: ""))
                }
            }
        }
    }

    private var preferencesSection: some View {
        MenuSection {
            MenuRow(icon: "crown.fill", iconColor: .yellow, title: NSLocalizedString("Premium", comment: ""))
            
            Button { withAnimation { isOpen = false } } label: {
                NavigationLink(destination: SettingsView()) {
                    MenuRowContent(icon: "gearshape.fill", iconColor: .gray, title: NSLocalizedString("Settings", comment: ""))
                }
            }
            
            MenuRow(icon: "questionmark.circle.fill", iconColor: .gray, title: NSLocalizedString("Help & Privacy", comment: ""))
        }
    }

    private var logoutButton: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isOpen = false
            }
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                await authViewModel.signOut()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.subheadline.weight(.semibold))
                Text(NSLocalizedString("Log Out", comment: ""))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 4)
    }

    private var versionLabel: some View {
        Text("MyFinance v1.0")
            .font(.caption2)
            .foregroundStyle(.gray.opacity(0.4))
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Subcomponents

private struct MenuSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        Button {} label: {
            MenuRowContent(icon: icon, iconColor: iconColor, title: title)
        }
        .buttonStyle(.plain)
    }
}

private struct MenuRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.gray.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
