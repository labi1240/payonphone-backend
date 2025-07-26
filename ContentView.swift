import SwiftUI
import StripeTerminal

struct ContentView: View {
    @StateObject private var terminalManager = TerminalManager.shared
    @State private var paymentAmount = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("PayOnPhone POS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                // Connection Status
                ConnectionStatusView()
                
                // Reader Discovery/Connection
                if terminalManager.connectionStatus == .notConnected {
                    ReaderDiscoveryView()
                } else {
                    ConnectedReaderView()
                }
                
                // Payment Section
                if terminalManager.connectionStatus == .connected {
                    PaymentView(paymentAmount: $paymentAmount)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .environmentObject(terminalManager)
        .alert("Payment Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var terminalManager: TerminalManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.headline)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var statusColor: Color {
        switch terminalManager.connectionStatus {
        case .notConnected:
            return .red
        case .connecting:
            return .orange
        case .connected:
            return .green
        }
    }
    
    private var statusText: String {
        switch terminalManager.connectionStatus {
        case .notConnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected to \(terminalManager.connectedReader?.label ?? "Reader")"
        }
    }
}

struct ReaderDiscoveryView: View {
    @EnvironmentObject var terminalManager: TerminalManager
    
    var body: some View {
        VStack {
            Button(action: {
                terminalManager.discoverReaders()
            }) {
                HStack {
                    if terminalManager.isDiscovering {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(terminalManager.isDiscovering ? "Discovering..." : "Discover Readers")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(terminalManager.isDiscovering)
            
            if !terminalManager.discoveredReaders.isEmpty {
                Text("Found Readers:")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(terminalManager.discoveredReaders, id: \.stripeId) { reader in
                    Button(action: {
                        terminalManager.connectToReader(reader)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(reader.label ?? "Unknown Reader")
                                    .font(.headline)
                                Text(reader.serialNumber)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

struct ConnectedReaderView: View {
    @EnvironmentObject var terminalManager: TerminalManager
    
    var body: some View {
        VStack {
            if let reader = terminalManager.connectedReader {
                VStack {
                    Text("Connected to:")
                        .font(.headline)
                    Text(reader.label ?? "Unknown Reader")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(reader.serialNumber)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                
                Button("Disconnect") {
                    terminalManager.disconnect()
                }
                .foregroundColor(.red)
                .padding(.top)
            }
        }
    }
}

struct PaymentView: View {
    @Binding var paymentAmount: String
    @EnvironmentObject var terminalManager: TerminalManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Process Payment")
                .font(.title2)
                .fontWeight(.semibold)
            
            HStack {
                Text("$")
                    .font(.title)
                TextField("0.00", text: $paymentAmount)
                    .font(.title)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button(action: {
                processPayment()
            }) {
                Text("Charge Card")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(paymentAmount.isEmpty || Double(paymentAmount) == nil)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func processPayment() {
        guard let amount = Double(paymentAmount) else { return }
        let amountInCents = Int(amount * 100)
        terminalManager.processPayment(amount: amountInCents)
        paymentAmount = ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}