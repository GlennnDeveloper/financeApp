import SwiftUI

/// Standardized button styles for the application.
struct AppButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case custom(colors: [Color])
    }
    
    let title: String
    var icon: String? = nil
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    let action: () -> Void
    
    private var gradientColors: [Color] {
        switch style {
        case .primary: return [.blue, .purple]
        case .secondary: return [.white.opacity(0.1), .white.opacity(0.05)]
        case .destructive: return [.red.opacity(0.8), .red]
        case .custom(let colors): return colors
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive, .custom: return .white
        case .secondary: return .white
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if case .secondary = style {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(gradientColors[0])
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: gradientColors.last?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                }
            }
            .foregroundStyle(foregroundColor)
        }
        .disabled(isLoading)
    }
}

/// A circular button with a system icon.
struct AppIconButton: View {
    let icon: String
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppButton(title: "Primary Action", action: {})
        AppButton(title: "Secondary Action", style: .secondary, action: {})
        AppButton(title: "Destructive Action", style: .destructive, action: {})
        AppButton(title: "Loading...", isLoading: true, action: {})
        AppIconButton(icon: "plus", action: {})
    }
    .padding()
    .background(Color.black.opacity(0.8))
}
