import SwiftUI
import UIKit

struct MainFloatingTabBarRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainFloatingTabBarController {
        return MainFloatingTabBarController()
    }
    
    func updateUIViewController(_ uiViewController: MainFloatingTabBarController, context: Context) {}
}

struct MainTabView: View {
    var body: some View {
        MainFloatingTabBarRepresentable()
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
