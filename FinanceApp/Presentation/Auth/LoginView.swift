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
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)
                            
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(color: (isSignUp ? Color.orange : Color.blue).opacity(0.4), radius: 15)
                        }
                        
                        Text("MyFinance")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white)
                        
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
                            Text(settingsManager.localizedString(for: isSignUp ? "Crear Cuenta" : "Welcome Back"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Text(settingsManager.localizedString(for: isSignUp ? "Únete para gestionar mejor tus finanzas" : "Inicia sesión para continuar"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        VStack(spacing: 16) {
                            customTextField(
                                icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $email,
                                isFocused: focusedField == .email
                            )
                            .onTapGesture { focusedField = .email }
                            
                            customSecureField(
                                icon: "lock.fill",
                                placeholder: "Password",
                                text: $password,
                                isFocused: focusedField == .password
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
                        Button {
                            hideKeyboard()
                            submitAction()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(settingsManager.localizedString(for: isSignUp ? "Registrarse" : "Sign In"))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isSignUp ? [.orange, .red] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: (isSignUp ? Color.red : Color.purple).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(viewModel.isLoading)
                        
                        // --- SOCIAL LOGIN ---
                        VStack(spacing: 20) {
                            HStack {
                                Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
                                Text(settingsManager.localizedString(for: "O continúa con"))
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
    
    @ViewBuilder
    private func customTextField(icon: String, placeholder: String, text: Binding<String>, isFocused: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .orange : .white.opacity(0.4))
                .font(.system(size: 20))
                .frame(width: 24)
            
            TextField("", text: text, prompt: Text(settingsManager.localizedString(for: placeholder)).foregroundStyle(.white.opacity(0.3)))
                .foregroundStyle(.white)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isFocused ? .white.opacity(0.12) : .white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? .orange.opacity(0.5) : .clear, lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func customSecureField(icon: String, placeholder: String, text: Binding<String>, isFocused: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? .orange : .white.opacity(0.4))
                .font(.system(size: 20))
                .frame(width: 24)
            
            SecureField("", text: text, prompt: Text(settingsManager.localizedString(for: placeholder)).foregroundStyle(.white.opacity(0.3)))
                .foregroundStyle(.white)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(isSignUp ? .join : .go)
                .onSubmit { submitAction() }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isFocused ? .white.opacity(0.12) : .white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isFocused ? .orange.opacity(0.5) : .clear, lineWidth: 1)
        )
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
