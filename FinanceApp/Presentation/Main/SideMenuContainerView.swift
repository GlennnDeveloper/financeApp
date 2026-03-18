import SwiftUI

struct SideMenuContainerView<MenuContent: View, MainContent: View>: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> MenuContent
    @ViewBuilder let main: () -> MainContent

    private let menuWidth: CGFloat = 300

    var body: some View {
        ZStack(alignment: .leading) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            menu()
                .frame(width: menuWidth, alignment: .leading)
                .offset(x: isOpen ? 0 : -menuWidth) // Fully hidden off-screen
                .opacity(isOpen ? 1 : 0) // No visibility when closed
                .ignoresSafeArea()

            ZStack {
                main()
                    .disabled(isOpen)
                    
                // Invisible tap area to close menu
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(isOpen)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isOpen = false
                        }
                    }
            }
            .background(Color(uiColor: .systemBackground))
            .shadow(color: .black.opacity(isOpen ? 0.12 : 0), radius: isOpen ? 15 : 0, x: isOpen ? -5 : 0, y: 0)
            .offset(x: isOpen ? menuWidth : 0)
            .compositingGroup()
        }
    }
}
