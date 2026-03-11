import SwiftUI
import SwiftData

struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var name: String = ""
    @State private var selectedSymbol: String = "cart"
    @State private var selectedColor: String = "blue"
    
    let orderIndex: Int
    
    let symbols = ["cart", "star", "heart", "gift", "gamecontroller", "tv", "book", "airplane", "laundry", "leaf", "fork.knife", "bus.fill", "bolt.fill", "sparkles", "bag.fill", "cross.case.fill", "banknote.fill"]
    let colorNames = ["blue", "green", "orange", "red", "purple", "pink", "teal", "indigo", "gray"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(settingsManager.localizedString(for: "Category Name")) {
                    TextField(settingsManager.localizedString(for: "Hobby, Subscriptions..."), text: $name)
                }
                
                Section(settingsManager.localizedString(for: "Icon")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(symbols, id: \.self) { sym in
                                Image(systemName: sym)
                                    .font(.title2)
                                    .foregroundStyle(selectedSymbol == sym ? Color.white : Color.primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedSymbol == sym ? .blue : Color(uiColor: .systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture { selectedSymbol = sym }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(settingsManager.localizedString(for: "Color")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorNames, id: \.self) { color in
                                Circle()
                                    .fill(mapColor(color))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture { selectedColor = color }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(settingsManager.localizedString(for: "New Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settingsManager.localizedString(for: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settingsManager.localizedString(for: "Save")) {
                        let newCat = Category(name: name, symbol: selectedSymbol, colorName: selectedColor, isDefault: false, orderIndex: orderIndex)
                        modelContext.insert(newCat)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func mapColor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .gray
        }
    }
}
