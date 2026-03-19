import Foundation

enum ChartItemType: String, Equatable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

struct ChartItem: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let amount: Double
    let date: Date
    var type: ChartItemType = .expense
}
