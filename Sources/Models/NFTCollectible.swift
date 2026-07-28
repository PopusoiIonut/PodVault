import Foundation

struct NFTCollectible: Identifiable, Codable {
    var id = UUID()
    let name: String
    let collection: String
    let tokenId: String
    let floorPriceEth: Double
    let description: String
    let gradientColors: [String] // Hex color strings for generating rich abstract art inside the cards
}
