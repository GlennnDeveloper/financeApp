import SwiftUI

/// A Rocket Money–style 3D side menu container.
///
/// The main content gets pushed to the right with scale + corner radius,
/// while the menu is revealed underneath. Supports drag gesture to open/close.
struct SideMenuContainerView<MenuContent: View, MainContent: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> MenuContent
    @ViewBuilder let main: () -> MainContent

    // ── Layout constants ──
    private let menuWidth: CGFloat = 300
    private let scaleEffect: CGFloat = 0.88
    private let cornerRadius: CGFloat = 30

    // ── Drag state ──
    @GestureState private var dragOffset: CGFloat = 0

    private var effectiveOffset: CGFloat {
        let base = isOpen ? menuWidth : 0
        let proposed = base + dragOffset
        return max(0, min(menuWidth, proposed)) // Clamp between 0 and menuWidth
    }

    private var progress: CGFloat {
        effectiveOffset / menuWidth // 0.0 → 1.0
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // ── Background ──
            Color.black.ignoresSafeArea()

            // ── Side Menu (underneath) ──
            menu()
                .frame(width: menuWidth, alignment: .leading)
                .offset(x: -60 * (1 - progress)) // Subtle slide-in
                .opacity(0.6 + 0.4 * progress)

            // ── Main Content (on top, pushed right) ──
            ZStack {
                main()
                    .disabled(isOpen)

                // Dark overlay when menu is open
                Color.black.opacity(0.4 * progress)
                    .ignoresSafeArea()
                    .allowsHitTesting(isOpen)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isOpen = false
                        }
                    }
            }
            .scaleEffect(1 - (1 - scaleEffect) * progress)
            .offset(x: effectiveOffset)
            .cornerRadius(cornerRadius * progress)
            .shadow(color: .black.opacity(0.4 * progress), radius: 20, x: -5, y: 0)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.width
                        let threshold: CGFloat = menuWidth * 0.4

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if isOpen {
                                // Close if dragged left enough or flung left
                                isOpen = (effectiveOffset + velocity) > threshold
                            } else {
                                // Open if dragged right enough or flung right
                                isOpen = (value.translation.width + velocity) > threshold
                            }
                        }
                    }
            )
        }
    }
}
