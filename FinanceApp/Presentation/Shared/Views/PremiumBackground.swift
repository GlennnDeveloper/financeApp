import SwiftUI

struct PremiumBackground: View {
    var colors: [Color] = [.orange, .red, .purple]
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background Blobs
            GeometryReader { proxy in
                ZStack {
                    // Top Leading Blob
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colors[0].opacity(0.4), colors[1].opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: proxy.size.width * 0.8)
                        .blur(radius: 80)
                        .offset(
                            x: animate ? -30 : 50,
                            y: animate ? -50 : 30
                        )
                    
                    // Bottom Trailing Blob
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colors[2].opacity(0.3), colors[1].opacity(0.1)],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: proxy.size.width * 0.9)
                        .blur(radius: 100)
                        .offset(
                            x: animate ? 80 : -40,
                            y: animate ? 100 : -20
                        )
                    
                    // Center Subtle Glow
                    Circle()
                        .fill(colors[0].opacity(0.05))
                        .frame(width: proxy.size.width * 1.2)
                        .blur(radius: 120)
                        .scaleEffect(animate ? 1.1 : 0.9)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
            }
            
            // Grainy Texture Overlay (Optional, but adds "premium" feel)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.2)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    PremiumBackground()
}
