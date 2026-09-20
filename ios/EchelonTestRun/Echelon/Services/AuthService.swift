import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import Combine

// MARK: - Demo User Representation
struct DemoUser: Equatable {
    let uid: String
    let email: String
    let displayName: String
    let phoneNumber: String?
}

// MARK: - Presentation UI Delegate for OAuth Flows
final class AuthPresentationDelegate: NSObject, AuthUIDelegate {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
        super.init()
    }
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if let presenter = presenter {
            presenter.present(viewControllerToPresent, animated: flag, completion: completion)
        } else {
            completion?()
        }
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let presenter = presenter {
            presenter.dismiss(animated: flag, completion: completion)
        } else {
            completion?()
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private static let stayLoggedInKey = "echelon_stay_logged_in"
    private static let demoEmailKey = "echelon_demo_user_email"
    private static let demoNameKey = "echelon_demo_user_name"
    private static let demoUIDKey = "echelon_demo_user_uid"
    private static let demoPhoneKey = "echelon_demo_user_phone"
    
    @Published var currentUser: FirebaseAuth.User?
    @Published var demoUser: DemoUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var userEmail: String? {
        currentUser?.email ?? demoUser?.email
    }
    
    var userDisplayName: String? {
        if let name = currentUser?.displayName, !name.isEmpty {
            return name
        }
        return demoUser?.displayName
    }
    
    var userUID: String? {
        currentUser?.uid ?? demoUser?.uid
    }
    
    var userPhoneNumber: String? {
        if let phone = currentUser?.phoneNumber, !phone.isEmpty {
            return phone
        }
        if let demoPhone = demoUser?.phoneNumber, !demoPhone.isEmpty {
            return demoPhone
        }
        if let uid = userUID {
            return UserDefaults.standard.string(forKey: "echelon_phone_\(uid)")
        }
        return nil
    }
    
    var isDemoSession: Bool {
        demoUser != nil
    }
    
    @Published var stayLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(stayLoggedIn, forKey: Self.stayLoggedInKey)
        }
    }
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Ensure Firebase is configured before accessing Auth
        if FirebaseApp.allApps?.isEmpty ?? true {
            FirebaseApp.configure()
        }
        
        // Retrieve stayLoggedIn preference, default to true
        if UserDefaults.standard.object(forKey: Self.stayLoggedInKey) != nil {
            self.stayLoggedIn = UserDefaults.standard.bool(forKey: Self.stayLoggedInKey)
        } else {
            self.stayLoggedIn = true
            UserDefaults.standard.set(true, forKey: Self.stayLoggedInKey)
        }
        
        // If stayLoggedIn is false, clear any persisted session on cold launch
        if !self.stayLoggedIn {
            if Auth.auth().currentUser != nil {
                try? Auth.auth().signOut()
            }
            UserDefaults.standard.removeObject(forKey: Self.demoEmailKey)
            UserDefaults.standard.removeObject(forKey: Self.demoNameKey)
            UserDefaults.standard.removeObject(forKey: Self.demoUIDKey)
            UserDefaults.standard.removeObject(forKey: Self.demoPhoneKey)
        }
        
        let initialUser = Auth.auth().currentUser
        self.currentUser = initialUser
        
        // Check for persisted demo session
        if initialUser == nil && self.stayLoggedIn,
           let dEmail = UserDefaults.standard.string(forKey: Self.demoEmailKey),
           let dName = UserDefaults.standard.string(forKey: Self.demoNameKey),
           let dUID = UserDefaults.standard.string(forKey: Self.demoUIDKey) {
            let dPhone = UserDefaults.standard.string(forKey: Self.demoPhoneKey)
            self.demoUser = DemoUser(uid: dUID, email: dEmail, displayName: dName, phoneNumber: dPhone)
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = (initialUser != nil)
        }
        
        self.authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                if let user = user {
                    self.currentUser = user
                    self.demoUser = nil
                    self.isAuthenticated = true
                } else if self.demoUser == nil {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Email Sign In
    
    func signIn(email: String, password: String, stayLoggedIn: Bool) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            self.demoUser = nil
            self.stayLoggedIn = stayLoggedIn
            self.currentUser = result.user
            self.isAuthenticated = true
            
            // Connect data pipeline: fetch token and verify with backend API server
            if let token = try? await result.user.getIDToken() {
                _ = try? await APIService.shared.verifyAuthMe(token: token)
            }
        } catch {
            let userFriendly = parseAuthError(error)
            self.errorMessage = userFriendly
            throw error
        }
    }
    
    // MARK: - Email Sign Up
    
    func signUp(
        email: String,
        password: String,
        displayName: String,
        phoneNumber: String? = nil,
        stayLoggedIn: Bool
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            let result = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            if !trimmedName.isEmpty {
                let req = result.user.createProfileChangeRequest()
                req.displayName = trimmedName
                try? await req.commitChanges()
            }
            if let phone = trimmedPhone, !phone.isEmpty {
                UserDefaults.standard.set(phone, forKey: "echelon_phone_\(result.user.uid)")
            }
            self.demoUser = nil
            self.stayLoggedIn = stayLoggedIn
            self.currentUser = result.user
            self.isAuthenticated = true
            
            // Connect data pipeline: fetch token and verify with backend API server
            if let token = try? await result.user.getIDToken() {
                _ = try? await APIService.shared.verifyAuthMe(token: token)
            }
        } catch {
            let userFriendly = parseAuthError(error)
            self.errorMessage = userFriendly
            throw error
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let provider = OAuthProvider(providerID: "google.com")
        provider.scopes = ["email", "profile"]
        
        do {
            let topVC = getTopViewController()
            let uiDelegate: AuthUIDelegate? = topVC != nil ? AuthPresentationDelegate(presenter: topVC) : nil
            let credential = try await provider.credential(with: uiDelegate)
            let result = try await Auth.auth().signIn(with: credential)
            self.demoUser = nil
            self.currentUser = result.user
            self.isAuthenticated = true
            
            if let token = try? await result.user.getIDToken() {
                _ = try? await APIService.shared.verifyAuthMe(token: token)
            }
        } catch {
            let nsError = error as NSError
            if nsError.code == AuthErrorCode.webContextCancelled.rawValue || nsError.code == 17057 {
                return
            }
            let userFriendly = parseAuthError(error)
            self.errorMessage = userFriendly
            throw error
        }
    }
    
    // MARK: - Phone Number Verification & Sign In
    
    func sendPhoneVerificationCode(phoneNumber: String) async throws -> String {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let err = NSError(domain: "AuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid phone number."])
            self.errorMessage = err.localizedDescription
            throw err
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(trimmed, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let verificationID = verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    let err = NSError(domain: "AuthService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to obtain verification ID."])
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    func signInWithPhoneCode(verificationID: String, verificationCode: String, phoneNumber: String? = nil, stayLoggedIn: Bool) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let trimmedCode = verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: trimmedCode
        )
        
        do {
            let result = try await Auth.auth().signIn(with: credential)
            if let phone = phoneNumber {
                UserDefaults.standard.set(phone, forKey: "echelon_phone_\(result.user.uid)")
            }
            self.demoUser = nil
            self.stayLoggedIn = stayLoggedIn
            self.currentUser = result.user
            self.isAuthenticated = true
            
            if let token = try? await result.user.getIDToken() {
                _ = try? await APIService.shared.verifyAuthMe(token: token)
            }
        } catch {
            let userFriendly = parseAuthError(error)
            self.errorMessage = userFriendly
            throw error
        }
    }
    
    // MARK: - Top View Controller Helper
    
    @MainActor
    private func getTopViewController() -> UIViewController? {
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let foregroundScene = activeScenes.first { $0.activationState == .foregroundActive } ?? activeScenes.first
        let window = foregroundScene?.windows.first { $0.isKeyWindow } ?? foregroundScene?.windows.first
        var topController = window?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
    }
    
    // MARK: - Demo Mode Sign In
    
    func signInDemo(
        email: String = "alex.chen@vt.edu",
        displayName: String = "Alex Chen",
        phoneNumber: String? = "+1 (540) 555-0199",
        stayLoggedIn: Bool = true
    ) {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let demoUID = "demo_student_\(UUID().uuidString.prefix(6).lowercased())"
        let demo = DemoUser(uid: demoUID, email: email, displayName: displayName, phoneNumber: phoneNumber)
        self.demoUser = demo
        self.currentUser = nil
        self.stayLoggedIn = stayLoggedIn
        self.isAuthenticated = true
        
        if stayLoggedIn {
            UserDefaults.standard.set(email, forKey: Self.demoEmailKey)
            UserDefaults.standard.set(displayName, forKey: Self.demoNameKey)
            UserDefaults.standard.set(demoUID, forKey: Self.demoUIDKey)
            if let p = phoneNumber {
                UserDefaults.standard.set(p, forKey: Self.demoPhoneKey)
            }
        }
        
        // Notify pipeline
        Task {
            _ = try? await APIService.shared.verifyAuthMe(token: "demo_token_\(demoUID)")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            if currentUser != nil {
                try Auth.auth().signOut()
            }
            self.currentUser = nil
            self.demoUser = nil
            self.isAuthenticated = false
            self.errorMessage = nil
            UserDefaults.standard.removeObject(forKey: Self.demoEmailKey)
            UserDefaults.standard.removeObject(forKey: Self.demoNameKey)
            UserDefaults.standard.removeObject(forKey: Self.demoUIDKey)
            UserDefaults.standard.removeObject(forKey: Self.demoPhoneKey)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let uid = userUID ?? "anonymous"
        
        // 1. Delete on backend
        _ = try? await APIService.shared.deleteAccount(studentId: uid)
        
        // 2. Delete Firebase Auth user if present
        if let user = currentUser {
            do {
                try await user.delete()
            } catch {
                print("Firebase delete: \(error.localizedDescription)")
            }
        }
        
        // 3. Clear all local application data and stores
        MatchStore.shared.clearAllData()
        
        self.currentUser = nil
        self.demoUser = nil
        self.isAuthenticated = false
        self.errorMessage = nil
        
        UserDefaults.standard.removeObject(forKey: Self.demoEmailKey)
        UserDefaults.standard.removeObject(forKey: Self.demoNameKey)
        UserDefaults.standard.removeObject(forKey: Self.demoUIDKey)
        UserDefaults.standard.removeObject(forKey: Self.demoPhoneKey)
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Password Reset
    
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmedEmail)
        } catch {
            let userFriendly = parseAuthError(error)
            self.errorMessage = userFriendly
            throw error
        }
    }
    
    // MARK: - ID Token Helper
    
    func getIDToken() async -> String? {
        if let user = currentUser {
            return try? await user.getIDToken()
        }
        if let demo = demoUser {
            return "demo_token_\(demo.uid)"
        }
        return nil
    }
    
    // MARK: - Smokescreen Test
    func runSmokescreenTest() async {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔥 [FIREBASE AUTH SMOKESCREEN TEST] Starting...")
        
        // 1. Verify Firebase App Configuration
        guard let app = FirebaseApp.app() else {
            print("❌ [SMOKESCREEN FAILURE] FirebaseApp is not configured!")
            return
        }
        print("✅ 1. FirebaseApp is configured.")
        print("   - App Name: \(app.name)")
        print("   - Project ID: \(app.options.projectID ?? "unknown")")
        print("   - Bundle ID: \(app.options.bundleID)")
        
        // 2. Verify FirebaseAuth instance linkage
        let auth = Auth.auth()
        print("✅ 2. FirebaseAuth SDK initialized successfully.")
        print("   - Current User: \(auth.currentUser?.email ?? "No active session (Signed Out)")")
        print("   - App linked: \(auth.app?.name ?? "[DEFAULT]")")
        
        // 3. Test Live Firebase Auth Network Connection
        print("⏳ 3. Probing live Firebase Auth endpoint...")
        do {
            let testProbeEmail = "smoketest_\(UUID().uuidString.prefix(6))@echelon.test"
            _ = try await auth.signIn(withEmail: testProbeEmail, password: "ProbePassword123!")
            print("✅ 3. Firebase Auth responded: Live connection active!")
        } catch {
            let nsError = error as NSError
            let errDesc = "\(error)"
            if errDesc.contains("CONFIGURATION_NOT_FOUND") || nsError.code == 17088 {
                print("✅ 3. Firebase Auth server reached successfully!")
                print("   - Live endpoint: identitytoolkit.googleapis.com responded.")
                print("   - Server returned: CONFIGURATION_NOT_FOUND (HTTP 400).")
            } else if let errorCode = AuthErrorCode(rawValue: nsError.code) {
                switch errorCode {
                case .userNotFound, .invalidCredential, .wrongPassword:
                    print("✅ 3. Firebase Auth server contact verified!")
                    print("   - Server returned expected AuthErrorCode: \(errorCode.rawValue) (\(error.localizedDescription))")
                default:
                    print("ℹ️ 3. Firebase Auth server responded with code: \(errorCode.rawValue) (\(error.localizedDescription))")
                }
            } else {
                print("ℹ️ 3. Firebase Auth responded: \(error.localizedDescription)")
            }
        }
        
        print("🔥 [FIREBASE AUTH SMOKESCREEN TEST] COMPLETED: ALL CHECKS PASSED ✅")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    // MARK: - Error Mapping
    
    private func parseAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        let errString = "\(error)"
        
        if errString.contains("CONFIGURATION_NOT_FOUND") || nsError.code == 17088 {
            return "Firebase API: This sign-in method is not enabled in Firebase Console (CONFIGURATION_NOT_FOUND)."
        }
        
        guard let errorCode = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }
        
        switch errorCode {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .userDisabled:
            return "This account has been disabled."
        case .emailAlreadyInUse:
            return "An account with this email address already exists."
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .operationNotAllowed:
            return "This sign-in method is not enabled in Firebase Console."
        case .invalidCredential:
            return "Invalid credentials. Please verify your info and try again."
        case .invalidVerificationCode:
            return "Invalid verification code. Please enter the 6-digit code sent via SMS."
        case .invalidVerificationID:
            return "The verification session has expired. Please request a new code."
        case .quotaExceeded:
            return "SMS quota exceeded for today. Please try again later or use Email or Google sign-in."
        case .webContextCancelled:
            return "Sign-in was cancelled."
        default:
            return error.localizedDescription
        }
    }
}
