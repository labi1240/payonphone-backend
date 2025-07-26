import SwiftUI
import StripeTerminal

@main
struct PayOnPhoneApp: App {
    
    init() {
        // Initialize Stripe Terminal
        Terminal.setTokenProvider(APIClient.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}