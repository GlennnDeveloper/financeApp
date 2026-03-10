import Foundation
import SwiftUI
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbol: String
    var colorName: String
    var isDefault: Bool
    var orderIndex: Int

    init(id: UUID = UUID(), 
         name: String, 
         symbol: String, 
         colorName: String, 
         isDefault: Bool = false,
         orderIndex: Int = 0) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorName = colorName
        self.isDefault = isDefault
        self.orderIndex = orderIndex
    }

    // Static O(1) color lookup
    private static let colorMap: [String: Color] = [
        "orange": .orange,
        "red":    .red,
        "blue":   .blue,
        "green":  .green,
        "purple": .purple,
        "gray":   .gray,
        "teal":   .teal,
        "pink":   .pink,
        "indigo": .indigo
    ]

    var color: Color { Self.colorMap[colorName] ?? .primary }

    var localizedName: String {
        NSLocalizedString(name, comment: "")
    }

    static let defaultData: [Category] = [
        Category(name: "Food & Drink", symbol: "fork.knife",           colorName: "orange", isDefault: true, orderIndex: 0),
        Category(name: "Transport",    symbol: "bus.fill",             colorName: "blue",   isDefault: true, orderIndex: 1),
        Category(name: "Home Bills",   symbol: "bolt.fill",            colorName: "orange", isDefault: true, orderIndex: 2),
        Category(name: "Self-Care",    symbol: "sparkles",             colorName: "purple", isDefault: true, orderIndex: 3),
        Category(name: "Shopping",     symbol: "bag.fill",             colorName: "red",    isDefault: true, orderIndex: 4),
        Category(name: "Health",       symbol: "cross.case.fill",      colorName: "teal",   isDefault: true, orderIndex: 5),
        Category(name: "Salary",       symbol: "banknote.fill",        colorName: "green",  isDefault: true, orderIndex: 6),
        Category(name: "Others",       symbol: "ellipsis.circle.fill", colorName: "gray",   isDefault: true, orderIndex: 7)
    ]
    
    static var placeholder: Category {
        defaultData.last!
    }
}
