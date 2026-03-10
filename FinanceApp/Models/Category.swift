import Foundation
import SwiftUI

struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let symbol: String
    let colorName: String // Color semantic name

    // Static O(1) color lookup — built once at app start
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

    static let defaults: [Category] = [
        Category(name: "Food & Drink", symbol: "fork.knife",           colorName: "orange"),
        Category(name: "Transport",    symbol: "bus.fill",             colorName: "blue"),
        Category(name: "Home Bills",   symbol: "bolt.fill",            colorName: "orange"),
        Category(name: "Self-Care",    symbol: "sparkles",             colorName: "purple"),
        Category(name: "Shopping",     symbol: "bag.fill",             colorName: "red"),
        Category(name: "Health",       symbol: "cross.case.fill",      colorName: "teal"),
        // Retained for income and fallbacks
        Category(name: "Salary",       symbol: "banknote.fill",        colorName: "green"),
        Category(name: "Others",       symbol: "ellipsis.circle.fill", colorName: "gray")
    ]

    // O(1) symbol → color lookup used by TransactionRow and other views
    static let symbolColorMap: [String: Color] = {
        var map = [String: Color]()
        for cat in defaults { map[cat.symbol] = cat.color }
        return map
    }()

    // O(1) symbol → category lookup
    static let symbolCategoryMap: [String: Category] = {
        var map = [String: Category]()
        for cat in defaults { map[cat.symbol] = cat }
        return map
    }()
}

