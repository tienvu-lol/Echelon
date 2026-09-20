import SwiftUI
import UniformTypeIdentifiers

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
    
    // Delete Account Confirmation Alert
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
                        
                        // Destructive Zone: Delete Account
                        destructiveCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
                
                if showSavedToast {
                    VStack {
                        Spacer()
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
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)
                    .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.4), radius: 10, x: 0, y: 4)
                
                let initial = String(name.prefix(1)).uppercased()
                Text(initial.isEmpty ? "S" : initial)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Logged in as \(AuthService.shared.userEmail ?? matchStore.studentProfile.email ?? "Alex Chen")")
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
                formRow(title: "GPA", text: $gpa, placeholder: "3.90")
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Bio / Summary")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                TextEditor(text: $bio)
                    .frame(height: 70)
                    .padding(8)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r12))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r12).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
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
            Text("Skills & Coursework")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            // Skills
            VStack(alignment: .leading, spacing: 8) {
                Text("Skills (Tap × to remove)")
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
                    TextField("Add skill (e.g. PyTorch)...", text: $newSkillInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button("Add") {
                        let trimmed = newSkillInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !skills.contains(trimmed) {
                            skills.append(trimmed)
                            newSkillInput = ""
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                }
            }
            
            Divider().background(AppTheme.SwiftUIColors.border)
            
            // Coursework
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
                    TextField("Add course (e.g. Operating Systems)...", text: $newCourseInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button("Add") {
                        let trimmed = newCourseInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !coursework.contains(trimmed) {
                            coursework.append(trimmed)
                            newCourseInput = ""
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.blue)
                }
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Experience Card
    private var experienceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Experience & Projects")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            VStack(spacing: 8) {
                ForEach(experience, id: \.self) { exp in
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        Text(exp)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        Spacer()
                        Button(action: {
                            experience.removeAll { $0 == exp }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                        }
                    }
                    .padding(10)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            HStack {
                TextField("Add experience (e.g. SWE Intern @ Meta)...", text: $newExperienceInput)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color(hex: "#0E131E"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Button("Add") {
                    let trimmed = newExperienceInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && !experience.contains(trimmed) {
                        experience.append(trimmed)
                        newExperienceInput = ""
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.SwiftUIColors.cyan)
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Preferences Card
    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Work & Location Preferences")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            // Work Modes
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Modes")
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
                            Text(mode)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isSelected ? .white : AppTheme.SwiftUIColors.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(isSelected ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.pillBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isSelected ? AppTheme.SwiftUIColors.blue : AppTheme.SwiftUIColors.border, lineWidth: 1))
                        }
                    }
                }
            }
            
            // Desired Compensation
            formRow(title: "Target Compensation", text: $compensation, placeholder: "e.g. $45/hr+ or $9,000/mo")
            
            // Preferred Locations
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Locations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(locationPreferences, id: \.self) { loc in
                        removableTag(text: loc, color: AppTheme.SwiftUIColors.purple) {
                            locationPreferences.removeAll { $0 == loc }
                        }
                    }
                }
                
                HStack {
                    TextField("Add location (e.g. San Francisco, CA)...", text: $newLocationInput)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button("Add") {
                        let trimmed = newLocationInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !locationPreferences.contains(trimmed) {
                            locationPreferences.append(trimmed)
                            newLocationInput = ""
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.purple)
                }
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Resume Card
    private var resumeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resume & Documents")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(resumeFileName.isEmpty ? "No Resume Attached" : resumeFileName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    
                    Text(resumeFileName.isEmpty ? "Upload a PDF to parse and auto-match" : "Attached to your applicant profile")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    showDocumentPicker = true
                }) {
                    Text(resumeFileName.isEmpty ? "Upload" : "Replace")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.SwiftUIColors.cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(Color(hex: "#0E131E"))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r12))
            
            if isParsingResume {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Parsing resume via backend...")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Destructive Card (Delete Account)
    private var destructiveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Danger Zone")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.red)
            
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
                .frame(height: 46)
                .background(AppTheme.SwiftUIColors.red)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r12))
            }
            .disabled(isDeletingAccount)
        }
        .padding(16)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.red.opacity(0.4), lineWidth: 1))
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
        name = p.name ?? AuthService.shared.userDisplayName ?? "Alex Chen"
        university = p.university ?? "Virginia Tech"
        major = p.major
        minor = p.minor ?? ""
        graduationYear = "\(p.graduationYear)"
        gpa = p.gpa != nil ? String(format: "%.2f", p.gpa!) : "3.90"
        bio = p.bio ?? ""
        compensation = p.compensationPreference ?? "$45/hr+"
        skills = p.skills
        coursework = p.coursework
        experience = p.experience
        locationPreferences = p.locationPreferences
        selectedWorkModes = Set(p.workModePreferences)
        resumeFileName = p.resume?.fileName ?? "Alex_Chen_Resume_2027.pdf"
    }
    
    private func saveProfile() {
        var updated = matchStore.studentProfile
        updated.name = name
        updated.university = university
        updated.major = major
        updated.minor = minor.isEmpty ? nil : minor
        updated.graduationYear = Int(graduationYear) ?? 2027
        updated.gpa = Double(gpa)
        updated.bio = bio
        updated.compensationPreference = compensation
        updated.skills = skills
        updated.coursework = coursework
        updated.experience = experience
        updated.locationPreferences = locationPreferences
        updated.workModePreferences = Array(selectedWorkModes)
        if !resumeFileName.isEmpty {
            updated.resume = Resume(fileName: resumeFileName)
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
