import SwiftUI
import Auth
import SwiftData

struct BankAccountsSection: View {
    let accounts: [Account]
    @ObservedObject var bankViewModel: BankConnectionViewModel
    let authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        if bankViewModel.isConnected {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(settingsManager.localizedString(for: "Bank Accounts"))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if bankViewModel.isLoading {
                        ProgressView().tint(.blue)
                    } else {
                        HStack(spacing: 8) {
                            Button {
                                Task { await bankViewModel.syncRemoteData(context: modelContext) }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(6)
                                    .background(.blue.opacity(0.15), in: Circle())
                            }
                            Button {
                                Task { if let session = authViewModel.session { await bankViewModel.preparePlaidLink(session: session) } }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(6)
                                    .background(.blue.opacity(0.15), in: Circle())
                            }
                            Button { bankViewModel.disconnectBank(context: modelContext) } label: {
                                Text(settingsManager.localizedString(for: "Disconnect")).font(.caption.bold()).foregroundStyle(.red).padding(.horizontal, 12).padding(.vertical, 6).background(.red.opacity(0.15), in: Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal)
                ForEach(accounts) { account in
                    HStack {
                        Image(systemName: account.symbol).font(.title3).foregroundStyle(.blue).frame(width: 32)
                        Text(account.name).foregroundStyle(.primary)
                        Spacer()
                        Text(account.balance, format: .currency(code: "USD")).foregroundStyle(.primary.opacity(0.7))
                    }.padding().background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                }
            }
        } else {
            Button {
                Task {
                    if let session = authViewModel.session { await bankViewModel.preparePlaidLink(session: session) }
                    else { bankViewModel.errorMessage = "Session expired." }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "building.columns.fill").font(.title2).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(settingsManager.localizedString(for: "Connect Your Bank")).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        Text(settingsManager.localizedString(for: "Link an account to see balances")).font(.caption).foregroundStyle(.gray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.gray.opacity(0.5))
                }.padding(16).background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }.buttonStyle(.plain).padding(.horizontal)
        }
    }
}
