import Foundation
import UIKit
import Combine
import WalletConnectModal
import WalletConnectPairing
import WalletConnectRelay

class WalletConnectService: ObservableObject {
    static let shared = WalletConnectService()
    
    // Get a free Project ID from: https://cloud.walletconnect.com/
    static let projectId = "YOUR_WALLET_CONNECT_PROJECT_ID"
    
    @Published var isConnected = false
    @Published var walletAddress: String? = nil
    @Published var pairingUri: String? = nil
    
    private var publishers = Set<AnyCancellable>()
    private var isConfigured = false
    
    init() {
        configureSDK()
    }
    
    private func configureSDK() {
        guard Self.projectId != "YOUR_WALLET_CONNECT_PROJECT_ID" && !Self.projectId.isEmpty else {
            print("WalletConnect: Project ID not configured. Running in Demo Mode.")
            return
        }
        
        do {
            // Configure Networking with custom socket factory
            let socketFactory = DefaultSocketFactory()
            Networking.configure(
                groupIdentifier: "group.com.popusoiionut.PodVault",
                projectId: Self.projectId,
                socketFactory: socketFactory
            )
            
            // Configure App Metadata
            let redirect = try AppMetadata.Redirect(native: "podvault://", universal: nil)
            let metadata = AppMetadata(
                name: "PodVault",
                description: "Secure Crypto & NFT Vault",
                url: "bitforgelabs.com",
                icons: ["https://bitforgelabs.com/vite.svg"],
                redirect: redirect
            )
            
            // Configure WalletConnectModal
            WalletConnectModal.configure(
                projectId: Self.projectId,
                metadata: metadata
            )
            
            setupModalClientSubscribers()
            isConfigured = true
        } catch {
            print("WalletConnect initialization failed: \(error)")
        }
    }
    
    /// Connects to a real mobile wallet via WalletConnect and deep-links to MetaMask
    func connect() async {
        guard isConfigured else {
            connectDemoWallet()
            return
        }
        
        do {
            let uri = try await WalletConnectModal.instance.connect()
            DispatchQueue.main.async {
                self.pairingUri = uri.absoluteString
            }
            
            let encodedUri = uri.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? uri.absoluteString
            if let deepLinkUrl = URL(string: "metamask://wc?uri=\(encodedUri)") {
                DispatchQueue.main.async {
                    if UIApplication.shared.canOpenURL(deepLinkUrl) {
                        UIApplication.shared.open(deepLinkUrl)
                    } else {
                        // Fallback: If metamask app is not installed, copy uri
                        UIPasteboard.general.string = uri.absoluteString
                        print("MetaMask app not found. Copied pairing URI to clipboard: \(uri.absoluteString)")
                    }
                }
            }
        } catch {
            print("WalletConnect pairing creation failed: \(error)")
        }
    }
    
    /// Connects a real public Ethereum address as a read-only demo to test live RPC fetching
    func connectDemoWallet() {
        DispatchQueue.main.async {
            // Vitalik Buterin's public address (vitalik.eth)
            self.walletAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
            self.isConnected = true
        }
    }
    
    /// Disconnects the active wallet session
    func disconnect() {
        if isConfigured, let session = WalletConnectModal.instance.getSessions().first {
            Task {
                do {
                    try await WalletConnectModal.instance.disconnect(topic: session.topic)
                } catch {
                    print("WalletConnect disconnect failed: \(error)")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.walletAddress = nil
            self.isConnected = false
            self.pairingUri = nil
        }
    }
    
    private func setupModalClientSubscribers() {
        WalletConnectModal.instance.sessionSettlePublisher.sink { session in
            guard let account = session.accounts.first else { return }
            DispatchQueue.main.async {
                self.walletAddress = account.address
                self.isConnected = true
            }
        }.store(in: &publishers)
        
        WalletConnectModal.instance.sessionDeletePublisher.sink { _ in
            DispatchQueue.main.async {
                self.walletAddress = nil
                self.isConnected = false
                self.pairingUri = nil
            }
        }.store(in: &publishers)
    }
}

// MARK: - Default WebSocket & Factory conformers using URLSession

class DefaultWebSocket: NSObject, WebSocketConnecting, URLSessionWebSocketDelegate {
    var request: URLRequest
    var isConnected: Bool = false
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }()
    
    init(request: URLRequest) {
        self.request = request
        super.init()
    }
    
    func connect() {
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }
    
    func write(string: String, completion: (() -> Void)?) {
        webSocketTask?.send(.string(string)) { error in
            if error == nil {
                completion?()
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.onText?(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.onText?(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
            case .failure(let error):
                self.onDisconnect?(error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        onConnect?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
        onDisconnect?(nil)
    }
}

class DefaultSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        return DefaultWebSocket(request: URLRequest(url: url))
    }
}
