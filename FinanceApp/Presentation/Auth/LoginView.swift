import SwiftUI

enum FocusField {
    case email
    case password
}

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    @FocusState private var focusedField: FocusField?
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // --- DYNAMIC BACKGROUND ---
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    // Floating blobs for depth
                    Circle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.4), .red.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: animate ? 100 : -100, y: animate ? -150 : 150)
                    
                    Circle()
                        .fill(LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: animate ? -120 : 120, y: animate ? 200 : -100)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
                
                VStack(spacing: 0) {
                    // --- HEADER / BRANDING ---
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .blur(radius: 10)
                            
                            Image(systemName: "chart.pie.fill") // A more finance-related icon
                                .font(.system(size: 50))
                                .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .orange.opacity(0.5), radius: 20)
                        }
                        
                        Text("Glennn Finance")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // --- FORM WITH GLASSMORPHISM ---
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settingsManager.localizedString(for: isSignUp ? "Create Account" : "Welcome Back"))
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            
                            Text(settingsManager.localizedString(for: isSignUp ? "Join us to manage your finances better" : "Please sign in to continue"))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            // EMAIL FIELD
                            customTextField(
                                icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $email,
                                isFocused: focusedField == .email
                            )
                            .onTapGesture { focusedField = .email }
                            
                            // PASSWORD FIELD
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
                        
                        // PRIMARY ACTION BUTTON
                        Button {
                            focusedField = nil
                            submitAction()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(settingsManager.localizedString(for: isSignUp ? "Sign Up" : "Sign In"))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.isLoading)
                        
                        // TOGGLE LOGIN/SIGNUP
                        Button {
                            // Simple haptic feedback could be added here
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSignUp.toggle()
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsManager.localizedString(for: isSignUp ? "Already have an account?" : "Don't have an account?"))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(settingsManager.localizedString(for: isSignUp ? "Sign In" : "Sign Up"))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(30)
                    .background {
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .fill(.white.opacity(0.08))
                            .background(
                                BlurView(style: .systemThinMaterialDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 35, style: .continuous)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                }
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color.black)
        .onTapGesture { focusedField = nil }
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

// Support for Glassmorphism
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
