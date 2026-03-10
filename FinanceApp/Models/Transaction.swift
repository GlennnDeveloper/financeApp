import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var isIncome: Bool
    var categorySymbol: String
    @Attribute(.unique) var externalId: String? // Plaid transaction_id
    var isRecurring: Bool = false // Indicates if it's a subscription or regular payment
    
    init(id: UUID = UUID(), 
         title: String, 
         amount: Double, 
         date: Date = .now, 
         isIncome: Bool, 
         categorySymbol: String = "dollarsign.circle.fill",
         externalId: String? = nil,
         isRecurring: Bool = false) {
        
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.isIncome = isIncome
        self.categorySymbol = categorySymbol
        self.externalId = externalId
        self.isRecurring = isRecurring
    }
}
