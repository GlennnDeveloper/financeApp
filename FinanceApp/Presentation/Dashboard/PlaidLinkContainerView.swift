import SwiftUI
import Auth
import SwiftData

struct PlaidLinkContainerView: View {
    @ObservedObject var bankViewModel: BankConnectionViewModel
    let authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        if let token = bankViewModel.linkToken {
            PlaidLinkView(linkToken: token) { publicToken, metadata in
                Task { if let session = authViewModel.session { await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session) } }
            } onExit: { error in bankViewModel.handleError(error ?? NSError(domain: "Plaid", code: -1)) }
        } else {
            PlaidLinkView(linkToken: "mock-token") { publicToken, metadata in
                Task { if let session = authViewModel.session { await bankViewModel.handleSuccess(publicToken: publicToken, metadata: metadata, context: modelContext, session: session) } }
            } onExit: { _ in }
        }
    }
}
