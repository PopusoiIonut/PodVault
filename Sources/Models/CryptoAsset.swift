import Foundation

struct CryptoAsset: Identifiable, Codable {
    var id = UUID()
    let name: String
    let symbol: String
    let iconName: String // SF Symbol name
    var balance: Double
    var priceUsd: Double
    var change24h: Double // e.g. +5.4
    var history: [Double] // Last 7 data points for sparkline charts
    
    var valueUsd: Double {
        return balance * priceUsd
    }
}
