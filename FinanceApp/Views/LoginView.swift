import SwiftUI

enum FocusField {
    case email
    case password
}

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var isSignUp = false
    @FocusState private var focusedField: FocusField?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Spacer for top padding to keep form centered when keyboard is down
                Spacer()
                    .frame(height: 80)
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.5), radius: 15, x: 0, y: 5)
                    
                    Text("Antigravity Finance")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                }
                .padding(.bottom, 40)
                
                // Extracted to isolate state changes and avoid full view redraws
                LoginFormView(
                    viewModel: viewModel,
                    isSignUp: $isSignUp,
                    focusedField: $focusedField
                )
                
                Spacer()
                    .frame(height: 100) // Bottom padding for scroll area
            }
            .containerRelativeFrame(.vertical, alignment: .center) // Replaces UIScreen.main.bounds.height
        }
        .background(
            // Option 1: Static Image background (if available in assets)
            // Option 2: Solid fallback optimized for 0ms initial render
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Static Fallback Geometry
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 350, height: 350)
                    .offset(x: 150, y: 250)
                    
                // If "background_static" is in assets, it will overlay instantly here
                Image("background_static")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            }
            .drawingGroup() // Flattens strictly the static background into an instant GPU bitmap
        )
        // Dismiss keyboard when tapping outside
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Isolated Form View to prevent Parent Redraws
struct LoginFormView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Binding var isSignUp: Bool
    var focusedField: FocusState<FocusField?>.Binding
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Create Account" : "Welcome Back")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                CustomTextField(
                    placeholder: "Email Address",
                    text: $viewModel.email,
                    icon: "envelope.fill",
                    isSecure: false,
                    keyboardType: .emailAddress,
                    isFocused: focusedField.wrappedValue == .email
                )
                .focused(focusedField, equals: .email)
                .onSubmit {
                    focusedField.wrappedValue = .password
                }
                
                CustomTextField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    icon: "lock.fill",
                    isSecure: true,
                    keyboardType: .default,
                    isFocused: focusedField.wrappedValue == .password
                )
                .focused(focusedField, equals: .password)
                .onSubmit {
                    focusedField.wrappedValue = nil
                    Task {
                        if isSignUp { await viewModel.signUp() }
                        else { await viewModel.signIn() }
                    }
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.vertical, 4)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            
            // Main Action Button
            Button {
                focusedField.wrappedValue = nil // Hide keyboard
                Task {
                    if isSignUp {
                        await viewModel.signUp()
                    } else {
                        await viewModel.signIn()
                    }
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .disabled(viewModel.isLoading)
            .padding(.top, 8)
            
            // Toggle Mode Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSignUp.toggle()
                    viewModel.errorMessage = nil
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundStyle(.white.opacity(0.7))
                    Text(isSignUp ? "Sign In" : "Sign Up")
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
                .font(.footnote)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.4), .black.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // NO drawingGroup here!
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1) // Slightly darker border
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Custom Input Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var isFocused: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isFocused ? .orange : .white.opacity(0.5))
                .frame(width: 24)
                .animation(.easeInOut, value: isFocused)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)))
                    .foregroundStyle(.white)
                    .textContentType(.password)
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.4)))
                    .foregroundStyle(.white)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
                    .textContentType(keyboardType == .emailAddress ? .emailAddress : nil)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(isFocused ? 0.1 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFocused ? Color.orange.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
