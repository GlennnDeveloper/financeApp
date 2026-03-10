import SwiftUI
import SwiftData

struct CategoryRulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var rules: [Rule]
    @State private var showingAddRule = false
    @State private var showingAddCategory = false
    
    var body: some View {
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(SettingsManager.shared.localizedString(for: "Available Categories"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showingAddCategory = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            ForEach(categories) { category in
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(category.color.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Image(systemName: category.symbol)
                                                .font(.subheadline)
                                                .foregroundStyle(category.color)
                                        }
                                    
                                    Text(category.localizedName)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    if !category.isDefault {
                                        Button(role: .destructive) {
                                            modelContext.delete(category)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundStyle(.red.opacity(0.6))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if category.id != categories.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                    
                    // Rules Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(SettingsManager.shared.localizedString(for: "Custom Rules"))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Button {
                                showingAddRule = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        if rules.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray.opacity(0.3))
                                Text(SettingsManager.shared.localizedString(for: "No custom rules yet"))
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                Text(SettingsManager.shared.localizedString(for: "Rules help automatically categorize transactions based on their title."))
                                    .font(.caption)
                                    .foregroundStyle(.gray.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(rules) { rule in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rule.pattern)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text("\(SettingsManager.shared.localizedString(for: "Categorize as")) \(categories.first(where: { $0.symbol == rule.categorySymbol })?.localizedName ?? SettingsManager.shared.localizedString(for: "Others"))")
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(role: .destructive) {
                                            modelContext.delete(rule)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundStyle(.red.opacity(0.6))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    if rule.id != rules.last?.id {
                                        Divider().padding(.horizontal)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "Categories & Rules"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddRule) {
                AddRuleSheet(categories: categories)
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(orderIndex: categories.count)
            }
        }
    }


private struct AddCategorySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedSymbol: String = "cart"
    @State private var selectedColor: String = "blue"
    
    let orderIndex: Int
    
    let symbols = ["cart", "star", "heart", "gift", "gamecontroller", "tv", "book", "airplane", "laundry", "leaf"]
    let colorNames = ["blue", "green", "orange", "red", "purple", "pink", "teal", "indigo", "gray"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(SettingsManager.shared.localizedString(for: "Category Name")) {
                    TextField(SettingsManager.shared.localizedString(for: "Hobby, Subscriptions..."), text: $name)
                }
                
                Section(SettingsManager.shared.localizedString(for: "Icon")) {
                    Picker(SettingsManager.shared.localizedString(for: "Icon"), selection: $selectedSymbol) {
                        ForEach(symbols, id: \.self) { sym in
                            Image(systemName: sym).tag(sym)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                }
                
                Section(SettingsManager.shared.localizedString(for: "Color")) {
                    Picker(SettingsManager.shared.localizedString(for: "Color"), selection: $selectedColor) {
                        ForEach(colorNames, id: \.self) { color in
                            HStack {
                                Circle().fill(mapColor(color)).frame(width: 12)
                                Text(SettingsManager.shared.localizedString(for: color.capitalized))
                            }.tag(color)
                        }
                    }
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "New Category"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Save")) {
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

private struct AddRuleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    
    @State private var pattern: String = ""
    @State private var selectedSymbol: String
    
    init(categories: [Category]) {
        self.categories = categories
        _selectedSymbol = State(initialValue: categories.first?.symbol ?? "fork.knife")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(SettingsManager.shared.localizedString(for: "Rule Pattern")) {
                    TextField(SettingsManager.shared.localizedString(for: "Title contains..."), text: $pattern)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section(SettingsManager.shared.localizedString(for: "Target Category")) {
                    Picker(SettingsManager.shared.localizedString(for: "Category"), selection: $selectedSymbol) {
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.symbol)
                                Text(cat.localizedName)
                            }
                            .tag(cat.symbol)
                        }
                    }
                }
                
                Section {
                    Text(SettingsManager.shared.localizedString(for: "Whenever a transaction title matches this pattern, it will be automatically assigned to the selected category."))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "New Rule"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Save")) {
                        let newRule = Rule(pattern: pattern, categorySymbol: selectedSymbol)
                        modelContext.insert(newRule)
                        dismiss()
                    }
                    .disabled(pattern.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CategoryRulesView()
            .modelContainer(for: [Rule.self], inMemory: true)
    }
}
