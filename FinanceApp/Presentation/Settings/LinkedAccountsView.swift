import SwiftUI
import SwiftData

struct LinkedAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var bankVM = BankConnectionViewModel()
    @Query private var accounts: [Account]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(SettingsManager.shared.localizedString(for: "Connection Status"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.gray)
                        .padding(.horizontal)
                    
                    HStack {
                        Circle()
                            .fill(bankVM.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(bankVM.isConnected ? SettingsManager.shared.localizedString(for: "Connected to Plaid") : SettingsManager.shared.localizedString(for: "Not Connected"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if bankVM.isConnected {
                            Button(SettingsManager.shared.localizedString(for: "Disconnect")) {
                                bankVM.disconnectBank(context: modelContext)
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }
                
                // Accounts List
                if bankVM.isConnected && !accounts.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(SettingsManager.shared.localizedString(for: "Linked Accounts"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.gray)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            ForEach(accounts) { account in
                                HStack(spacing: 14) {
                                    Image(systemName: account.symbol)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .frame(width: 36, height: 36)
                                        .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text("$\(Int(account.balance))")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if account.id != accounts.last?.id {
                                    Divider().padding(.horizontal)
                                }
                            }
                        }
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                    }
                }
                
                // Add Connection
                if !bankVM.isConnected {
                    VStack(spacing: 16) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray.opacity(0.3))
                        
                        Text(SettingsManager.shared.localizedString(for: "Link your bank accounts"))
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text(SettingsManager.shared.localizedString(for: "Connect your bank securely via Plaid to automatically sync your transactions and balances."))
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            if let session = authViewModel.session {
                                Task {
                                    await bankVM.preparePlaidLink(session: session)
                                }
                            }
                        } label: {
                            if bankVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(SettingsManager.shared.localizedString(for: "Connect with Plaid"))
                                    .font(.subheadline.weight(.bold))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(SettingsManager.shared.localizedString(for: "Linked Accounts"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $bankVM.isLinkActive) {
            if let token = bankVM.linkToken {
                PlaidLinkView(linkToken: token) { publicToken, metadata in
                    if let session = authViewModel.session {
                        Task {
                            await bankVM.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session)
                        }
                    }
                } onExit: { _ in
                    bankVM.isLinkActive = false
                }
            }
        }
        .alert(SettingsManager.shared.localizedString(for: "Error"), isPresented: Binding(
            get: { bankVM.errorMessage != nil },
            set: { if !$0 { bankVM.errorMessage = nil } }
        )) {
            Button(SettingsManager.shared.localizedString(for: "OK"), role: .cancel) { }
        } message: {
            if let error = bankVM.errorMessage {
                Text(error)
            }
        }
    }
}

#Preview {
    NavigationStack {
        LinkedAccountsView()
            .environmentObject(AuthViewModel())
            .modelContainer(for: [Account.self], inMemory: true)
    }
}
