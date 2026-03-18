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
                    // Top Leading Blob (Orange/Red - Signup Path)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [colors[0].opacity(0.5), colors[1].opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: proxy.size.width * 1.0)
                        .blur(radius: 60) // Reduced from 100
                        .offset(
                            x: animate ? -120 : 160,
                            y: animate ? -150 : 120
                        )
                    
                    // Bottom Trailing Blob (Blue/Purple - Login Path)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (colors.count > 3 ? colors[3] : colors[2]).opacity(0.5),
                                    colors[2].opacity(0.3)
                                ],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: proxy.size.width * 1.1)
                        .blur(radius: 70) // Reduced from 120
                        .offset(
                            x: animate ? 180 : -140,
                            y: animate ? 150 : -100
                        )
                    
                    // Center Subtle Glow
                    Circle()
                        .fill((colors.count > 3 ? colors[3] : colors[0]).opacity(0.1))
                        .frame(width: proxy.size.width * 1.4)
                        .blur(radius: 80) // Reduced from 140
                        .scaleEffect(animate ? 1.2 : 0.8)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .drawingGroup() // Triggers Metal-backed rendering for complex blurs
                .onAppear {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
            }
            .ignoresSafeArea()
            
            // Simplified Texture Overlay (Fixed performance cost)
            Rectangle()
                .fill(Color.black.opacity(0.25)) // Replaced ultraThinMaterial (very expensive)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    PremiumBackground()
}
