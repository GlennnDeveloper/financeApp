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
    @State private var isSignUp: Bool
    
    init(initialIsSignUp: Bool = false) {
        _isSignUp = State(initialValue: initialIsSignUp)
    }
    
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
                        .fill(isSignUp ? 
                              LinearGradient(colors: [.orange.opacity(0.4), .red.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: animate ? 100 : -100, y: animate ? -150 : 150)
                    
                    Circle()
                        .fill(isSignUp ?
                              LinearGradient(colors: [.yellow.opacity(0.2), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(colors: [.cyan.opacity(0.2), .indigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
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
                                .frame(width: 110, height: 110)
                                .blur(radius: 10)
                            
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .shadow(color: (isSignUp ? Color.orange : Color.blue).opacity(0.4), radius: 15)
                        }
                        
                        Text("MyFinance")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    .overlay(alignment: .topLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(12)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                    }
                    
                    // --- FORM WITH GLASSMORPHISM ---
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(settingsManager.localizedString(for: isSignUp ? "Crear Cuenta" : "Bienvenido"))
                                .font(.title.bold())
                                .foregroundStyle(.white)
                            
                            Text(settingsManager.localizedString(for: isSignUp ? "Únete para gestionar mejor tus finanzas" : "Inicia sesión para continuar"))
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
                                    Text(settingsManager.localizedString(for: isSignUp ? "Registrarse" : "Entrar"))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: isSignUp ? [.orange, .red] : [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: (isSignUp ? Color.red : Color.purple).opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(viewModel.isLoading)
                        
                        // TOGGLE LOGIN/SIGNUP
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                isSignUp.toggle()
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsManager.localizedString(for: isSignUp ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?"))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text(settingsManager.localizedString(for: isSignUp ? "Inicia sesión ahora" : "Regístrate ahora"))
                                    .fontWeight(.bold)
                                    .foregroundStyle(isSignUp ? .orange : .cyan)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(settingsManager.localizedString(for: "Hecho")) {
                    focusedField = nil
                }
                .fontWeight(.bold)
                .foregroundStyle(.orange)
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

// Support for Glassmorphism
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
