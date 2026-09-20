import SwiftUI

struct AuthLandingView: View {
    @EnvironmentObject var authService: AuthService
    
    enum AuthScreen: Hashable {
        case login
        case signUp
    }
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                AuthBackground()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Hero Branding Section
                    VStack(spacing: 20) {
                        // Glowing App Icon Emblem with official Echelon Logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.SwiftUIColors.blue.opacity(0.35), AppTheme.SwiftUIColors.cyan.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 112, height: 112)
                                .blur(radius: 18)
                            
                            Image("AppLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 92, height: 92)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(hex: "#5AC8FA").opacity(0.6), Color(hex: "#0A84FF").opacity(0.25)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.4), radius: 20, x: 0, y: 8)
                        }
                        .padding(.bottom, 8)
                        
                        // App Name
                        VStack(spacing: 8) {
                            Text("ECHELON")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .tracking(4)
                                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                            
                            Text("Campus opportunities & research\ntailored just for you")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    Spacer()
                    
                    // Feature highlights pill
                    VStack(alignment: .leading, spacing: 12) {
                        LandingFeatureRow(icon: "sparkle.magnifyingglass", title: "AI-Powered Matching", description: "Opportunities tailored to your major & skills")
                        LandingFeatureRow(icon: "hand.draw.fill", title: "Swipe Discovery", description: "Browse verified research, internships & REUs")
                        LandingFeatureRow(icon: "bookmark.fill", title: "Track & Apply", description: "Save matches and manage your application cycle")
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.r22)
                            .fill(AppTheme.SwiftUIColors.glass.opacity(0.7))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radii.r22)
                            .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Auth Actions
                    VStack(spacing: 12) {
                        if let errorMessage = authService.errorMessage {
                            AuthErrorBanner(message: errorMessage)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Continue with Google
                        GoogleSignInButton(isLoading: authService.isLoading) {
                            Task {
                                do {
                                    try await authService.signInWithGoogle()
                                } catch {
                                    // Managed by authService.errorMessage
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Rectangle().fill(AppTheme.SwiftUIColors.border).frame(height: 1)
                            Text("OR")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                            Rectangle().fill(AppTheme.SwiftUIColors.border).frame(height: 1)
                        }
                        .padding(.vertical, 2)
                        
                        // Option 1: Sign Up
                        AuthPrimaryButton(
                            title: "Sign Up",
                            icon: "person.badge.plus"
                        ) {
                            navigationPath.append(AuthScreen.signUp)
                        }
                        
                        // Option 2: Log In
                        AuthSecondaryButton(
                            title: "Log In",
                            icon: "arrow.right.circle"
                        ) {
                            navigationPath.append(AuthScreen.login)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(for: AuthScreen.self) { screen in
                switch screen {
                case .login:
                    LoginView(onNavigateToSignUp: {
                        navigationPath.removeLast()
                        navigationPath.append(AuthScreen.signUp)
                    })
                    .environmentObject(authService)
                case .signUp:
                    SignUpView(onNavigateToLogin: {
                        navigationPath.removeLast()
                        navigationPath.append(AuthScreen.login)
                    })
                    .environmentObject(authService)
                }
            }
        }
    }
}

// MARK: - Landing Feature Row
private struct LandingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.SwiftUIColors.blue.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AuthLandingView()
        .environmentObject(AuthService.shared)
        .preferredColorScheme(.dark)
}
