import SwiftUI

@main
struct PodVaultApp: App {
    @State private var isUnlocked: Bool
    @ObservedObject private var vaultService = KeychainVaultService.shared
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        if CommandLine.arguments.contains("-unlocked") {
            _isUnlocked = State(initialValue: true)
        } else {
            _isUnlocked = State(initialValue: false)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(hex: "0B0B0E").edgesIgnoringSafeArea(.all)
                
                if isUnlocked {
                    MainTabView(isUnlocked: $isUnlocked)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    UnlockView(
                        mode: vaultService.isConfigured ? .level1Gate : .setup,
                        isUnlocked: $isUnlocked
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isUnlocked)
            .onChange(of: scenePhase) { phase in
                if phase == .background {
                    // Instantly seal Level 2 Cold Vault whenever backgrounded
                    vaultService.lockLevel2()
                }
            }
        }
    }
}
