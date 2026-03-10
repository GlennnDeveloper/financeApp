import SwiftUI

struct SideMenuContainerView<MenuContent: View, MainContent: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder let menu: () -> MenuContent
    @ViewBuilder let main: () -> MainContent

    private let menuWidth: CGFloat = 300
    private let scaleEffect: CGFloat = 0.88
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
                    Color.black.opacity(0.4 * progress)
                        .allowsHitTesting(isOpen)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isOpen = false
                            }
                        }
                }
            }
            // 1. Tamaño fijo absoluto basado en la pantalla física (sin GeometryReader ni paddings)
            .frame(width: screenSize.width, height: screenSize.height)
            // 2. Agrupamos la vista ANTES de las transformaciones
            .compositingGroup()
            // 3. Recortamos, escalamos y movemos
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius * progress,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius * progress
            ))
            .scaleEffect(1 - (1 - scaleEffect) * progress)
            .offset(x: effectiveOffset)
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
