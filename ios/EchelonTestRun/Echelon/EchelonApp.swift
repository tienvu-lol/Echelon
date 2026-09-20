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

final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.object(forKey: "hasCompletedOnboarding") as? Bool ?? true
    }
}

@main
struct EchelonApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    if !appState.hasCompletedOnboarding {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                } else {
                    AuthLandingView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environmentObject(authService)
            .environmentObject(appState)
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.35), value: authService.isAuthenticated)
            .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
            .onOpenURL { url in
                _ = Auth.auth().canHandle(url)
            }
            .task {
                await authService.runSmokescreenTest()
            }
        }
    }
}
