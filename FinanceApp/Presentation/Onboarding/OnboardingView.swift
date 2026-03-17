import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var currentPage = 0
    
    // Form States
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var age = 25
    @State private var selectedGoals: Set<String> = []
    
    enum OnboardingField {
        case firstName, lastName
    }
    @FocusState private var focusedField: OnboardingField?
    
    let goals = [
        ("Ahorrar", "leaf.fill", Color.green),
        ("Invertir", "chart.line.uptrend.xyaxis", Color.blue),
        ("Reducir Deuda", "creditcard.fill", Color.red),
        ("Presupuestar", "list.bullet.rectangle.fill", Color.orange),
        ("Libertad Financiera", "star.fill", Color.yellow)
    ]
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color.black, Color(white: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .onTapGesture { focusedField = nil }
            
            VStack {
                // Progress Header
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.orange : Color.white.opacity(0.2))
                            .frame(height: 4)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                TabView(selection: $currentPage) {
                    welcomeStep.tag(0)
                    ageStep.tag(1)
                    goalsStep.tag(2)
                    summaryStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Navigation
                HStack {
                    if currentPage > 0 {
                        Button("Atrás") {
                            withAnimation { currentPage -= 1 }
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentPage < 3 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Continuar")
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(Color.orange))
                        }
                        .disabled(currentPage == 0 && (firstName.isEmpty || lastName.isEmpty))
                        .opacity(currentPage == 0 && (firstName.isEmpty || lastName.isEmpty) ? 0.5 : 1)
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Empezar")
                                .fontWeight(.bold)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .padding(.top, 40)
            
            VStack(spacing: 10) {
                Text("¡Bienvenido!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Cuentanos un poco sobre ti para personalizar tu experiencia.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                CustomTextField(
                    placeholder: "Nombre",
                    text: $firstName,
                    isFocused: focusedField == .firstName
                )
                .focused($focusedField, equals: .firstName)
                .submitLabel(.next)
                .onSubmit { focusedField = .lastName }
                .onTapGesture { focusedField = .firstName }
                
                CustomTextField(
                    placeholder: "Apellidos",
                    text: $lastName,
                    isFocused: focusedField == .lastName
                )
                .focused($focusedField, equals: .lastName)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .onTapGesture { focusedField = .lastName }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
    
    private var ageStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .padding(.top, 40)
            
            VStack(spacing: 10) {
                Text("¿Qué edad tienes?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Picker("Edad", selection: $age) {
                ForEach(18...100, id: \.self) { num in
                    Text("\(num)")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .tag(num)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var goalsStep: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Tus Objetivos")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Selecciona los que más te interesen.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goals, id: \.0) { goal in
                        GoalRow(
                            title: goal.0,
                            icon: goal.1,
                            color: goal.2,
                            isSelected: selectedGoals.contains(goal.0)
                        ) {
                            if selectedGoals.contains(goal.0) {
                                selectedGoals.remove(goal.0)
                            } else {
                                selectedGoals.insert(goal.0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
    }
    
    private var summaryStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green)
                .padding(.top, 60)
            
            VStack(spacing: 15) {
                Text("¡Todo listo, \(firstName)!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("Estamos preparando tu tablero financiero personalizado.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Components
    
    private func completeOnboarding() {
        settingsManager.userName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        settingsManager.userAge = age
        settingsManager.financialGoals = Array(selectedGoals)
        withAnimation {
            settingsManager.hasCompletedOnboarding = true
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false
    
    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder).foregroundStyle(.white.opacity(0.3))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.1)))
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isFocused ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
            )
    }
}

private extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct GoalRow: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundStyle(.white)
                    .fontWeight(isSelected ? .bold : .regular)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsManager.shared)
}
