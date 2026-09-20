import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    var onNavigateToSignUp: () -> Void
    
    // Login Method
    @State private var selectedMethod: LoginMethod = .email
    
    // Email State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var stayLoggedIn: Bool = true
    @State private var showForgotPasswordAlert: Bool = false
    @State private var forgotPasswordEmail: String = ""
    @State private var showResetSuccessAlert: Bool = false
    
    // Phone State
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var verificationID: String? = nil
    @State private var isCodeSent: Bool = false
    
    private var isEmailFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    private var isPhoneSendValid: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isPhoneVerifyValid: Bool {
        isPhoneSendValid && !verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            AuthBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    // Back button & header row
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
                            Text("Welcome Back")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                            
                            Text("Sign in using your preferred method to access your account.")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.top, 2)
                    
                    // Method Selector (Email vs Phone)
                    AuthMethodSelector(selectedMethod: $selectedMethod)
                    
                    // Error Banner
                    if let errorMessage = authService.errorMessage {
                        AuthErrorBanner(message: errorMessage)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Form fields based on selected method
                    if selectedMethod == .email {
                        VStack(spacing: 16) {
                            AuthTextField(
                                title: "Email Address",
                                placeholder: "student@university.edu",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            
                            AuthTextField(
                                title: "Password",
                                placeholder: "••••••••",
                                text: $password,
                                icon: "lock.fill",
                                isSecure: true
                            )
                            
                            // Stay Logged In Toggle
                            StayLoggedInToggle(isOn: $stayLoggedIn)
                                .padding(.top, 4)
                            
                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button(action: {
                                    forgotPasswordEmail = email
                                    showForgotPasswordAlert = true
                                }) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                                }
                            }
                            .padding(.top, 2)
                            
                            // Log In Button
                            AuthPrimaryButton(
                                title: "Log In",
                                icon: "arrow.right",
                                isLoading: authService.isLoading,
                                isEnabled: isEmailFormValid
                            ) {
                                Task {
                                    do {
                                        try await authService.signIn(
                                            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                            password: password,
                                            stayLoggedIn: stayLoggedIn
                                        )
                                    } catch {
                                        // Error message handled in authService
                                    }
                                }
                            }
                        }
                    } else {
                        // Phone Login
                        VStack(spacing: 16) {
                            AuthTextField(
                                title: "Phone Number",
                                placeholder: "+1 (555) 000-0000",
                                text: $phoneNumber,
                                icon: "phone.fill",
                                keyboardType: .phonePad
                            )
                            
                            if isCodeSent {
                                AuthTextField(
                                    title: "Verification Code",
                                    placeholder: "6-digit SMS code",
                                    text: $verificationCode,
                                    icon: "lock.shield.fill",
                                    keyboardType: .numberPad
                                )
                                
                                HStack {
                                    Button(action: {
                                        withAnimation {
                                            isCodeSent = false
                                            verificationCode = ""
                                        }
                                    }) {
                                        Text("Change phone number")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppTheme.SwiftUIColors.cyan)
                                    }
                                    Spacer()
                                }
                                .padding(.top, 2)
                                
                                AuthPrimaryButton(
                                    title: "Verify & Log In",
                                    icon: "checkmark.shield.fill",
                                    isLoading: authService.isLoading,
                                    isEnabled: isPhoneVerifyValid
                                ) {
                                    guard let vid = verificationID else { return }
                                    Task {
                                        do {
                                            try await authService.signInWithPhoneCode(
                                                verificationID: vid,
                                                verificationCode: verificationCode,
                                                phoneNumber: phoneNumber,
                                                stayLoggedIn: stayLoggedIn
                                            )
                                        } catch {
                                            // Handled
                                        }
                                    }
                                }
                            } else {
                                AuthPrimaryButton(
                                    title: "Send Verification Code",
                                    icon: "paperplane.fill",
                                    isLoading: authService.isLoading,
                                    isEnabled: isPhoneSendValid
                                ) {
                                    Task {
                                        do {
                                            let vid = try await authService.sendPhoneVerificationCode(phoneNumber: phoneNumber)
                                            withAnimation {
                                                self.verificationID = vid
                                                self.isCodeSent = true
                                            }
                                        } catch {
                                            // Handled
                                        }
                                    }
                                }
                            }
                            
                            StayLoggedInToggle(isOn: $stayLoggedIn)
                                .padding(.top, 4)
                        }
                    }
                    
                    // Navigation to Sign Up
                    HStack {
                        Text("Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                        
                        Button(action: {
                            onNavigateToSignUp()
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("Reset Password", isPresented: $showForgotPasswordAlert) {
            TextField("Enter your email", text: $forgotPasswordEmail)
                .textInputAutocapitalization(.never)
            Button("Send Link") {
                Task {
                    do {
                        try await authService.sendPasswordReset(email: forgotPasswordEmail)
                        showResetSuccessAlert = true
                    } catch {
                        // Handled
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("We'll send a password reset link to your email address.")
        }
        .alert("Email Sent", isPresented: $showResetSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your email inbox for instructions to reset your password.")
        }
    }
}

#Preview {
    LoginView(onNavigateToSignUp: {})
        .environmentObject(AuthService.shared)
        .preferredColorScheme(.dark)
}
