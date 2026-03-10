//
//  FinanceAppApp.swift
//  FinanceApp
//
//  Created by Adrian Sanchez on 3/8/26.
//

import SwiftUI
import SwiftData

@main
struct FinanceAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var initManager = AppInitializationManager()
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if initManager.isInitialized, let container = initManager.modelContainer {
                    Group {
                        if authViewModel.session != nil {
                            MainTabView()
                                .environmentObject(authViewModel)
                        } else {
                            LoginView()
                                .environmentObject(authViewModel)
                        }
                    }
                    .modelContainer(container) // Use the background-initialized container
                    .environmentObject(settingsManager)
                    .environment(\.locale, settingsManager.locale)
                    .preferredColorScheme(settingsManager.appTheme.colorScheme)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else {
                    // Ultra-lightweight Splash Screen
                    VStack(spacing: 20) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        ProgressView()
                            .tint(.white.opacity(0.5))
                    }
                }
            }
            .task {
                // We DON'T await these together because startListening() is an infinite loop 
                // that would block the rest of the app from ever finishing the task.
                // We fire them independently.
                
                Task {
                    await initManager.initialize()
                }
                
                Task {
                    await authViewModel.startListening()
                }
            }
        }
    }
}
