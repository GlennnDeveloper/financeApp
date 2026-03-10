import SwiftUI
import Auth

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Greeting ──
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Hi there 👋")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)

                            if let email = authViewModel.session?.user.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // ── Quick Actions ──
                        SettingsSection {
                            SettingsRow(icon: "gift.fill", iconColor: .purple, title: "Refer a Friend")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "bubble.left.and.bubble.right.fill", iconColor: .blue, title: "Chat")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "play.circle.fill", iconColor: .green, title: "Enter Demo Mode")
                        }

                        // ── Account ──
                        SettingsSection {
                            SettingsRow(icon: "person.fill", iconColor: .orange, title: "Profile")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "person.2.fill", iconColor: .cyan, title: "Share Account")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "dollarsign.circle.fill", iconColor: .green, title: "Manage Budget")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "square.grid.2x2.fill", iconColor: .indigo, title: "Categories, Tags & Rules")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "building.columns.fill", iconColor: .blue, title: "Linked Accounts")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications & Alerts")
                        }

                        // ── Preferences ──
                        SettingsSection {
                            SettingsRow(icon: "paintbrush.fill", iconColor: .pink, title: "App Appearance")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "crown.fill", iconColor: .yellow, title: "Premium Membership")
                            Divider().overlay(Color.white.opacity(0.06))
                            SettingsRow(icon: "questionmark.circle.fill", iconColor: .gray, title: "Help & Privacy")
                        }

                        // ── Sign Out ──
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
                                Text("Log Out")
                                    .font(.body.weight(.semibold))
                            }
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal)

                        // ── App Version ──
                        Text("MyFinance v1.0")
                            .font(.caption2)
                            .foregroundStyle(.gray.opacity(0.5))
                            .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.gray.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}
