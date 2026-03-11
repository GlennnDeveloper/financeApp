import SwiftUI
import SwiftData

struct EditBudgetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @Bindable var budget: Budget
    @State private var amount: String
    
    init(budget: Budget) {
        self.budget = budget
        _amount = State(initialValue: String(format: "%.2f", budget.amount))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(SettingsManager.shared.localizedString(for: "Category")) {
                    HStack {
                        let cat = categories.first(where: { $0.symbol == budget.categorySymbol }) ?? Category.placeholder
                        Image(systemName: cat.symbol)
                            .foregroundStyle(cat.color)
                        Text(cat.localizedName)
                        Spacer()
                        Text(SettingsManager.shared.localizedString(for: "Fixed"))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                
                Section(SettingsManager.shared.localizedString(for: "Limit")) {
                    TextField(SettingsManager.shared.localizedString(for: "Amount"), text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { _, newValue in
                            let filtered = newValue.filter { "0123456789.,".contains($0) }
                            if filtered != newValue {
                                amount = filtered
                            }
                        }
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "Edit Budget"))
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.locale, SettingsManager.shared.locale)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Save")) {
                        if let value = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                            budget.amount = value
                            dismiss()
                        }
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
}
