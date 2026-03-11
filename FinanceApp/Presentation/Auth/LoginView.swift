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
    
    var body: some View {
        // GEOMETRY READER: Congela las dimensiones de la pantalla
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // --- HEADER ---
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .orange.opacity(0.5), radius: 15)
                            .drawingGroup()
                        
                        Text("MyFinance")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.bottom, 40)
                    
                    // --- FORMULARIO ---
                    VStack(spacing: 20) {
                        Text(settingsManager.localizedString(for: isSignUp ? "Create Account" : "Welcome Back"))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 16) {
                            // CAMPO EMAIL
                            HStack(spacing: 16) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(focusedField == .email ? Color.orange : Color.white.opacity(0.5))
                                    .frame(width: 24)
                                
                                TextField("", text: $email, prompt: Text(settingsManager.localizedString(for: "Email Address")).foregroundStyle(Color.white.opacity(0.4)))
                                    .foregroundStyle(Color.white)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.username)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .submitLabel(.next)
                                    .focused($focusedField, equals: .email)
                            }
                            .padding(.horizontal, 20).frame(height: 60)
                            .contentShape(Rectangle())
                            .onTapGesture { focusedField = .email }
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(focusedField == .email ? 0.12 : 0.05)))
                            
                            // CAMPO PASSWORD
                            HStack(spacing: 16) {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(focusedField == .password ? Color.orange : Color.white.opacity(0.5))
                                    .frame(width: 24)
                                
                                SecureField("", text: $password, prompt: Text(settingsManager.localizedString(for: "Password")).foregroundStyle(Color.white.opacity(0.4)))
                                    .foregroundStyle(Color.white)
                                    .textContentType(.password)
                                    .submitLabel(.done)
                                    .focused($focusedField, equals: .password)
                            }
                            .padding(.horizontal, 20).frame(height: 60)
                            .contentShape(Rectangle())
                            .onTapGesture { focusedField = .password }
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(focusedField == .password ? 0.12 : 0.05)))
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.9))
                                .padding(.vertical, 4)
                        }
                        
                        // BOTÓN
                        Button {
                            focusedField = nil
                            submitAction()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(Color.white)
                                } else {
                                    Text(settingsManager.localizedString(for: isSignUp ? "Sign Up" : "Sign In")).font(.headline).fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.top, 8)
                        
                        // TOGGLE
                        Button {
                            withAnimation(.spring()) {
                                isSignUp.toggle()
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(settingsManager.localizedString(for: isSignUp ? "Already have an account?" : "Don't have an account?"))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Text(settingsManager.localizedString(for: isSignUp ? "Sign In" : "Sign Up"))
                                    .fontWeight(.bold).foregroundStyle(Color.orange)
                            }
                            .font(.footnote)
                        }
                        .padding(.top, 4)
                    }
                    .padding(28)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .padding(.horizontal, 24)
                }
                // Usamos el GeometryReader para empujarlo dinámicamente un 10% hacia abajo
                .padding(.top, proxy.size.height * 0.10)
                // Congelamos el frame exacto de la pantalla
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            }
        }
        // Este modificador ahora trabaja en conjunto con GeometryReader de manera perfecta
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { focusedField = nil }
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
