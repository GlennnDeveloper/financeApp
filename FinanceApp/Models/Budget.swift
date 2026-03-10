import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var categorySymbol: String
    var amount: Double
    var month: Date
    
    init(id: UUID = UUID(), categorySymbol: String, amount: Double, month: Date = Date()) {
        self.id = id
        self.categorySymbol = categorySymbol
        self.amount = amount
        self.month = month
    }
}
