import SwiftUI

struct LandingView: View {
    @State private var showAuth = false
    @State private var isSignUp = false
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        ZStack {
            PremiumBackground(colors: [.orange, .red, .purple, .blue])
            
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
                    
                    Text(settingsManager.localizedString(for: "MyFinance"))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(settingsManager.localizedString(for: "Take control of your financial future today."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)
                }
                .opacity(showAuth ? 0 : 1)
                .scaleEffect(showAuth ? 0.9 : 1)
                .blur(radius: showAuth ? 10 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAuth)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    AppButton(
                        title: settingsManager.localizedString(for: "Start Now"),
                        style: .custom(colors: [.orange, .red])
                    ) {
                        isSignUp = true
                        showAuth = true
                    }
                    
                    AppButton(
                        title: settingsManager.localizedString(for: "I already have an account"),
                        style: .secondary
                    ) {
                        isSignUp = false
                        showAuth = true
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
