import SwiftUI
import SwiftData

struct CategoryRulesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var rules: [Rule]
    @State private var showingAddRule = false
    @State private var showingAddCategory = false
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.indigo, .purple, .black])
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(SettingsManager.shared.localizedString(for: "Available Categories"))
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                showingAddCategory = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
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
                                        .foregroundStyle(.white)
                                    
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
                        .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                        .padding(.horizontal)
                    }
                    
                    // Rules Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(SettingsManager.shared.localizedString(for: "Custom Rules"))
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                showingAddRule = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        if rules.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.2))
                                Text(SettingsManager.shared.localizedString(for: "No custom rules yet"))
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(SettingsManager.shared.localizedString(for: "Rules help automatically categorize transactions based on their title."))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(rules) { rule in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rule.pattern)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.white)
                                            Text("\(SettingsManager.shared.localizedString(for: "Categorize as")) \(categories.first(where: { $0.symbol == rule.categorySymbol })?.localizedName ?? SettingsManager.shared.localizedString(for: "Others"))")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.6))
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
                            .glassCard(cornerRadius: 16, padding: 0, lowRes: true)
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
                AddCategorySheet(orderIndex: categories.count)
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
