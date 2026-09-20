import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

public struct ProfileSettingsView: View {
    @ObservedObject private var matchStore = MatchStore.shared
    @Environment(\.dismiss) private var dismiss
    
    // Editable Fields
    @State private var name: String = ""
    @State private var university: String = ""
    @State private var major: String = ""
    @State private var minor: String = ""
    @State private var graduationYear: String = ""
    @State private var gpa: String = ""
    @State private var compensation: String = ""
    @State private var bio: String = ""
    
    // Profile Picture Add / Remove
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var profilePictureUrl: String? = nil
    
    // Arrays
    @State private var skills: [String] = []
    @State private var newSkillInput: String = ""
    @State private var coursework: [String] = []
    @State private var newCourseInput: String = ""
    @State private var experience: [String] = []
    @State private var newExperienceInput: String = ""
    @State private var locationPreferences: [String] = []
    @State private var newLocationInput: String = ""
    
    // Work mode choices
    let allWorkModes = ["In-Person", "Hybrid", "Remote"]
    @State private var selectedWorkModes: Set<String> = []
    
    // Document Picker for Resume
    @State private var showDocumentPicker: Bool = false
    @State private var resumeFileName: String = ""
    @State private var isParsingResume: Bool = false
    
    // Alerts & Confirmations
    @State private var showSignOutAlert: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showSavedToast: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                AppTheme.SwiftUIColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Avatar Section
                        avatarSection
                        
                        // Basic Info Section
                        basicInfoCard
                        
                        // Skills & Coursework Section
                        skillsAndCourseworkCard
                        
                        // Experience Section
                        experienceCard
                        
                        // Preferences & Work Mode Card
                        preferencesCard
                        
                        // Resume Card
                        resumeCard
                        
                        // Destructive Zone: Sign Out & Delete Account
                        destructiveCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
                
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.SwiftUIColors.green)
                        Text("Profile changes saved!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#1A2230"))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Edit Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.blue)
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    handleResumePicked(url: url)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    AuthService.shared.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Permanently", role: .destructive) {
                    performDeleteAccount()
                }
            } message: {
                Text("Are you sure you want to permanently delete your account? All your matches, applications, and saved preferences will be erased. This action cannot be undone.")
            }
            .onAppear {
                loadProfileData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Avatar Section (Add / Remove Profile Picture)
    private var avatarSection: some View {
        VStack(spacing: 14) {
            ZStack {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.SwiftUIColors.cyan, lineWidth: 2))
                } else if let picUrl = profilePictureUrl, !picUrl.isEmpty {
                    RemoteImageView(urlString: picUrl, fallbackSystemName: "person.crop.circle.fill", contentMode: .fill)
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.SwiftUIColors.cyan, lineWidth: 2))
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    let initial = String((name.isEmpty ? (AuthService.shared.userDisplayName ?? "S") : name).prefix(1)).uppercased()
                    Text(initial.isEmpty ? "S" : initial)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Photo Actions: Add / Change & Remove Buttons
            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                        Text(profilePictureUrl != nil || avatarImage != nil ? "Change Photo" : "Add Photo")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppTheme.SwiftUIColors.blue)
                    .clipShape(Capsule())
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                self.avatarImage = uiImage
                                if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                                    let fileURL = docs.appendingPathComponent("avatar_\(UUID().uuidString).jpg")
                                    if (try? data.write(to: fileURL)) != nil {
                                        self.profilePictureUrl = fileURL.absoluteString
                                        self.matchStore.studentProfile.profilePictureUrl = fileURL.absoluteString
                                        self.matchStore.saveState()
                                    }
                                }
                            }
                        }
                    }
                }
                
                if profilePictureUrl != nil || avatarImage != nil {
                    Button(role: .destructive, action: {
                        self.avatarImage = nil
                        self.profilePictureUrl = nil
                        self.selectedPhotoItem = nil
                        self.matchStore.studentProfile.profilePictureUrl = nil
                        self.matchStore.saveState()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("Remove Photo")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.SwiftUIColors.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.SwiftUIColors.red.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.red.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            
            Text("Logged in as \(AuthService.shared.userEmail ?? matchStore.studentProfile.email ?? "Student")")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Basic Info Card
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Education & Identity")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            formRow(title: "Full Name", text: $name, placeholder: "e.g. Samuel Kang")
            formRow(title: "University / School", text: $university, placeholder: "e.g. Virginia Tech")
            formRow(title: "Major", text: $major, placeholder: "e.g. Computer Science")
            formRow(title: "Minor (Optional)", text: $minor, placeholder: "e.g. Mathematics")
            
            HStack(spacing: 12) {
                formRow(title: "Grad Year", text: $graduationYear, placeholder: "2027")
                formRow(title: "GPA", text: $gpa, placeholder: "3.80")
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bio & Elevator Pitch")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                TextEditor(text: $bio)
                    .frame(height: 80)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                    .font(.system(size: 14))
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Skills & Coursework Card
    private var skillsAndCourseworkCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skills & Technical Depth")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            // Skills Flow
            VStack(alignment: .leading, spacing: 8) {
                Text("Skills")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(skills, id: \.self) { skill in
                        removableTag(text: skill, color: AppTheme.SwiftUIColors.cyan) {
                            skills.removeAll { $0 == skill }
                        }
                    }
                }
                
                HStack {
                    TextField("Add skill (e.g. Rust, PyTorch)", text: $newSkillInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                        .onSubmit { addSkill() }
                    
                    Button("Add") { addSkill() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        .disabled(newSkillInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            
            Divider().background(AppTheme.SwiftUIColors.border)
            
            // Coursework Flow
            VStack(alignment: .leading, spacing: 8) {
                Text("Relevant Coursework")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(coursework, id: \.self) { course in
                        removableTag(text: course, color: AppTheme.SwiftUIColors.blue) {
                            coursework.removeAll { $0 == course }
                        }
                    }
                }
                
                HStack {
                    TextField("Add coursework (e.g. CS 3114)", text: $newCourseInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                        .onSubmit { addCourse() }
                    
                    Button("Add") { addCourse() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.blue)
                        .disabled(newCourseInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private func addSkill() {
        let trimmed = newSkillInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !skills.contains(trimmed) else { return }
        skills.append(trimmed)
        newSkillInput = ""
    }
    
    private func addCourse() {
        let trimmed = newCourseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !coursework.contains(trimmed) else { return }
        coursework.append(trimmed)
        newCourseInput = ""
    }
    
    // MARK: - Experience Card
    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Past Experience & Projects")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(experience, id: \.self) { exp in
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        Text(exp)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        Spacer()
                        Button(action: {
                            experience.removeAll { $0 == exp }
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.SwiftUIColors.red)
                        }
                    }
                    .padding(8)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            HStack {
                TextField("Add experience (e.g. ML Intern @ XYZ)", text: $newExperienceInput)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                    .onSubmit { addExperience() }
                
                Button("Add") { addExperience() }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                    .disabled(newExperienceInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private func addExperience() {
        let trimmed = newExperienceInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !experience.contains(trimmed) else { return }
        experience.append(trimmed)
        newExperienceInput = ""
    }
    
    // MARK: - Preferences & Work Modes Card
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Work & Location Preferences")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            formRow(title: "Target Compensation", text: $compensation, placeholder: "e.g. $40/hr+ or Competitive")
            
            // Work Mode Multi-Select
            VStack(alignment: .leading, spacing: 6) {
                Text("Preferred Work Modes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                HStack(spacing: 8) {
                    ForEach(allWorkModes, id: \.self) { mode in
                        let isSelected = selectedWorkModes.contains(mode)
                        Button(action: {
                            if isSelected {
                                selectedWorkModes.remove(mode)
                            } else {
                                selectedWorkModes.insert(mode)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 11))
                                Text(mode)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .white : AppTheme.SwiftUIColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSelected ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.pillBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.border, lineWidth: 1))
                        }
                    }
                }
            }
            
            // Locations
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Locations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(locationPreferences, id: \.self) { loc in
                        removableTag(text: loc, color: AppTheme.SwiftUIColors.yellow) {
                            locationPreferences.removeAll { $0 == loc }
                        }
                    }
                }
                
                HStack {
                    TextField("Add location (e.g. Blacksburg, VA)", text: $newLocationInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                        .onSubmit { addLocation() }
                    
                    Button("Add") { addLocation() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.yellow)
                        .disabled(newLocationInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private func addLocation() {
        let trimmed = newLocationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !locationPreferences.contains(trimmed) else { return }
        locationPreferences.append(trimmed)
        newLocationInput = ""
    }
    
    // MARK: - Resume Card
    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resume Document")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(resumeFileName.isEmpty ? "No resume attached" : resumeFileName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(resumeFileName.isEmpty ? AppTheme.SwiftUIColors.textSecondary : AppTheme.SwiftUIColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(isParsingResume ? "AI parsing in progress..." : "Upload a PDF resume to auto-fill profile details")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(hex: "#0E131E"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            HStack(spacing: 10) {
                Button(action: {
                    showDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text(resumeFileName.isEmpty ? "Upload PDF" : "Replace Resume")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(AppTheme.SwiftUIColors.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if !resumeFileName.isEmpty {
                    Button(role: .destructive, action: {
                        resumeFileName = ""
                        matchStore.studentProfile.resume = nil
                        matchStore.saveState()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(AppTheme.SwiftUIColors.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.red.opacity(0.3), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Destructive Actions (Sign Out & Delete Account)
    private var destructiveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account Actions")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            // Sign Out Button
            Button(action: {
                showSignOutAlert = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppTheme.SwiftUIColors.yellow)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.SwiftUIColors.yellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r12))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r12).stroke(AppTheme.SwiftUIColors.yellow.opacity(0.3), lineWidth: 1))
            }
            
            Divider().background(AppTheme.SwiftUIColors.border).padding(.vertical, 4)
            
            Text("Permanently delete your account and all associated applications, matches, and profile data.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    if isDeletingAccount {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "trash.fill")
                        Text("Delete Account Permanently")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(AppTheme.SwiftUIColors.red)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r12))
            }
            .disabled(isDeletingAccount)
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Helpers
    private func formRow(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .padding(10)
                .background(Color(hex: "#0E131E"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    private func removableTag(text: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 5) {
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 1))
    }
    
    // MARK: - Profile Load & Save
    private func loadProfileData() {
        let p = matchStore.studentProfile
        name = p.name ?? AuthService.shared.userDisplayName ?? ""
        university = p.university ?? "Virginia Tech"
        major = p.major
        minor = p.minor ?? ""
        graduationYear = p.graduationYear > 0 ? "\(p.graduationYear)" : "2027"
        gpa = p.gpa != nil ? String(format: "%.2f", p.gpa!) : "3.80"
        bio = p.bio ?? ""
        compensation = p.compensationPreference ?? ""
        skills = p.skills
        coursework = p.coursework
        experience = p.experience
        locationPreferences = p.locationPreferences
        selectedWorkModes = Set(p.workModePreferences)
        resumeFileName = p.resume?.fileName ?? ""
        profilePictureUrl = p.profilePictureUrl
        
        if let picUrl = p.profilePictureUrl, let url = URL(string: picUrl), url.isFileURL {
            avatarImage = UIImage(contentsOfFile: url.path)
        }
    }
    
    private func saveProfile() {
        var updated = matchStore.studentProfile
        updated.name = name.isEmpty ? nil : name
        updated.university = university
        updated.major = major
        updated.minor = minor.isEmpty ? nil : minor
        updated.graduationYear = Int(graduationYear) ?? 2027
        updated.gpa = Double(gpa)
        updated.bio = bio.isEmpty ? nil : bio
        updated.compensationPreference = compensation.isEmpty ? nil : compensation
        updated.skills = skills
        updated.coursework = coursework
        updated.experience = experience
        updated.locationPreferences = locationPreferences
        updated.workModePreferences = Array(selectedWorkModes)
        updated.profilePictureUrl = profilePictureUrl
        if !resumeFileName.isEmpty {
            updated.resume = Resume(fileName: resumeFileName)
        } else {
            updated.resume = nil
        }
        
        matchStore.updateProfile(updated)
        
        Task {
            _ = try? await APIService.shared.updateStudentProfile(studentId: updated.id, profile: updated)
        }
        
        withAnimation {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
    
    private func handleResumePicked(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileName = url.lastPathComponent
        self.resumeFileName = fileName
        
        guard let data = try? Data(contentsOf: url) else { return }
        self.isParsingResume = true
        
        Task {
            do {
                let parsed = try await APIService.shared.parseResume(pdfData: data, fileName: fileName)
                await MainActor.run {
                    self.isParsingResume = false
                    if let parsedName = parsed.name, !parsedName.isEmpty { self.name = parsedName }
                    if let parsedUni = parsed.university, !parsedUni.isEmpty { self.university = parsedUni }
                    if let parsedMajor = parsed.major, !parsedMajor.isEmpty { self.major = parsedMajor }
                    if let parsedGrad = parsed.graduationYear { self.graduationYear = "\(parsedGrad)" }
                    if let parsedSkills = parsed.skills, !parsedSkills.isEmpty { self.skills = parsedSkills }
                    if let parsedCourse = parsed.coursework, !parsedCourse.isEmpty { self.coursework = parsedCourse }
                    if let parsedExp = parsed.experience, !parsedExp.isEmpty { self.experience = parsedExp }
                }
            } catch {
                await MainActor.run {
                    self.isParsingResume = false
                }
            }
        }
    }
    
    private func performDeleteAccount() {
        isDeletingAccount = true
        
        Task {
            do {
                try await AuthService.shared.deleteAccount()
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
