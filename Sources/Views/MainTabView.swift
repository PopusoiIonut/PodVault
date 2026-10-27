import SwiftUI

struct MainTabView: View {
    @Binding var isUnlocked: Bool
    @State private var selectedTab: Int
    
    init(isUnlocked: Binding<Bool>) {
        self._isUnlocked = isUnlocked
        if CommandLine.arguments.contains("-keys") {
            self._selectedTab = State(initialValue: 2)
        } else if CommandLine.arguments.contains("-collectibles") {
            self._selectedTab = State(initialValue: 1)
        } else {
            self._selectedTab = State(initialValue: 0)
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(isUnlocked: $isUnlocked)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .tag(0)
            
            NFTGalleryView()
                .tabItem {
                    Label("Collectibles", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)
            
            VaultView()
                .tabItem {
                    Label("Keys", systemImage: "lock.shield.fill")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "00A3FF"))
        .onAppear {
            // Apply standard dark style tab bar appearances
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "16161A"))
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
