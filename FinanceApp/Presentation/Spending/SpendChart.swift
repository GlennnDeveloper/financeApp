import SwiftUI
import Charts

struct SpendChartData: Identifiable {
    let id = UUID()
    let day: Int
    let accumulatedAmount: Double
}

struct SpendSummaryChart: View {
    var transactions: [Transaction]
    
    // Simularemos un gradiente de área morada para los gastos acumulados del mes
    private var chartData: [SpendChartData] {
        let calendar = Calendar.current
        let now = Date.now

        // Filtramos solo los gastos de este mes
        let expenses = transactions.filter {
            !$0.isIncome &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }.sorted(by: { $0.date < $1.date }) // Orden cronológico
        
        var accumulated: Double = 0
        var data: [SpendChartData] = []
        
        // Generamos datos acumulativos día a día para el gráfico suave
        // Mapeamos los días del mes para el eje X
        for day in 1...calendar.component(.day, from: .now) {
            let dayExpenses = expenses.filter { calendar.component(.day, from: $0.date) == day }
            accumulated += dayExpenses.reduce(0) { $0 + $1.amount }
            
            // Si hay datos reales acumulados (o para forzar la curva inicial)
            data.append(SpendChartData(day: day, accumulatedAmount: accumulated))
        }
        
        // Si no hay datos, mostramos una línea base
        if data.isEmpty {
            return [SpendChartData(day: 1, accumulatedAmount: 0), SpendChartData(day: 15, accumulatedAmount: 0)]
        }
        return data
    }
    
    var body: some View {
        Chart(chartData) { item in
            // Línea principal
            LineMark(
                x: .value("Día", item.day),
                y: .value("Gasto", item.accumulatedAmount)
            )
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color(red: 0.35, green: 0.2, blue: 0.6)) // Morado característico
            .symbol {
                // Último punto con círculo
                if item.id == chartData.last?.id {
                    Circle()
                        .strokeBorder(Color(red: 0.35, green: 0.2, blue: 0.6), lineWidth: 3)
                        .background(Circle().fill(.white))
                        .frame(width: 10, height: 10)
                }
            }
            // Interpolación suavizada (Spline)
            .interpolationMethod(.monotone)
            
            // Área de gradiente debajo de la línea
            AreaMark(
                x: .value("Día", item.day),
                y: .value("Gasto", item.accumulatedAmount)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 0.35, green: 0.2, blue: 0.6).opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 100)
        // Línea de base "BUDGET"
        .overlay(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                Text("BUDGET")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(1)
                    .padding(.bottom, 2)
                    .padding(.trailing, 8)
                
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 350, y: 0)) // Aproximado para llenar el ancho
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundStyle(.gray.opacity(0.3))
                .frame(height: 1)
            }
            .offset(y: 10) // Ajuste para posicionar la línea punteada como en el diseño
        }
    }
}
