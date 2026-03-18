//
//  FinanceAppApp.swift
//  FinanceApp
//
//  Created by Adrian Sanchez on 3/8/26.
//  Updated by Antigravity on 3/17/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var initManager = AppInitializationManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                let needsBiometric = settingsManager.isLoggedIn && settingsManager.useBiometrics && settingsManager.hasCompletedOnboarding
                let isUnlocked = !needsBiometric || initManager.isUnlocked
                
                // Show content if:
                // 1. App is initialized AND (is unlocked OR doesn't need biometric)
                // 2. OR if the user is NOT logged in and the app is still initializing (to skip splash for guest users)
                let shouldShowContent = (initManager.isInitialized && isUnlocked) || (!settingsManager.isLoggedIn && !initManager.isInitialized)
                
                if shouldShowContent {
                    Group {
                        if authViewModel.session != nil {
                            if !settingsManager.hasCompletedOnboarding {
                                OnboardingView()
                                    .environmentObject(authViewModel)
                            } else {
                                MainTabView()
                                    .environmentObject(authViewModel)
                            }
                        } else {
                            LandingView()
                                .environmentObject(authViewModel)
                        }
                    }
                    .modelContainer(initManager.modelContainer ?? (try! ModelContainer(for: Schema([Transaction.self, Account.self, Budget.self, Rule.self, Category.self]), configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])))
                    .environmentObject(settingsManager)
                    .environment(\.locale, settingsManager.locale)
                    .preferredColorScheme(settingsManager.appTheme.colorScheme)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else {
                    // Premium Splash Screen
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // BRANDING GROUP (ALWAYS CENTERED)
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(Color.orange.opacity(0.15))
                                        .frame(width: 140, height: 140)
                                        .blur(radius: 20)
                                    
                                    Image("AppLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: Color.orange.opacity(0.3), radius: 20)
                                }
                                
                                VStack(spacing: 8) {
                                    Text("MyFinance")
                                        .font(.system(size: 36, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Text("Toma el control de tu futuro financiero hoy mismo")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // ACTION GROUP (POSITIONED RELATIVE TO BOTTOM)
                        VStack {
                            Spacer()
                            if initManager.authFailed && settingsManager.useBiometrics {
                                Button {
                                    Task {
                                        await initManager.performAuthentication()
                                    }
                                } label: {
                                    Text("Desbloquear")
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 40)
                                        .padding(.vertical, 14)
                                        .background(Capsule().fill(Color.orange))
                                }
                                .padding(.bottom, 60)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(), value: initManager.authFailed)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }
            }
            .onOpenURL { url in
                // Handle Plaid OAuth redirect
            }
            .task {
                // Initialize things in parallel. 
                // We fire them independently.
                
                Task {
                    await authViewModel.checkSession()
                    await initManager.initialize()
                    
                    // Only prompt if we have a session on startup
                    if authViewModel.session != nil && settingsManager.useBiometrics {
                        await initManager.performAuthentication()
                    }
                }
                
                Task {
                    await authViewModel.startListening()
                }
            }
        }
    }
}
