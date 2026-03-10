import SwiftUI

struct SideMenuContainerView<MenuContent: View, MainContent: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> MenuContent
    @ViewBuilder let main: () -> MainContent

    private let menuWidth: CGFloat = 300
    private let cornerRadius: CGFloat = 30

    @GestureState private var dragOffset: CGFloat = 0

    private var effectiveOffset: CGFloat {
        let base = isOpen ? menuWidth : 0
        let proposed = base + dragOffset
        return max(0, min(menuWidth, proposed))
    }

    private var progress: CGFloat {
        effectiveOffset / menuWidth
    }

    private var screenSize: CGSize {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size ?? .zero
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            menu()
                .frame(width: menuWidth, alignment: .leading)
                .offset(x: -60 * (1 - progress))
                .opacity(0.6 + 0.4 * progress)
                .ignoresSafeArea()

            ZStack {
                main()
                    .disabled(isOpen)
                    
                if progress > 0 {
                    Color.clear
                        .contentShape(Rectangle())
                        .allowsHitTesting(isOpen)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isOpen = false
                            }
                        }
                }
            }
            // 2. Movemos la vista
            .offset(x: effectiveOffset)
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
                                isOpen = (effectiveOffset + velocity) > threshold
                            } else {
                                isOpen = (value.translation.width + velocity) > threshold
                            }
                        }
                    }
            )
        }
        // 4. Ignorar el Safe Area en la raíz aisla las animaciones de los recálculos del sistema
        .ignoresSafeArea()
    }
}
