import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }
            
            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Color(red: 0.52, green: 0.12, blue: 0.25)) // Virginia Tech Maroon
    }
}

#Preview {
    MainTabView()
}

