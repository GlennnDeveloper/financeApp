import Foundation
import SwiftUI

struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let symbol: String
    let colorName: String // Color semantic name
    
    var color: Color {
        switch colorName {
        case "orange": return .orange
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "gray": return .gray
        case "teal": return .teal
        case "pink": return .pink
        case "indigo": return .indigo
        default: return .primary
        }
    }
    
    static let defaults: [Category] = [
        Category(name: "Food & Drink", symbol: "fork.knife", colorName: "orange"),
        Category(name: "Transport", symbol: "bus.fill", colorName: "blue"),
        Category(name: "Home Bills", symbol: "bolt.fill", colorName: "orange"),
        Category(name: "Self-Care", symbol: "sparkles", colorName: "purple"),
        Category(name: "Shopping", symbol: "bag.fill", colorName: "red"),
        Category(name: "Health", symbol: "cross.case.fill", colorName: "teal"),
        // Retained for income and fallbacks
        Category(name: "Salary", symbol: "banknote.fill", colorName: "green"),
        Category(name: "Others", symbol: "ellipsis.circle.fill", colorName: "gray")
    ]
}
