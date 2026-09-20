import SwiftUI
import Combine

@main
struct EchelonApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(appState)
            .preferredColorScheme(.dark)
        }
    }
}

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = true
}
