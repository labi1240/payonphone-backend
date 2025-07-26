import Foundation
import StripeTerminal
import Combine

class TerminalManager: NSObject, ObservableObject {
    static let shared = TerminalManager()
    
    @Published var connectionStatus: ConnectionStatus = .notConnected
    @Published var discoveredReaders: [Reader] = []
    @Published var connectedReader: Reader?
    @Published var lastPaymentIntent: PaymentIntent?
    @Published var isDiscovering = false
    
    private var discoverCancelable: Cancelable?
    
    enum ConnectionStatus {
        case notConnected
        case connecting
        case connected
    }
    
    override init() {
        super.init()
        Terminal.shared.delegate = self
    }
    
    func discoverReaders() {
        guard !isDiscovering else { return }
        
        isDiscovering = true
        discoveredReaders.removeAll()
        
        let config = DiscoveryConfiguration(
            discoveryMethod: .bluetoothScan,
            simulated: false // Set to true for testing
        )
        
        discoverCancelable = Terminal.shared.discoverReaders(config, delegate: self) { error in
            DispatchQueue.main.async {
                self.isDiscovering = false
                if let error = error {
                    print("Discovery failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func connectToReader(_ reader: Reader) {
        connectionStatus = .connecting
        
        let config = BluetoothConnectionConfiguration(locationId: "your-location-id")
        
        Terminal.shared.connectBluetoothReader(reader, delegate: self, connectionConfig: config) { reader, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Connection failed: \(error.localizedDescription)")
                    self.connectionStatus = .notConnected
                } else {
                    self.connectedReader = reader
                    self.connectionStatus = .connected
                    print("Connected to reader: \(reader?.label ?? "Unknown")")
                }
            }
        }
    }
    
    func processPayment(amount: Int, currency: String = "usd") {
        guard connectedReader != nil else {
            print("No reader connected")
            return
        }
        
        let params = PaymentIntentParameters(
            amount: amount,
            currency: currency,
            captureMethod: .automatic
        )
        
        Terminal.shared.createPaymentIntent(params) { paymentIntent, error in
            if let error = error {
                print("Failed to create payment intent: \(error.localizedDescription)")
                return
            }
            
            guard let paymentIntent = paymentIntent else { return }
            
            Terminal.shared.collectPaymentMethod(paymentIntent, delegate: self) { paymentIntent, error in
                if let error = error {
                    print("Failed to collect payment method: \(error.localizedDescription)")
                    return
                }
                
                guard let paymentIntent = paymentIntent else { return }
                
                Terminal.shared.processPayment(paymentIntent) { paymentIntent, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Payment failed: \(error.localizedDescription)")
                        } else {
                            self.lastPaymentIntent = paymentIntent
                            print("Payment successful!")
                        }
                    }
                }
            }
        }
    }
    
    func disconnect() {
        Terminal.shared.disconnectReader { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Disconnect failed: \(error.localizedDescription)")
                } else {
                    self.connectedReader = nil
                    self.connectionStatus = .notConnected
                }
            }
        }
    }
}

// MARK: - Terminal Delegates
extension TerminalManager: TerminalDelegate {
    func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
        DispatchQueue.main.async {
            self.connectedReader = nil
            self.connectionStatus = .notConnected
        }
    }
}

extension TerminalManager: DiscoveryDelegate {
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        DispatchQueue.main.async {
            self.discoveredReaders = readers
        }
    }
}

extension TerminalManager: BluetoothReaderDelegate {
    func terminal(_ terminal: Terminal, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        print("Installing update...")
    }
    
    func terminal(_ terminal: Terminal, didReportReaderSoftwareUpdateProgress progress: Float) {
        print("Update progress: \(progress)")
    }
    
    func terminal(_ terminal: Terminal, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let error = error {
            print("Update failed: \(error.localizedDescription)")
        } else {
            print("Update completed")
        }
    }
}

extension TerminalManager: CollectPaymentMethodDelegate {
    func terminal(_ terminal: Terminal, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        print("Reader requesting input: \(inputOptions)")
    }
    
    func terminal(_ terminal: Terminal, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        print("Reader display: \(displayMessage)")
    }
}