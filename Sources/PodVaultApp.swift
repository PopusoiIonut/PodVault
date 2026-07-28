import SwiftUI

@main
struct PodVaultApp: App {
    @State private var isUnlocked = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(hex: "0F0F12").edgesIgnoringSafeArea(.all)
                
                if isUnlocked {
                    MainTabView(isUnlocked: $isUnlocked)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    UnlockView(isUnlocked: $isUnlocked)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isUnlocked)
        }
    }
}
