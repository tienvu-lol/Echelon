import SwiftUI

// MARK: - Ambient Background
struct AuthBackground: View {
    var body: some View {
        ZStack {
            AppTheme.SwiftUIColors.background
                .ignoresSafeArea()
            
            // Subtle ambient glows
            GeometryReader { proxy in
                Circle()
                    .fill(AppTheme.SwiftUIColors.blue.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: -80, y: -100)
                
                Circle()
                    .fill(AppTheme.SwiftUIColors.cyan.opacity(0.14))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: proxy.size.width - 160, y: proxy.size.height * 0.4)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Auth Text Field
struct AuthTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    
    @State private var isPasswordVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isFocused ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.textTertiary)
                    .frame(width: 20)
                
                Group {
                    if isSecure && !isPasswordVisible {
                        SecureField(placeholder, text: $text)
                            .textContentType(textContentType)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled(true)
                            .textContentType(textContentType)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                .focused($isFocused)
                
                if isSecure {
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .fill(AppTheme.SwiftUIColors.glass.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .stroke(
                        isFocused ? AppTheme.SwiftUIColors.blue.opacity(0.8) : AppTheme.SwiftUIColors.border,
                        lineWidth: isFocused ? 1.5 : 1.0
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Stay Logged In Toggle
struct StayLoggedInToggle: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isOn ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.glass)
                        .frame(width: 22, height: 22)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isOn ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.border, lineWidth: 1.2)
                        .frame(width: 22, height: 22)
                    
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stay logged in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    
                    Text("Keep me signed in on this device")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary Button
struct AuthPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if !isLoading && isEnabled {
                action()
            }
        }) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: isEnabled
                        ? [Color(hex: "#0A84FF"), Color(hex: "#005bb5")]
                        : [Color(hex: "#2C3440"), Color(hex: "#1E242C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .stroke(
                        isEnabled ? Color.white.opacity(0.18) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isEnabled ? AppTheme.SwiftUIColors.blue.opacity(0.35) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

// MARK: - Secondary Button
struct AuthSecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .fill(AppTheme.SwiftUIColors.glass.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Login Method Selector
enum LoginMethod: String, CaseIterable {
    case email = "Email"
    case phone = "Phone"
}

struct AuthMethodSelector: View {
    @Binding var selectedMethod: LoginMethod
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(LoginMethod.allCases, id: \.self) { method in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedMethod = method
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: method == .email ? "envelope.fill" : "phone.fill")
                            .font(.system(size: 13, weight: .medium))
                        Text(method.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selectedMethod == method ? .white : AppTheme.SwiftUIColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        selectedMethod == method
                            ? AppTheme.SwiftUIColors.blue
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(AppTheme.SwiftUIColors.glass.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Google Sign In Button
struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
            
            Text("G")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#4285F4"), Color(hex: "#EA4335"), Color(hex: "#FBBC05"), Color(hex: "#34A853")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct GoogleSignInButton: View {
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.85)
                } else {
                    GoogleLogoView()
                    Text("Continue with Google")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .fill(AppTheme.SwiftUIColors.glass.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16)
                    .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Error Banner
struct AuthErrorBanner: View {
    let message: String?
    
    var body: some View {
        if let message = message, !message.isEmpty {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.SwiftUIColors.red)
                    .font(.system(size: 15))
                    .padding(.top, 1)
                
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.red)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r12)
                    .fill(AppTheme.SwiftUIColors.red.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r12)
                    .stroke(AppTheme.SwiftUIColors.red.opacity(0.35), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}
