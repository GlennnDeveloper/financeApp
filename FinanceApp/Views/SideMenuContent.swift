import SwiftUI
import Auth

/// Side menu content — adapted from SettingsView for the 3D drawer layout
struct SideMenuContent: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var isOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Greeting ──
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi there 👋")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                if let email = authViewModel.session?.user.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 28)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // ── Quick Actions ──
                    MenuSection {
                        MenuRow(icon: "gift.fill", iconColor: .purple, title: "Refer a Friend")
                        MenuRow(icon: "bubble.left.and.bubble.right.fill", iconColor: .blue, title: "Chat")
                        MenuRow(icon: "play.circle.fill", iconColor: .green, title: "Demo Mode")
                    }

                    // ── Account ──
                    MenuSection {
                        MenuRow(icon: "person.fill", iconColor: .orange, title: "Profile")
                        MenuRow(icon: "person.2.fill", iconColor: .cyan, title: "Share Account")
                        MenuRow(icon: "dollarsign.circle.fill", iconColor: .green, title: "Manage Budget")
                        MenuRow(icon: "square.grid.2x2.fill", iconColor: .indigo, title: "Categories & Rules")
                        MenuRow(icon: "building.columns.fill", iconColor: .blue, title: "Linked Accounts")
                        MenuRow(icon: "bell.fill", iconColor: .red, title: "Notifications")
                    }

                    // ── Preferences ──
                    MenuSection {
                        MenuRow(icon: "paintbrush.fill", iconColor: .pink, title: "Appearance")
                        MenuRow(icon: "crown.fill", iconColor: .yellow, title: "Premium")
                        MenuRow(icon: "questionmark.circle.fill", iconColor: .gray, title: "Help & Privacy")
                    }

                    // ── Log Out ──
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
                            Text("Log Out")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 4)

                    // ── Version ──
                    Text("MyFinance v1.0")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.4))
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Subcomponents

private struct MenuSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct MenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.gray.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
