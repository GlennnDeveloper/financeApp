import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var transactions: [Transaction]
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @State private var showingAddBudget = false
    @State private var selectedCategory: Category?
    @State private var budgetAmount: String = ""
    
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.amount } }
    private var totalSpent: Double { transactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount } }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Header
                VStack(spacing: 8) {
                    Text("Monthly Budget")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        
                    Text("$\(Int(totalBudget))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    HStack {
                        Text("Spent: $\(Int(totalSpent))")
                        Text("•")
                        Text("Remaining: $\(Int(max(0, totalBudget - totalSpent)))")
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                }
                .padding(.top, 20)
                
                // Budget List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Categories")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                    
                    if budgets.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray.opacity(0.3))
                            Text("No budgets set yet")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Button("Set first budget") {
                                showingAddBudget = true
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 1) {
                            ForEach(budgets) { budget in
                                BudgetRow(budget: budget, transactions: transactions, categories: categories)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                
                                if budget.id != budgets.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Manage Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddBudget = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetSheet()
        }
    }
}

private struct BudgetRow: View {
    let budget: Budget
    let transactions: [Transaction]
    let categories: [Category]
    
    var body: some View {
        let category = categories.first(where: { $0.symbol == budget.categorySymbol }) ?? categories.first ?? Category.placeholder
        let spent = transactions
            .filter { $0.categorySymbol == budget.categorySymbol && !$0.isIncome }
            .reduce(0) { $0 + $1.amount }
        let progress = min(1.0, spent / budget.amount)
        
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: budget.categorySymbol)
                            .font(.caption)
                            .foregroundStyle(category.color)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.localizedName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("$\(Int(spent)) of $\(Int(budget.amount))")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(progress >= 1.0 ? .red : .gray)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(progress >= 1.0 ? Color.red : category.color)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct AddBudgetSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @State private var selectedSymbol: String?
    @State private var amount: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Select Category", selection: $selectedSymbol) {
                        ForEach(categories) { cat in
                            HStack {
                                Image(systemName: cat.symbol)
                                Text(cat.localizedName)
                            }
                            .tag(cat.symbol as String?)
                        }
                    }
                }
                
                Section("Limit") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Double(amount) {
                            let newBudget = Budget(categorySymbol: selectedSymbol ?? categories.first?.symbol ?? "fork.knife", amount: value)
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

#Preview {
    NavigationStack {
        BudgetView()
            .modelContainer(for: [Budget.self, Transaction.self], inMemory: true)
    }
}
