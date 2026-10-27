import SwiftUI

struct DashboardView: View {
    @Binding var isUnlocked: Bool
    @ObservedObject var wcService = WalletConnectService.shared
    
    @ObservedObject var marketService = MarketPriceService.shared
    @State private var realEthBalance: Double? = nil
    @State private var isLoadingBalance = false
    @State private var balanceError: String? = nil
    @State private var showingCustomWalletSheet = false
    @State private var customAddressInput = ""
    
    var totalBalance: Double {
        var sum = 0.0
        for asset in marketService.assets {
            if asset.symbol == "ETH" && wcService.isConnected {
                sum += (realEthBalance ?? 0.0) * asset.priceUsd
            } else {
                sum += asset.valueUsd
            }
        }
        return sum
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if wcService.isConnected {
                        // Connected State Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("PORTFOLIO BALANCE")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.4))
                                    .tracking(2)
                                
                                Spacer()
                                
                                // Truncated wallet address pill
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(hex: "2ECC71"))
                                        .frame(width: 8, height: 8)
                                    Text(truncateAddress(wcService.walletAddress ?? ""))
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(100)
                            }
                            
                            if isLoadingBalance {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "00A3FF")))
                                    .frame(height: 45)
                            } else {
                                Text(String(format: "$%.2f", totalBalance))
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundColor(Color(hex: "2ECC71"))
                                Text("+$2,410.88 (2.62%)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "2ECC71"))
                                Text("today")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Interactive Sparkline Chart
                            SparklineView(data: [91910, 92300, 91500, 93200, 92800, 93900, totalBalance], color: Color(hex: "00A3FF"))
                                .frame(height: 100)
                                .padding(.top, 16)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Action Buttons Row
                        HStack(spacing: 16) {
                            actionButton(title: "Send", icon: "arrow.up.circle.fill")
                            actionButton(title: "Receive", icon: "arrow.down.circle.fill")
                            actionButton(title: "Disconnect", icon: "link.badge.plus") {
                                wcService.disconnect()
                                realEthBalance = nil
                            }
                        }
                        .padding(.horizontal)
                        
                    } else {
                        // Disconnected / Connect Wallet Card
                        VStack(spacing: 20) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "00A3FF"))
                                .padding(.top, 10)
                            
                            VStack(spacing: 8) {
                                Text("Link Your Crypto Wallet")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white)
                                Text("Connect MetaMask or load the read-only live demo wallet to query real-time blockchain balances.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 10)
                            }
                            
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await wcService.connect()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("Connect MetaMask")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "00A3FF"), Color(hex: "0055ff")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .shadow(color: Color(hex: "00A3FF").opacity(0.3), radius: 8, y: 4)
                                    )
                                }
                                
                                Button(action: {
                                    wcService.connectDemoWallet()
                                }) {
                                    Text("Connect Demo Wallet (vitalik.eth)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color(hex: "00A3FF"))
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(hex: "00A3FF").opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Button(action: {
                                    showingCustomWalletSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                        Text("Watch Any Wallet Address")
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.04))
                                    )
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding(26)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.02))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                    }
                    
                    // Assets List Header
                    HStack {
                        Text("Assets")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Market (24h)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Assets List
                    VStack(spacing: 12) {
                        ForEach(marketService.assets) { asset in
                            let isEth = asset.symbol == "ETH"
                            let displayBalance = (isEth && wcService.isConnected) ? (realEthBalance ?? 0.0) : asset.balance
                            let displayValue = (isEth && wcService.isConnected) ? (realEthBalance ?? 0.0) * asset.priceUsd : asset.valueUsd
                            
                            HStack(spacing: 16) {
                                // Asset Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.02))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: asset.iconName)
                                        .font(.title3)
                                        .foregroundColor(asset.change24h > 0 ? Color(hex: "00A3FF") : Color(hex: "E74C3C"))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(asset.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    if isEth && wcService.isConnected && isLoadingBalance {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(String(format: "%.4f %@", displayBalance, asset.symbol))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Mini Sparkline
                                SparklineView(data: asset.history, color: asset.change24h > 0 ? Color(hex: "2ECC71") : Color(hex: "E74C3C"))
                                    .frame(width: 60, height: 25)
                                    .padding(.trailing, 8)
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "$%.2f", displayValue))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(String(format: "%@%.2f%%", asset.change24h > 0 ? "+" : "", asset.change24h))
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(asset.change24h > 0 ? Color(hex: "2ECC71") : Color(hex: "E74C3C"))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.01))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .background(Color(hex: "0F0F12").edgesIgnoringSafeArea(.all))
            .onAppear {
                loadBalance()
                Task {
                    await marketService.fetchLivePrices()
                }
            }
            .refreshable {
                loadBalance()
                await marketService.fetchLivePrices()
            }
            .onChange(of: wcService.walletAddress) { _ in
                loadBalance()
            }
            .sheet(isPresented: $showingCustomWalletSheet) {
                customWalletSheetView
            }
        }
    }
    
    private var customWalletSheetView: some View {
        ZStack {
            Color(hex: "16161A").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Watch Public Wallet")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Text("Paste any Ethereum address (e.g. 0x...) to track live balances and holdings without sharing private keys.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("0x71C... or ENS name", text: $customAddressInput)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                HStack(spacing: 14) {
                    Button("Cancel") {
                        showingCustomWalletSheet = false
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)
                    
                    Button("Connect") {
                        let clean = customAddressInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            wcService.walletAddress = clean
                            wcService.isConnected = true
                            showingCustomWalletSheet = false
                        }
                    }
                    .foregroundColor(.white)
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "00A3FF"))
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 24)
        }
        .applySheetDetents()
    }
    
    private func loadBalance() {
        guard let address = wcService.walletAddress else { return }
        isLoadingBalance = true
        balanceError = nil
        
        Task {
            do {
                let balance = try await EthereumRPCService.shared.fetchEthBalance(for: address)
                DispatchQueue.main.async {
                    self.realEthBalance = balance
                    self.isLoadingBalance = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.balanceError = error.localizedDescription
                    self.isLoadingBalance = false
                }
            }
        }
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        return String(address.prefix(6)) + "..." + String(address.suffix(4))
    }
    
    private func actionButton(title: String, icon: String, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "00A3FF"))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}

// Sparkline Custom SwiftUI Path Chart
struct SparklineView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard data.count > 1 else { return }
                let width = geo.size.width
                let height = geo.size.height
                
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
                
                let stepX = width / CGFloat(data.count - 1)
                
                let firstY = height - CGFloat((data[0] - minVal) / range) * height
                path.move(to: CGPoint(x: 0, y: firstY))
                
                for idx in 1..<data.count {
                    let x = CGFloat(idx) * stepX
                    let y = height - CGFloat((data[idx] - minVal) / range) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

extension View {
    @ViewBuilder
    func applySheetDetents() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.fraction(0.45)])
        } else {
            self
        }
    }
}
