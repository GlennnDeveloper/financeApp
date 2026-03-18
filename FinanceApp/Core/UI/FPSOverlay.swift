import SwiftUI

struct FPSOverlay: View {
    @StateObject private var fpsManager = FPSManager.shared
    
    var body: some View {
        Text("\(fpsManager.currentFPS) FPS")
            .font(.system(.caption, design: .monospaced).bold())
            .foregroundStyle(fpsColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .onAppear { fpsManager.start() }
            .onDisappear { fpsManager.stop() }
    }
    
    private var fpsColor: Color {
        if fpsManager.currentFPS >= 55 { return .green }
        if fpsManager.currentFPS >= 30 { return .yellow }
        return .red
    }
}
