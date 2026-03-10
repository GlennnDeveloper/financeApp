import SwiftUI
import LinkKit

struct PlaidLinkView: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String, Any) -> Void
    let onExit: (Error?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        var linkConfiguration = LinkTokenConfiguration(token: linkToken) { linkSuccess in
            onSuccess(linkSuccess.publicToken, linkSuccess.metadata)
        }
        
        linkConfiguration.onExit = { linkExit in
            onExit(linkExit.error)
        }
        
        let result = Plaid.create(linkConfiguration)
        switch result {
        case .failure(let error):
            onExit(error)
        case .success(let handler):
            // MUY IMPORTANTE: El Handler debe vivir tanto tiempo como la sesión de Link
            context.coordinator.handler = handler
            
            DispatchQueue.main.async {
                handler.open(presentUsing: .viewController(viewController))
            }
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class Coordinator: NSObject {
        var handler: Handler?
        
        init(_ parent: PlaidLinkView) {
            // No necesitamos guardar el parent si no lo usamos
        }
    }
}
