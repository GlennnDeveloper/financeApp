import SwiftUI
import Charts
struct TestView: View {
    var data = ["A": 10]
    var dict: [String: Color] = ["A": .red]
    var body: some View {
        Chart {
            BarMark(x: .value("A", "A"), y: .value("B", 10))
            .foregroundStyle(by: .value("K", "A"))
        }
        .chartForegroundStyleScale(dict)
    }
}
