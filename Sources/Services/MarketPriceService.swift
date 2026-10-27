import Foundation

struct BinanceTicker: Codable {
    let symbol: String
    let lastPrice: String
    let priceChangePercent: String
}

class MarketPriceService: ObservableObject {
    static let shared = MarketPriceService()
    
    @Published var assets: [CryptoAsset] = []
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date? = nil
    
    init() {
        // Base seed assets with initial realistic values
        self.assets = [
            CryptoAsset(
                name: "Bitcoin",
                symbol: "BTC",
                iconName: "bitcoinsign.circle.fill",
                balance: 0.8542,
                priceUsd: 82950.00,
                change24h: 1.45,
                history: [81200, 81600, 81900, 82400, 82100, 82700, 82950]
            ),
            CryptoAsset(
                name: "Ethereum",
                symbol: "ETH",
                iconName: "dollarsign.circle.fill",
                balance: 12.3512,
                priceUsd: 2840.00,
                change24h: -0.65,
                history: [2920, 2890, 2860, 2820, 2850, 2830, 2840]
            ),
            CryptoAsset(
                name: "Solana",
                symbol: "SOL",
                iconName: "s.circle.fill",
                balance: 84.50,
                priceUsd: 172.50,
                change24h: 4.82,
                history: [160, 163, 167, 165, 169, 171, 172.5]
            ),
            CryptoAsset(
                name: "Polkadot",
                symbol: "DOT",
                iconName: "p.circle.fill",
                balance: 350.00,
                priceUsd: 5.85,
                change24h: 0.32,
                history: [5.70, 5.75, 5.82, 5.78, 5.80, 5.83, 5.85]
            )
        ]
    }
    
    /// Fetches live 24h ticker prices from public market endpoints
    func fetchLivePrices() async {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/24hr?symbols=[%22BTCUSDT%22,%22ETHUSDT%22,%22SOLUSDT%22,%22DOTUSDT%22]") else { return }
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run { self.isLoading = false }
                return
            }
            
            let tickers = try JSONDecoder().decode([BinanceTicker].self, from: data)
            
            await MainActor.run {
                for ticker in tickers {
                    guard let price = Double(ticker.lastPrice),
                          let change = Double(ticker.priceChangePercent) else { continue }
                    
                    let coinSymbol = ticker.symbol.replacingOccurrences(of: "USDT", with: "")
                    if let index = self.assets.firstIndex(where: { $0.symbol == coinSymbol }) {
                        var updatedHistory = self.assets[index].history
                        if updatedHistory.count > 1 {
                            updatedHistory[updatedHistory.count - 1] = price
                        }
                        self.assets[index] = CryptoAsset(
                            name: self.assets[index].name,
                            symbol: self.assets[index].symbol,
                            iconName: self.assets[index].iconName,
                            balance: self.assets[index].balance,
                            priceUsd: price,
                            change24h: change,
                            history: updatedHistory
                        )
                    }
                }
                self.isLoading = false
                self.lastUpdated = Date()
            }
        } catch {
            print("MarketPriceService: Error fetching live prices: \(error)")
            await MainActor.run { self.isLoading = false }
        }
    }
}
