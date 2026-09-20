import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth

class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    override init() {
        super.init()
        if FirebaseApp.allApps?.isEmpty ?? true {
            FirebaseApp.configure()
        }
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if FirebaseApp.allApps?.isEmpty ?? true {
            FirebaseApp.configure()
        }
        return true
    }
}

@main
struct EchelonApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainTabView()
                } else {
                    AuthLandingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(authService)
            .environmentObject(appState)
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.35), value: authService.isAuthenticated)
            .onOpenURL { url in
                _ = Auth.auth().canHandle(url)
            }
            .task {
                await authService.runSmokescreenTest()
            }
        }
    }
}

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = true
}
