import SwiftUI

/// A reusable circular icon for categories with dynamic sizing and styling.
struct CategoryIcon: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 50
    var iconScale: CGFloat = 0.4
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            Image(systemName: symbol)
                .font(.system(size: size * iconScale, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    HStack {
        CategoryIcon(symbol: "cart.fill", color: .orange)
        CategoryIcon(symbol: "bus.fill", color: .blue, size: 40)
        CategoryIcon(symbol: "house.fill", color: .green, size: 60)
    }
    .padding()
    .background(Color.black)
}
