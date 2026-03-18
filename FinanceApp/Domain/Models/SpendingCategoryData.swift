import SwiftUI

struct SpendingCategoryData: Identifiable, Equatable {
    var id: String { symbol }
    let name: String
    let symbol: String
    let color: Color
    let totalSpent: Double
    let percentage: Double
}
