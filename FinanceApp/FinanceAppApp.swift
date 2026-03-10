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
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.session != nil {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .task {
                await authViewModel.startListening()
            }
        }
        .modelContainer(for: [Transaction.self, Account.self])
    }
}
