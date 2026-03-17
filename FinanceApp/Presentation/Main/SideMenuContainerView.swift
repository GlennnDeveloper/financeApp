import SwiftUI

struct SideMenuContainerView<MenuContent: View, MainContent: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> MenuContent
    @ViewBuilder let main: () -> MainContent

    private let menuWidth: CGFloat = 300

    var body: some View {
        ZStack(alignment: .leading) {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            menu()
                .frame(width: menuWidth, alignment: .leading)
                .offset(x: isOpen ? 0 : -60)
                .opacity(isOpen ? 1 : 0.6)
                .ignoresSafeArea()

            ZStack {
                main()
                    .disabled(isOpen)
                    
                // Stable Overlay
                Color.black
                    .opacity(isOpen ? 0.15 : 0)
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
        .ignoresSafeArea()
    }
}
