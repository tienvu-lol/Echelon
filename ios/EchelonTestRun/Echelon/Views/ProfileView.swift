import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSignOutAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Your student profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Profile Setup")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Upload your resume or fill in your details to get personalized opportunity recommendations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        if let name = authService.userDisplayName, !name.isEmpty {
                            ProfileField(label: "Name", value: name)
                        }
                        if let email = authService.userEmail {
                            ProfileField(label: "Email", value: email)
                        }
                        if let phone = authService.userPhoneNumber, !phone.isEmpty {
                            ProfileField(label: "Phone", value: phone)
                        }
                        ProfileField(label: "Major", value: "Not set")
                        ProfileField(label: "Graduation Year", value: "Not set")
                        ProfileField(label: "Skills", value: "None added")
                        ProfileField(label: "Interests", value: "None added")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Account & Sign Out Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Account Settings")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Stay Logged In")
                                .font(.subheadline)
                            Spacer()
                            Text(authService.stayLoggedIn ? "Enabled" : "Disabled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(role: .destructive, action: {
                            showSignOutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(10)
                        }
                        .padding(.top, 6)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct ProfileField: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
