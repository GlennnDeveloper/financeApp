import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var padding: CGFloat
    var opacity: Double
    var lowRes: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                ZStack {
                    if lowRes {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.45))
                    } else {
                        VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                            .opacity(opacity)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    }
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(lowRes ? 0.15 : 0.12), lineWidth: 0.5)
                }
            }
            .modifier(ShadowModifier(enabled: !lowRes))
    }
}

private struct ShadowModifier: ViewModifier {
    var enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        } else {
            content
        }
    }
}

// Helper for UIBlurEffect in SwiftUI
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24, padding: CGFloat = 0, opacity: Double = 0.8, lowRes: Bool = false) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding, opacity: opacity, lowRes: lowRes))
    }
}
