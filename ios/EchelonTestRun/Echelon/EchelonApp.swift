import SwiftUI
import Combine
import FirebaseCore

class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct EchelonApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
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
