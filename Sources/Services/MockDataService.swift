import Foundation

class MockDataService {
    static let shared = MockDataService()
    
    var cryptoAssets: [CryptoAsset] = [
        CryptoAsset(
            name: "Bitcoin",
            symbol: "BTC",
            iconName: "bitcoinsign.circle.fill",
            balance: 0.8542,
            priceUsd: 62450.00,
            change24h: 3.42,
            history: [61200, 61500, 60800, 62100, 61900, 62300, 62450]
        ),
        CryptoAsset(
            name: "Ethereum",
            symbol: "ETH",
            iconName: "dollarsign.circle.fill", // Generic fallback color overlay used in UI custom overlay
            balance: 12.3512,
            priceUsd: 3210.00,
            change24h: -1.85,
            history: [3310, 3280, 3240, 3190, 3230, 3200, 3210]
        ),
        CryptoAsset(
            name: "Solana",
            symbol: "SOL",
            iconName: "s.circle.fill",
            balance: 84.50,
            priceUsd: 148.50,
            change24h: 8.76,
            history: [136, 138, 141, 139, 143, 146, 148.5]
        ),
        CryptoAsset(
            name: "Polkadot",
            symbol: "DOT",
            iconName: "p.circle.fill",
            balance: 350.00,
            priceUsd: 6.20,
            change24h: 0.45,
            history: [6.1, 6.15, 6.05, 6.25, 6.18, 6.22, 6.2]
        )
    ]
    
    var nftCollectibles: [NFTCollectible] = [
        NFTCollectible(
            name: "Pixelated Ape #4208",
            collection: "Brit Ape Club",
            tokenId: "#4208",
            floorPriceEth: 2.45,
            description: "A unique pixelated ape customized with a military cap and neon sunglasses, registered under the BitForge Labs Web3 suite.",
            gradientColors: ["#8E44AD", "#3498DB"] // Purple to Blue
        ),
        NFTCollectible(
            name: "Neon Skull #099",
            collection: "CyberSkulls",
            tokenId: "#099",
            floorPriceEth: 0.85,
            description: "A rare generative virtual skull glowing with reactive holographic particles. Optimized for digital watchfaces.",
            gradientColors: ["#E74C3C", "#F1C40F"] // Red to Yellow
        ),
        NFTCollectible(
            name: "Virtual Space #12",
            collection: "Metaverse Lands",
            tokenId: "#012",
            floorPriceEth: 5.20,
            description: "Prime virtual land plot situated adjacent to the central plaza, ready for dynamic multiplayer dApp experiences.",
            gradientColors: ["#2ECC71", "#1ABC9C"] // Green to Emerald
        ),
        NFTCollectible(
            name: "EtherMech #881",
            collection: "Aether Mechs",
            tokenId: "#881",
            floorPriceEth: 1.15,
            description: "High-fidelity digital robot designed for augmented reality gaming integrations. Built on gas-optimized ERC-721 smart contracts.",
            gradientColors: ["#FF007F", "#7F00FF"] // Pink to Purple
        )
    ]
    
    var vaultCredentials: [VaultCredential] = [
        VaultCredential(
            name: "MetaMask Primary Seed Phrase",
            value: "alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima",
            type: .seedPhrase,
            dateAdded: Date().addingTimeInterval(-86400 * 30)
        ),
        VaultCredential(
            name: "Ethereum Developer Private Key",
            value: "0x892700c5c11b18dca326778ab0d22548bc1ab67fd2bb54d24177b8196157e3f8",
            type: .privateKey,
            dateAdded: Date().addingTimeInterval(-86400 * 15)
        ),
        VaultCredential(
            name: "Hardware Wallet Backup PIN",
            value: "71083726",
            type: .pin,
            dateAdded: Date().addingTimeInterval(-86400 * 5)
        )
    ]
}
