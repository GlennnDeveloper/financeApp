import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var balance: Double
    var symbol: String
    var colorName: String
    var orderIndex: Int
    var isLiability: Bool? // Optional to avoid migration crashes on old data
    
    init(id: UUID = UUID(), name: String, balance: Double, symbol: String, colorName: String, orderIndex: Int, isLiability: Bool? = false) {
        self.id = id
        self.name = name
        self.balance = balance
        self.symbol = symbol
        self.colorName = colorName
        self.orderIndex = orderIndex
        self.isLiability = isLiability
    }
}
