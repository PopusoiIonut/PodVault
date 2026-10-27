import SwiftUI

struct VaultView: View {
    @ObservedObject var wcService = WalletConnectService.shared
    @ObservedObject var vaultService = KeychainVaultService.shared
    
    @State private var revealedIds: Set<UUID> = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showingAddCredentialSheet = false
    @State private var showingLevel2Modal = false
    @State private var newCredName = ""
    @State private var newCredValue = ""
    @State private var newCredType: CredentialType = .seedPhrase
    
    private var isCompact: Bool {
        UIScreen.main.bounds.height <= 568 || UIScreen.main.bounds.width <= 320
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0B0B0E").edgesIgnoringSafeArea(.all)
                
                if vaultService.isLevel2Unlocked {
                    unlockedVaultContent
                } else {
                    sealedVaultCover
                }
                
                // Floating Toast Notification
                if showToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "00A3FF"))
                                    .shadow(color: Color(hex: "00A3FF").opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                            .padding(.bottom, 30)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(20)
                }
            }
            .navigationTitle("Secure Vault")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if vaultService.isLevel2Unlocked {
                        HStack(spacing: 12) {
                            Button(action: {
                                vaultService.lockLevel2()
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                            }) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "FF3B30"))
                            }
                            
                            Button(action: {
                                showingAddCredentialSheet = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "00A3FF"))
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCredentialSheet) {
                addCredentialSheetView
            }
            .sheet(isPresented: $showingLevel2Modal) {
                UnlockView(
                    mode: .level2Master,
                    isUnlocked: $showingLevel2Modal,
                    onComplete: {
                        vaultService.isLevel2Unlocked = true
                        showingLevel2Modal = false
                    }
                )
            }
        }
    }
    
    // MARK: - Level 2 Sealed Cover
    private var sealedVaultCover: some View {
        ScrollView {
            VStack(spacing: isCompact ? 16 : 24) {
                Spacer(minLength: isCompact ? 20 : 50)
                
                ZStack {
                    Circle()
                        .fill(Color(hex: "FF3B30").opacity(0.04))
                        .frame(width: isCompact ? 80 : 110, height: isCompact ? 80 : 110)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "FF3B30").opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "FF3B30").opacity(0.15), radius: 15)
                    
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: isCompact ? 36 : 48, weight: .medium))
                        .foregroundColor(Color(hex: "FF3B30"))
                }
                
                VStack(spacing: 8) {
                    Text("LEVEL 2 VAULT SEALED")
                        .font(.system(size: isCompact ? 16 : 20, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Text("Seed phrases, private keys, and hardware PINs are cryptographically locked behind your Level 2 Master Key.")
                        .font(.system(size: isCompact ? 12 : 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, isCompact ? 20 : 36)
                }
                
                // Hardware Enclave Info Box
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Color(hex: "00A3FF"))
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cold Storage Architecture")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("AES-256 GCM keychain hardware isolation active.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                
                // Big Unlock Button
                Button(action: {
                    showingLevel2Modal = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 15, weight: .bold))
                        Text("ENTER MASTER KEY")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .tracking(1)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isCompact ? 48 : 54)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF3B30"), Color(hex: "D32F2F")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "FF3B30").opacity(0.35), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                Spacer(minLength: 30)
            }
        }
    }
    
    // MARK: - Level 2 Unlocked Content
    private var unlockedVaultContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                // Armed Status Banner
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: "2ECC71"))
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LEVEL 2 MASTER UNLOCKED")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "2ECC71"))
                            .tracking(1)
                        Text("Sensitive credentials unmasked. Lock before backgrounding.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        vaultService.lockLevel2()
                    }) {
                        Text("Lock")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                            .background(Color(hex: "FF3B30"))
                            .cornerRadius(8)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "2ECC71").opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "2ECC71").opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                
                // Credentials List
                VStack(spacing: 14) {
                    if wcService.isConnected, let address = wcService.walletAddress {
                        activeConnectionRow(address: address)
                    }
                    
                    ForEach(vaultService.credentials) { cred in
                        credentialRow(cred: cred)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func activeConnectionRow(address: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(Color(hex: "2ECC71"))
                    .font(.subheadline)
                
                Text("Active Wallet Session")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(hex: "2ECC71"))
                
                Spacer()
                
                Text("Verified")
                    .font(.caption2.weight(.bold))
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
                
                Button(action: {
                    copyToClipboard(value: address, name: "Public Wallet Key")
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color(hex: "00A3FF"))
                        .padding(6)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.25))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "2ECC71").opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "2ECC71").opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func credentialRow(cred: VaultCredential) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: cred.type.iconName)
                    .foregroundColor(Color(hex: "00A3FF"))
                    .font(.subheadline)
                
                Text(cred.type.rawValue)
                    .font(.caption.weight(.bold))
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
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2)
                } else {
                    Text(String(repeating: "•", count: 20))
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
                        .padding(6)
                }
                
                // Copy Button
                Button(action: {
                    copyToClipboard(value: cred.value, name: cred.name)
                }) {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Color(hex: "00A3FF"))
                        .padding(6)
                }
                
                // Delete Button
                Button(action: {
                    vaultService.deleteCredential(id: cred.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(Color.red.opacity(0.7))
                        .padding(6)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.25))
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    private var addCredentialSheetView: some View {
        NavigationView {
            ZStack {
                Color(hex: "16161A").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Type", selection: $newCredType) {
                                ForEach(CredentialType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Label / Account Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("e.g. Master Cold Seed", text: $newCredName)
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Secret Key / Phrase")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("12/24 words or hex private key", text: $newCredValue)
                                .font(.system(.caption, design: .monospaced))
                                .padding(12)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            let name = newCredName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let val = newCredValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty, !val.isEmpty else { return }
                            vaultService.addCredential(name: name, value: val, type: newCredType)
                            newCredName = ""
                            newCredValue = ""
                            showingAddCredentialSheet = false
                        }) {
                            Text("Save to Cold Keychain")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(Color(hex: "00A3FF"))
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Master Key")
            .navigationBarItems(trailing: Button("Cancel") {
                showingAddCredentialSheet = false
            }.foregroundColor(.secondary))
        }
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
