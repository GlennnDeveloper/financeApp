import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var rules: [Rule]
    @Query private var transactions: [Transaction]
    
    @State private var viewModel = FinanceViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var showSettings = false
    
    init() {
        // Tab bar appearance will automatically follow the theme
    }
    
    var body: some View {
        NavigationStack {
            SideMenuContainerView(isOpen: $showSettings) {
                SideMenuContent(isOpen: $showSettings)
                    .environmentObject(authViewModel)
            } main: {
                TabView {
                    DashboardView(showSettings: $showSettings)
                        .tabItem {
                            Label("Dashboard", systemImage: "square.grid.2x2")
                        }
                    
                    RecurringView()
                        .tabItem {
                            Label("Recurring", systemImage: "calendar")
                        }
                    
                    NetWorthView()
                        .tabItem {
                            Label("Net Worth", systemImage: "chart.bar.fill")
                        }
                    
                    SpendingView()
                        .tabItem {
                            Label("Spending", systemImage: "wallet.pass")
                        }
                    
                    TransactionsView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                }
                .tint(.blue)
            }
        }
        .onAppear {
            viewModel.seedDefaultCategoriesIfNeeded(context: modelContext, existingCategories: categories)
            viewModel.autoCategorizeTransactions(context: modelContext, transactions: transactions, rules: rules, categories: categories)
        }
        .onChange(of: rules) { _, _ in
            viewModel.autoCategorizeTransactions(context: modelContext, transactions: transactions, rules: rules, categories: categories)
        }
        .onChange(of: categories) { _, _ in
            viewModel.autoCategorizeTransactions(context: modelContext, transactions: transactions, rules: rules, categories: categories)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Transaction.self, Account.self, Rule.self], inMemory: true)
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsManager.shared)
}
