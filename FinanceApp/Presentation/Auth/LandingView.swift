import SwiftUI

struct LandingView: View {
    @State private var showAuth = false
    @State private var isSignUp = false
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        ZStack {
            // Background with animated blobs (reusing style from LoginView)
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Branding
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.orange.opacity(0.1))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .shadow(color: .orange.opacity(0.3), radius: 15)
                    }
                    
                    Text("MyFinance")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Toma el control de tu futuro financiero hoy mismo.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        isSignUp = true
                        showAuth = true
                    } label: {
                        Text("Empezar ahora")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    Button {
                        isSignUp = false
                        showAuth = true
                    } label: {
                        Text("Ya tengo una cuenta")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .fullScreenCover(isPresented: $showAuth) {
            LoginView(initialIsSignUp: isSignUp)
                .id(isSignUp)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(SettingsManager.shared)
}
