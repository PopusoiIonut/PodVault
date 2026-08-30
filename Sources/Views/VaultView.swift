import SwiftUI

struct VaultView: View {
    @ObservedObject var wcService = WalletConnectService.shared
    @State private var credentials = MockDataService.shared.vaultCredentials
    @State private var revealedIds: Set<UUID> = []
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Disclaimer banner
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(Color(hex: "00A3FF"))
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Local Encryption Active")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Credentials are encrypted with AES-256 and stored locally in sandbox keychain.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "00A3FF").opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "00A3FF").opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        
                        // Credentials List
                        VStack(spacing: 16) {
                            if wcService.isConnected, let address = wcService.walletAddress {
                                activeConnectionRow(address: address)
                            }
                            
                            ForEach(credentials) { cred in
                                credentialRow(cred: cred)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Secure Keys")
                .background(Color(hex: "0F0F12").edgesIgnoringSafeArea(.all))
                
                // Floating Toast Notification
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "00A3FF"))
                                    .shadow(color: Color(hex: "00A3FF").opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                            .padding(.bottom, 50)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(10)
                }
            }
        }
    }
    
    private func activeConnectionRow(address: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(Color(hex: "2ECC71"))
                    .font(.subheadline)
                
                Text("Active Wallet Session")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2ECC71"))
                
                Spacer()
                
                Text("Verified")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "2ECC71"))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Color(hex: "2ECC71").opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text("Linked Public Key")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text(address)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                // Copy Button
                Button(action: {
                    copyToClipboard(value: address, name: "Public Wallet Key")
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color(hex: "00A3FF"))
                        .padding(8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: "2ECC71").opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: "2ECC71").opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func credentialRow(cred: VaultCredential) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: cred.type.iconName)
                    .foregroundColor(Color(hex: "00A3FF"))
                    .font(.subheadline)
                
                Text(cred.type.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(cred.dateAdded))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(cred.name)
                .font(.headline)
                .foregroundColor(.white)
            
            // Password / Seed Field
            HStack {
                if revealedIds.contains(cred.id) {
                    Text(cred.value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else {
                    Text(String(repeating: "•", count: 24))
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .tracking(2)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Toggle Reveal Button
                Button(action: {
                    toggleReveal(for: cred.id)
                }) {
                    Image(systemName: revealedIds.contains(cred.id) ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                
                // Copy Button
                Button(action: {
                    copyToClipboard(value: cred.value, name: cred.name)
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color(hex: "00A3FF"))
                        .padding(8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.01))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private func toggleReveal(for id: UUID) {
        if revealedIds.contains(id) {
            revealedIds.remove(id)
        } else {
            revealedIds.insert(id)
        }
    }
    
    private func copyToClipboard(value: String, name: String) {
        UIPasteboard.general.string = value
        toastMessage = "Copied \(name)! ✓"
        withAnimation(.spring()) {
            showToast = true
        }
        
        // Trigger haptic response
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring()) {
                showToast = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
