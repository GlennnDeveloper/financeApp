import SwiftUI
import Auth

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
        ("Save", "leaf.fill", Color.green),
        ("Invest", "chart.line.uptrend.xyaxis", Color.blue),
        ("Reduce Debt", "creditcard.fill", Color.red),
        ("Budget", "list.bullet.rectangle.fill", Color.orange),
        ("Financial Freedom", "star.fill", Color.yellow)
    ]
    
    @State private var slideDirection: Edge = .trailing
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.orange, .yellow, .red])
                .onTapGesture { focusedField = nil }
            
            VStack(spacing: 0) {
                // Progress Header
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.orange : Color.white.opacity(0.2))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .animation(.spring(), value: currentPage)
                
                // Content Step with Custom Transitions
                ZStack {
                    Group {
                        if currentPage == 0 {
                            welcomeStep
                        } else if currentPage == 1 {
                            ageStep
                        } else if currentPage == 2 {
                            goalsStep
                        } else if currentPage == 3 {
                            securityStep
                        } else if currentPage == 4 {
                            summaryStep
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: slideDirection),
                        removal: .move(edge: slideDirection == .trailing ? .leading : .trailing)
                    ))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.keyboard)
                
                // Bottom Navigation
                HStack {
                    if currentPage > 0 {
                        Button(settingsManager.localizedString(for: "Back")) {
                            slideDirection = .leading
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        }
                        .foregroundStyle(.white.opacity(0.6))
                        .padding()
                    }
                    
                    Spacer()
                    
                    if currentPage < 4 {
                        Button {
                            // Clear focus
                            focusedField = nil
                            
                            // Set direction and animate
                            slideDirection = .trailing
                            // Small delay to let keyboard dismiss if needed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            }
                        } label: {
                            Text(settingsManager.localizedString(for: "Continue"))
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
                            Text(settingsManager.localizedString(for: "Get Started"))
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
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .padding(.top, 40)
            
            VStack(spacing: 10) {
                Text(settingsManager.localizedString(for: "Welcome!"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(settingsManager.localizedString(for: "Tell us a bit about yourself to personalize your experience."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                CustomTextField(
                    placeholder: settingsManager.localizedString(for: "First Name"),
                    text: $firstName,
                    isFocused: focusedField == .firstName
                )
                .focused($focusedField, equals: .firstName)
                .submitLabel(.next)
                .onSubmit { focusedField = .lastName }
                .onTapGesture { focusedField = .firstName }
                
                CustomTextField(
                    placeholder: settingsManager.localizedString(for: "Last Name"),
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
                Text(settingsManager.localizedString(for: "How old are you?"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Picker(settingsManager.localizedString(for: "Age"), selection: $age) {
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
                Text(settingsManager.localizedString(for: "Your Goals"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(settingsManager.localizedString(for: "Select the ones that interest you most."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(goals, id: \.0) { goal in
                        GoalRow(
                            title: settingsManager.localizedString(for: goal.0),
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
    
    private var securityStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "faceid")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .padding(.top, 40)
            
            VStack(spacing: 12) {
                Text(settingsManager.localizedString(for: "Security"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(settingsManager.localizedString(for: "Protect your data with Face ID so only you can access your financial information."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                Toggle(isOn: $settingsManager.useBiometrics) {
                    HStack(spacing: 15) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading) {
                            Text(settingsManager.localizedString(for: "Enable Face ID"))
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text(settingsManager.localizedString(for: "Fast and secure access"))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.08)))
                .tint(.orange)
            }
            .padding(.horizontal, 30)
            
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
                Text("\(settingsManager.localizedString(for: "All Set")), \(firstName)!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(settingsManager.localizedString(for: "We are preparing your personalized financial dashboard."))
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
        
        // Sync profile to Supabase for future use
        Task {
            if let user = await SupabaseManager.shared.getCurrentUser() {
                let profile = RemoteProfile(
                    id: user.id,
                    firstName: firstName,
                    lastName: lastName,
                    age: age,
                    financialGoals: Array(selectedGoals)
                )
                try? await SupabaseManager.shared.upsertProfile(profile)
            }
        }
        
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
