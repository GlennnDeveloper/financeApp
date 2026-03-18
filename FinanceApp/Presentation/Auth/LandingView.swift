import SwiftUI

struct LandingView: View {
    @State private var showAuth = false
    @State private var isSignUp = false
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.orange, .red, .yellow])
            
            VStack(spacing: 40) {
                Spacer()
                
                // Branding
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.4), radius: 20)
                    
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
        .sheet(isPresented: $showAuth) {
            LoginView(isSignUp: $isSignUp)
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(SettingsManager.shared)
}
