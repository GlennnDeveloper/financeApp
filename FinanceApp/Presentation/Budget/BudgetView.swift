import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var showingAddBudget = false
    @State private var editingBudget: Budget?
    @State private var selectedMonth = Date().startOfMonth
    
    private var filteredBudgets: [Budget] {
        budgets.filter { Calendar.current.isDate($0.month, inSameDayAs: selectedMonth) }
    }
    
    private var totalBudget: Double { filteredBudgets.reduce(0) { $0 + $1.amount } }
    private var totalSpent: Double {
        transactions
            .filter { !$0.isIncome && Calendar.current.isDate($0.date, inSameDayAs: selectedMonth) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Month Selector Header
                monthSelector
                
                // Visual Summary (Donut-like progress)
                BudgetSummaryChart(totalBudget: totalBudget, totalSpent: totalSpent)
                    .padding(.top, 10)
                
                // Details Grid
                HStack(spacing: 20) {
                    summaryCard(title: "Remaining", value: max(0, totalBudget - totalSpent), color: .green)
                    summaryCard(title: "Over Budget", value: max(0, totalSpent - totalBudget), color: .red)
                }
                .padding(.horizontal)
                
                // Budget List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(SettingsManager.shared.localizedString(for: "Categories"))
                            .font(.headline)
                        Spacer()
                        if !filteredBudgets.isEmpty {
                            Text("\(filteredBudgets.count) \(SettingsManager.shared.localizedString(for: "active"))")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    if filteredBudgets.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(filteredBudgets) { budget in
                                BudgetRow(budget: budget, transactions: transactions, categories: categories, selectedMonth: selectedMonth) {
                                    editingBudget = budget
                                } onDelete: {
                                    modelContext.delete(budget)
                                }
                                
                                if budget.id != filteredBudgets.last?.id {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(SettingsManager.shared.localizedString(for: "Manage Budget"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !filteredBudgets.isEmpty {
                    Button {
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetSheet(month: selectedMonth)
        }
        .sheet(item: $editingBudget) { budget in
            EditBudgetSheet(budget: budget)
        }
    }
    
    private var monthSelector: some View {
        HStack {
            Button { moveMonth(by: -1) } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .foregroundStyle(.gray.opacity(0.3))
            }
            
            Spacer()
            
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            
            Spacer()
            
            Button { moveMonth(by: 1) } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundStyle(.gray.opacity(0.3))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var emptyState: some View {
        Button {
            showingAddBudget = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.blue.opacity(0.8))
                
                VStack(spacing: 4) {
                    Text(SettingsManager.shared.localizedString(for: "No budgets set yet"))
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Text(SettingsManager.shared.localizedString(for: "Tap to set your first budget"))
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    private func summaryCard(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(SettingsManager.shared.localizedString(for: title))
                .font(.caption2)
                .foregroundStyle(Color.gray)
            Text(value.formatted(.currency(code: settingsManager.appCurrency)))
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            withAnimation {
                selectedMonth = newDate
            }
        }
    }
}

private struct BudgetRow: View {
    let budget: Budget
    let transactions: [Transaction]
    let categories: [Category]
    let selectedMonth: Date
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var category: Category {
        categories.first(where: { $0.symbol == budget.categorySymbol }) ?? categories.first ?? Category.placeholder
    }
    
    private var spent: Double {
        transactions
            .filter { 
                $0.categorySymbol == budget.categorySymbol && 
                !$0.isIncome && 
                Calendar.current.isDate($0.date, inSameDayAs: selectedMonth)
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        min(1.0, spent / budget.amount)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: budget.categorySymbol)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(category.color)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.localizedName)
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text(spent.formatted(.currency(code: SettingsManager.shared.appCurrency)))
                            .font(.body.weight(.semibold))
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.05))
                                .frame(height: 8)
                            
                            Capsule()
                                .fill(progress >= 1.0 ? Color.red : category.color)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(String(format: SettingsManager.shared.localizedString(for: "of %@"), budget.amount.formatted(.currency(code: SettingsManager.shared.appCurrency))))
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.bold())
                            .foregroundStyle(progress >= 1.0 ? Color.red : Color.gray)
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
        }
    }
}

// MARK: - Subviews

private struct BudgetSummaryChart: View {
    let totalBudget: Double
    let totalSpent: Double
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        let progress = totalBudget > 0 ? min(1.0, totalSpent / totalBudget) : 0
        
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            progress >= 1.0 ? .red : .blue,
                            progress >= 1.0 ? .red.opacity(0.8) : .cyan
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(progress * 360 - 90)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(0))
                .animation(.spring(), value: progress)
            
            VStack(spacing: 4) {
                Text(SettingsManager.shared.localizedString(for: "Spent"))
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                Text(totalSpent.formatted(.currency(code: settingsManager.appCurrency)))
                    .font(.title.bold())
                Text(String(format: SettingsManager.shared.localizedString(for: "of %@"), totalBudget.formatted(.currency(code: settingsManager.appCurrency))))
                    .font(.caption2)
                    .foregroundStyle(Color.gray)
            }
        }
    }
}

private struct CategoryGridItem: View {
    let category: Category
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(category.color.opacity(isSelected ? 1.0 : 0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: category.symbol)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : category.color)
                }
            
            Text(category.localizedName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? Color.primary : Color.gray)
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
    }
}

private struct AddBudgetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @State private var selectedSymbol: String?
    @State private var amount: String = ""
    @State private var showingAddCategory = false
    let month: Date
    
    private let columns = [
        GridItem(.adaptive(minimum: 70, maximum: 100), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(categories) { cat in
                            CategoryGridItem(
                                category: cat,
                                isSelected: selectedSymbol == cat.symbol
                            )
                            .onTapGesture {
                                selectedSymbol = cat.symbol
                            }
                        }
                        
                        // Add New Category Button
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.primary.opacity(0.05))
                                .frame(width: 50, height: 50)
                                .overlay {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundStyle(Color.gray)
                                }
                            
                            Text(SettingsManager.shared.localizedString(for: "New"))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(Color.gray)
                        }
                        .onTapGesture {
                            showingAddCategory = true
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(SettingsManager.shared.localizedString(for: "Select Category"))
                }
                
                Section(SettingsManager.shared.localizedString(for: "Limit")) {
                    TextField(SettingsManager.shared.localizedString(for: "Amount"), text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { _, newValue in
                            // Filter non-numeric characters except for decimal separator
                            let filtered = newValue.filter { "0123456789.,".contains($0) }
                            if filtered != newValue {
                                amount = filtered
                            }
                        }
                }
            }
            .navigationTitle(SettingsManager.shared.localizedString(for: "New Budget"))
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.locale, SettingsManager.shared.locale)
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet(orderIndex: categories.count)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(SettingsManager.shared.localizedString(for: "Save")) {
                        if let value = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                            let newBudget = Budget(categorySymbol: selectedSymbol ?? categories.first?.symbol ?? "fork.knife", amount: value, month: month)
                            modelContext.insert(newBudget)
                            dismiss()
                        }
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
}

extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }
}

extension Date: Identifiable {
    public var id: String { self.description }
}

#Preview {
    NavigationStack {
        BudgetView()
            .modelContainer(for: [Budget.self, Transaction.self, Category.self], inMemory: true)
            .environmentObject(SettingsManager.shared)
    }
}
