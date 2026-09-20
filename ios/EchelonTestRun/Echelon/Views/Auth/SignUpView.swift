import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    var onNavigateToLogin: () -> Void
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var stayLoggedIn: Bool = true
    @State private var clientValidationMessage: String? = nil
    
    private var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            AuthBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Back button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(AppTheme.SwiftUIColors.glass)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                    
                    // Logo + Title & Subtitle
                    VStack(alignment: .leading, spacing: 14) {
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "#5AC8FA").opacity(0.5), Color(hex: "#0A84FF").opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.3), radius: 10, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                            
                            Text("Join Echelon to get matched with research, internships, and fellowships.")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.top, 2)
                    
                    // Error Banner
                    if let errorMessage = clientValidationMessage ?? authService.errorMessage {
                        AuthErrorBanner(message: errorMessage)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Form fields
                    VStack(spacing: 16) {
                        AuthTextField(
                            title: "Full Name",
                            placeholder: "Jane Doe",
                            text: $fullName,
                            icon: "person.fill",
                            autocapitalization: .words
                        )
                        
                        AuthTextField(
                            title: "University Email",
                            placeholder: "jane@university.edu",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                        
                        // Optional Phone Number Field
                        AuthTextField(
                            title: "Phone Number (Optional)",
                            placeholder: "+1 (555) 000-0000",
                            text: $phoneNumber,
                            icon: "phone.fill",
                            keyboardType: .phonePad
                        )
                        
                        AuthTextField(
                            title: "Password",
                            placeholder: "At least 6 characters",
                            text: $password,
                            icon: "lock.fill",
                            isSecure: true
                        )
                        
                        AuthTextField(
                            title: "Confirm Password",
                            placeholder: "Re-enter password",
                            text: $confirmPassword,
                            icon: "lock.shield.fill",
                            isSecure: true
                        )
                        
                        // Stay Logged In Toggle
                        StayLoggedInToggle(isOn: $stayLoggedIn)
                            .padding(.top, 4)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        AuthPrimaryButton(
                            title: "Create Account",
                            icon: "sparkles",
                            isLoading: authService.isLoading,
                            isEnabled: isFormValid
                        ) {
                            if password != confirmPassword {
                                clientValidationMessage = "Passwords do not match."
                                return
                            }
                            if password.count < 6 {
                                clientValidationMessage = "Password must be at least 6 characters."
                                return
                            }
                            
                            clientValidationMessage = nil
                            Task {
                                do {
                                    try await authService.signUp(
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                        password: password,
                                        displayName: fullName,
                                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                                        stayLoggedIn: stayLoggedIn
                                    )
                                } catch {
                                    // Error is managed by authService.errorMessage
                                }
                            }
                        }
                        
                        // Navigation to Log In
                        HStack {
                            Text("Already have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                            
                            Button(action: {
                                onNavigateToLogin()
                            }) {
                                Text("Log In")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SignUpView(onNavigateToLogin: {})
        .environmentObject(AuthService.shared)
        .preferredColorScheme(.dark)
}
