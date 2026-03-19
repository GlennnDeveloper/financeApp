import SwiftUI

enum FocusField {
    case email
    case password
}

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @Binding var isSignUp: Bool
    
    init(isSignUp: Binding<Bool>) {
        self._isSignUp = isSignUp
    }
    
    @FocusState private var focusedField: FocusField?
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                // Background
                PremiumBackground(colors: isSignUp ? [.orange, .red, .yellow] : [.blue, .purple, .cyan])
                
                VStack(spacing: 0) {
                    // --- TOP BRANDING AREA ---
                    VStack(spacing: 16) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .blur(radius: 10)
                            
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .shadow(color: (isSignUp ? Color.orange : Color.blue).opacity(0.4), radius: 15)
                        }
                        
                        Spacer()
                    }
                    .frame(height: proxy.size.height * 0.35)
                    
                    // --- BOTTOM FORM CARD ---
                    VStack(spacing: 24) {
                        // Handle for visual appeal (optional, but looks premium)
                        Capsule()
                            .fill(.white.opacity(0.15))
                            .frame(width: 40, height: 4)
                            .padding(.top, 12)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settingsManager.localizedString(for: isSignUp ? "Create Account" : "Welcome Back"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text(settingsManager.localizedString(for: isSignUp ? "Join to better manage your finances" : "Sign in to continue"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        VStack(spacing: 16) {
                            AppTextField(
                                icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $email,
                                isFocused: focusedField == .email,
                                keyboardType: .emailAddress,
                                textContentType: .username,
                                onSubmit: { focusedField = .password }
                            )
                            .onTapGesture { focusedField = .email }
                            
                            AppTextField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isSecure: true,
                                isFocused: focusedField == .password,
                                textContentType: .password,
                                onSubmit: { submitAction() }
                            )
                            .onTapGesture { focusedField = .password }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                                .padding(.horizontal, 4)
                        }
                        
                        // PRIMARY ACTION
                        AppButton(
                            title: settingsManager.localizedString(for: isSignUp ? "Registrarse" : "Sign In"),
                            style: isSignUp ? .custom(colors: [.orange, .red]) : .primary,
                            isLoading: viewModel.isLoading
                        ) {
                            hideKeyboard()
                            submitAction()
                        }
                        
                        // --- SOCIAL LOGIN ---
                        VStack(spacing: 20) {
                            HStack {
                                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                                Text(settingsManager.localizedString(for: "Or continue with"))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.horizontal, 8)
                                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                            }
                            
                            HStack(spacing: 20) {
                                socialButton(icon: "google_icon_placeholder", isSystem: false)
                                socialButton(icon: "apple.logo", isSystem: true)
                                socialButton(icon: "facebook_icon_placeholder", isSystem: false)
                            }
                        }
                        
                        // TOGGLE
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSignUp.toggle()
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsManager.localizedString(for: isSignUp ? "Already have an account?" : "Don't have an account?"))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(settingsManager.localizedString(for: isSignUp ? "Sign In" : "Sign Up"))
                                    .fontWeight(.bold)
                                    .foregroundStyle(isSignUp ? .orange : .cyan)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .frame(maxWidth: .infinity)
                    .background {
                        CustomCorners(corners: [.topLeft, .topRight], radius: 40)
                            .fill(.white.opacity(0.08))
                            .background(
                                BlurView(style: .systemThinMaterialDark)
                                    .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 40))
                            )
                            .overlay(
                                CustomCorners(corners: [.topLeft, .topRight], radius: 40)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture { hideKeyboard() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(settingsManager.localizedString(for: "Done")) {
                    hideKeyboard()
                }
                .fontWeight(.bold)
                .foregroundStyle(.orange)
            }
        }
    }
    
    @ViewBuilder
    private func socialButton(icon: String, isSystem: Bool) -> some View {
        Button {} label: {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                
                if isSystem {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                } else {
                    // Placeholder for brand icons
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
    }
    

    
    private func submitAction() {
        Task {
            if isSignUp {
                await viewModel.signUp(email: email, password: password)
            } else {
                await viewModel.signIn(email: email, password: password)
            }
        }
    }
}

// Helper for custom corners
struct CustomCorners: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
