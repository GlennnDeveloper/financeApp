import SwiftUI
import Charts

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let type: String
    let amount: Double
}

struct FinanceChart: View {
    var transactions: [Transaction]
    
    /// Agrupación lógica de transacciones por día para los últimos 7 días
    private var chartData: [ChartData] {
        let calendar = Calendar.current
        var data: [ChartData] = []
        
        // Iteramos sobre los últimos 7 días
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: .now)),
                  let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { continue }
            
            let dailyTxs = transactions.filter { $0.date >= date && $0.date < nextDate }
            
            let income = dailyTxs.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            let expense = dailyTxs.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
            
            // Solo añadimos si hay datos, o añadimos 0 para mantener la gráfica uniforme
            data.append(ChartData(date: date, type: "Ingreso", amount: income))
            data.append(ChartData(date: date, type: "Gasto", amount: expense))
        }
        return data
    }
    
    var body: some View {
        Chart(chartData) { item in
            BarMark(
                x: .value("Día", item.date, unit: .day),
                y: .value("Monto", item.amount)
            )
            .foregroundStyle(item.type == "Ingreso" ? Color.green.gradient : Color.orange.gradient)
            .position(by: .value("Tipo", item.type))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
            }
        }
        .chartLegend(.hidden) // Ocultamos la leyenda para mantener el diseño limpio
        .frame(height: 220)
        .padding()
        // Contenedor semántico adaptativo a Dark/Light Mode
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    FinanceChart(transactions: [])
}
