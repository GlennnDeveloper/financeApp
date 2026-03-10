import Foundation

struct ChartItem: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let amount: Double
    let date: Date
}
