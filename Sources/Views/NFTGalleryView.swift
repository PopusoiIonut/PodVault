import SwiftUI

struct NFTGalleryView: View {
    @State private var nfts = MockDataService.shared.nftCollectibles
    @State private var selectedNFT: NFTCollectible? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(nfts) { nft in
                            nftCard(nft: nft)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedNFT = nft
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Collectibles")
                .background(Color(hex: "0F0F12").edgesIgnoringSafeArea(.all))
                
                // NFT Detail Modal Overlay
                if let nft = selectedNFT {
                    Color.black.opacity(0.8)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedNFT = nil
                            }
                        }
                    
                    nftDetailModal(nft: nft)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
        }
    }
    
    private func nftCard(nft: NFTCollectible) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Gradient abstract placeholder art
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: nft.gradientColors.map { Color(hex: $0) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.6))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(nft.collection)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "00A3FF"))
                    .tracking(1)
                
                Text(nft.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "circle.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(String(format: "%.2f", nft.floorPriceEth)) ETH")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private func nftDetailModal(nft: NFTCollectible) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 24) {
                // Header image/gradient
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: nft.gradientColors.map { Color(hex: $0) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 240)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.7))
                    )
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(nft.collection)
                            .font(.headline)
                            .foregroundColor(Color(hex: "00A3FF"))
                        
                        Spacer()
                        
                        Text(nft.tokenId)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(nft.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(nft.description)
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.7))
                        .lineHeight(1.5)
                        .padding(.top, 4)
                }
                
                // Properties Row
                HStack(spacing: 16) {
                    propertyTile(title: "Floor Price", value: "\(nft.floorPriceEth) ETH")
                    propertyTile(title: "Network", value: "Ethereum")
                    propertyTile(title: "Standard", value: "ERC-721")
                }
                
                // Close Button
                Button(action: {
                    withAnimation(.spring()) {
                        selectedNFT = nil
                    }
                }) {
                    Text("Close details")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "16161A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private func propertyTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// Line Height Modifier helper
struct LineHeightModifier: ViewModifier {
    let height: CGFloat
    func body(content: Content) -> some View {
        content.lineSpacing(height)
    }
}

extension View {
    func lineHeight(_ height: CGFloat) -> some View {
        self.modifier(LineHeightModifier(height: height))
    }
}
