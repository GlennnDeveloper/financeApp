import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var isIncome: Bool = false
    @State private var selectedSymbol: String?
    
    private var selectedCategory: Category? {
        if let selectedSymbol = selectedSymbol {
            return categories.first(where: { $0.symbol == selectedSymbol })
        }
        return categories.first
    }
    
    // Focus to invoke the keyboard automatically
    @FocusState private var isAmountFocused: Bool
    
    // App brand gradient (Rocket)
    let brandGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.1, blue: 0.5), Color(red: 0.8, green: 0.1, blue: 0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Liquid Glass Background (Glassmorphism)
            Color.white.opacity(0.1) // Base transparente
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea() // This creates the premium frosted glass effect

            VStack(spacing: 0) {
                // Header Custom: Title + Close Button (PINNED)
                HStack {
                    Text(settingsManager.localizedString(for: "New Transaction"))
                        .font(.title3.weight(.bold))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Scrollable content area
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Toggle Expense / Income Stylized (Pill mode)
                        HStack(spacing: 0) {
                            SegmentButton(title: settingsManager.localizedString(for: "Expense"), isSelected: !isIncome) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isIncome = false
                                }
                            }
                            SegmentButton(title: settingsManager.localizedString(for: "Income"), isSelected: isIncome) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isIncome = true
                                }
                            }
                        }
                        .background(Color(UIColor.systemGray5).opacity(0.6), in: Capsule())
                        .padding(.horizontal, 40)

                        // Giant Amount Field (Apple Cash style)
                        VStack(spacing: 8) {
                            TextField("0", text: $amountText)
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFocused)
                                .foregroundStyle(isIncome ? .green : .primary)
                                .onChange(of: amountText) { _, newValue in
                                    // Robust filtering: numbers and a single decimal point (comma or dot)
                                    let filtered = newValue.filter { "0123456789.,".contains($0) }
                                    if filtered != newValue {
                                        amountText = filtered
                                    }
                                }

                            Text(settingsManager.localizedString(for: "Enter amount"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 16)

                        // Main Form (Glass Cards)
                        VStack(spacing: 16) {
                            // Title (Note)
                            HStack {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                TextField(SettingsManager.shared.localizedString(for: "What was this for?"), text: $title)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            // Date Selector
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                DatePicker(SettingsManager.shared.localizedString(for: "Date"), selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            // Category Selector (Custom Horizontal Scroll)
                            VStack(alignment: .leading, spacing: 12) {
                                Text(SettingsManager.shared.localizedString(for: "Category"))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 8)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(categories) { category in
                                            CategoryPill(category: category, isSelected: selectedCategory?.id == category.id)
                                                .onTapGesture {
                                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                                    generator.impactOccurred()

                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedSymbol = category.symbol
                                                    }
                                                }
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)

                        // Save Button (Glow Effect)
                        Button(action: saveTransaction) {
                            Text(settingsManager.localizedString(for: "Save Transaction"))
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    canSave ? brandGradient : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                                )
                                .shadow(color: canSave ? Color(red: 0.8, green: 0.1, blue: 0.3).opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!canSave)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .ignoresSafeArea(.keyboard) // Keyboard overlaps instead of pushing content up
        .onAppear {
            isAmountFocused = true
        }
        // Prevent the standard navigation bar from ruining the full screen glass effect
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // Computed validation
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (Double(amountText) ?? 0) > 0
    }
    
    private func saveTransaction() {
        guard let amount = Double(amountText) else { return }
        
        // Successful save haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let transaction = Transaction(
            title: title,
            amount: amount,
            date: date,
            isIncome: isIncome,
            categorySymbol: selectedCategory?.symbol ?? "fork.knife"
        )
        
        modelContext.insert(transaction)
        dismiss()
    }
}

// MARK: - Subcomponentes Locales

// Expense / Income Button
struct SegmentButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(UIColor.systemBackground) : Color.clear, in: Capsule())
                .shadow(color: isSelected ? .black.opacity(0.1) : .clear, radius: 2, y: 1)
        }
    }
}

// Circular category icon
struct CategoryPill: View {
    var category: Category
    var isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isSelected ? category.color : category.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: category.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : category.color)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0) // Small "pop" when selected
            
            Text(category.localizedName)
                .font(.caption2.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self], inMemory: true)
        .environmentObject(SettingsManager.shared)
}
