import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var matchStore = MatchStore.shared
    
    // Step index: 1 to 6
    @State private var currentStep: Int = 1
    private let totalSteps = 6
    
    // Step 1: Resume Upload & Parsing
    @State private var showDocumentPicker: Bool = false
    @State private var uploadedFileName: String? = nil
    @State private var uploadedFileData: Data? = nil
    @State private var isParsingResume: Bool = false
    @State private var parsedResumeData: ParsedResumeData? = nil
    @State private var showParsedDecisionPrompt: Bool = false
    
    // Step 2: Education
    @State private var name: String = ""
    @State private var university: String = ""
    @State private var degree: String = ""
    @State private var major: String = ""
    @State private var minor: String = ""
    @State private var graduationYear: String = ""
    @State private var gpa: String = ""
    
    // Step 3: Coursework
    @State private var coursework: [String] = []
    @State private var newCourseInput: String = ""
    
    // Step 4: Skills
    @State private var skills: [String] = []
    @State private var newSkillInput: String = ""
    
    // Step 5: Experience
    @State private var experiences: [String] = []
    @State private var newExperienceInput: String = ""
    
    // Step 6: Preferences
    @State private var selectedWorkModes: Set<String> = []
    let allWorkModes = ["In-Person", "Hybrid", "Remote"]
    @State private var locationPreferences: [String] = []
    @State private var newLocationInput: String = ""
    @State private var compensationTarget: String = ""
    
    // Saving state & Error Handling
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    
    var body: some View {
        ZStack {
            AppTheme.SwiftUIColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Progress Bar
                onboardingHeader
                
                // Content per step
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        switch currentStep {
                        case 1:
                            step1ResumeUpload
                        case 2:
                            step2Education
                        case 3:
                            step3Coursework
                        case 4:
                            step4Skills
                        case 5:
                            step5Experience
                        case 6:
                            step6Preferences
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                
                // Bottom Floating Navigation
                bottomNavigation
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { url in
                handleResumeUploaded(url: url)
            }
        }
        .onAppear {
            if let userDisp = AuthService.shared.userDisplayName, !userDisp.isEmpty {
                self.name = userDisp
            }
        }
        .alert("Unable to Complete Onboarding", isPresented: $showErrorAlert) {
            Button("Continue Offline") {
                skipOnboarding()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred while saving your profile.")
        }
    }
    
    // MARK: - Header
    private var onboardingHeader: some View {
        VStack(spacing: 12) {
            HStack {
                if currentStep > 1 {
                    Button(action: {
                        withAnimation {
                            currentStep -= 1
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                    }
                } else {
                    Spacer().frame(width: 24)
                }
                
                Spacer()
                
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                
                Spacer()
                
                HStack(spacing: 12) {
                    if currentStep < totalSteps {
                        Button("Skip") {
                            goToNextStep()
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                    }
                    
                    Button("Skip All") {
                        skipOnboarding()
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Progress Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#161D2A"))
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)), height: 5)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Step 1: Resume Upload
    private var step1ResumeUpload: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "doc.text.fill",
                title: "Upload Your Resume",
                subtitle: "We'll parse your skills, education, and experiences to find the best opportunities."
            )
            
            // Upload Box
            VStack(spacing: 16) {
                if let fileName = uploadedFileName {
                    VStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppTheme.SwiftUIColors.green)
                        
                        Text(fileName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        
                        Button("Upload Different File") {
                            showDocumentPicker = true
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                    }
                    .padding(24)
                } else {
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        VStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.SwiftUIColors.blue.opacity(0.15))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "arrow.up.doc.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                                )
                            
                            Text("Tap to select PDF resume")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                            
                            Text("Supports standard PDF files up to 10MB")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r22))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r22)
                    .stroke(
                        uploadedFileName != nil ? AppTheme.SwiftUIColors.green.opacity(0.5) : AppTheme.SwiftUIColors.border,
                        style: StrokeStyle(lineWidth: 1.5, dash: uploadedFileName != nil ? [] : [6, 4])
                    )
            )
            
            // Parsing Loading Indicator
            if isParsingResume {
                HStack(spacing: 10) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.SwiftUIColors.cyan))
                    Text("Analyzing resume and extracting experience...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(AppTheme.SwiftUIColors.glass)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Extracted Info Decision Prompt
            if showParsedDecisionPrompt, let parsed = parsedResumeData {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        Text("Resume Information Extracted")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let n = parsed.name { Text("• Name: \(n)").font(.system(size: 12.5)).foregroundColor(AppTheme.SwiftUIColors.textSecondary) }
                        if let u = parsed.university { Text("• School: \(u)").font(.system(size: 12.5)).foregroundColor(AppTheme.SwiftUIColors.textSecondary) }
                        if let m = parsed.major { Text("• Major: \(m)").font(.system(size: 12.5)).foregroundColor(AppTheme.SwiftUIColors.textSecondary) }
                        if let sk = parsed.skills, !sk.isEmpty { Text("• Skills: \(sk.prefix(4).joined(separator: ", "))").font(.system(size: 12.5)).foregroundColor(AppTheme.SwiftUIColors.textSecondary) }
                    }
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            applyParsedDataToFields(parsed)
                            showParsedDecisionPrompt = false
                            goToNextStep()
                        }) {
                            Text("Fill My Profile")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(AppTheme.SwiftUIColors.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        Button(action: {
                            showParsedDecisionPrompt = false
                            goToNextStep()
                        }) {
                            Text("I'll Enter It Myself")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#1A2230"))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#101622"))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r18))
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r18).stroke(AppTheme.SwiftUIColors.cyan.opacity(0.4), lineWidth: 1))
            }
        }
    }
    
    // MARK: - Step 2: Education
    private var step2Education: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "graduationcap.fill",
                title: "Education & Degree",
                subtitle: "Tell us about your university, major, and graduation timeline."
            )
            
            VStack(spacing: 14) {
                fieldInput(title: "Full Name", text: $name, placeholder: "e.g. Samuel Kang")
                fieldInput(title: "University", text: $university, placeholder: "e.g. Virginia Tech")
                fieldInput(title: "Major", text: $major, placeholder: "e.g. Computer Science")
                fieldInput(title: "Minor (Optional)", text: $minor, placeholder: "e.g. Mathematics")
                
                HStack(spacing: 12) {
                    fieldInput(title: "Graduation Year", text: $graduationYear, placeholder: "2027")
                    fieldInput(title: "GPA", text: $gpa, placeholder: "3.85")
                }
            }
            .padding(18)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    // MARK: - Step 3: Coursework
    private var step3Coursework: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "books.vertical.fill",
                title: "Relevant Coursework",
                subtitle: "Add courses you have taken or are currently enrolled in."
            )
            
            VStack(alignment: .leading, spacing: 14) {
                FlowLayout(spacing: 8) {
                    ForEach(coursework, id: \.self) { item in
                        HStack(spacing: 6) {
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.SwiftUIColors.blue)
                            Button(action: { coursework.removeAll { $0 == item } }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.SwiftUIColors.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.SwiftUIColors.blue.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.blue.opacity(0.35), lineWidth: 1))
                    }
                }
                
                HStack {
                    TextField("Add course (e.g. Machine Learning)...", text: $newCourseInput)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit { addCourse() }
                    
                    Button("Add") { addCourse() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.SwiftUIColors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    // MARK: - Step 4: Skills
    private var step4Skills: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "hammer.fill",
                title: "Skills & Frameworks",
                subtitle: "Select technical and domain skills to match with role requirements."
            )
            
            VStack(alignment: .leading, spacing: 14) {
                FlowLayout(spacing: 8) {
                    ForEach(skills, id: \.self) { item in
                        HStack(spacing: 6) {
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.SwiftUIColors.cyan)
                            Button(action: { skills.removeAll { $0 == item } }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.SwiftUIColors.cyan.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.cyan.opacity(0.35), lineWidth: 1))
                    }
                }
                
                HStack {
                    TextField("Add skill (e.g. PyTorch, React, Go)...", text: $newSkillInput)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit { addSkill() }
                    
                    Button("Add") { addSkill() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.SwiftUIColors.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    // MARK: - Step 5: Experience
    private var step5Experience: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "briefcase.fill",
                title: "Experience & Projects",
                subtitle: "Highlight previous internships, campus research, or key projects."
            )
            
            VStack(alignment: .leading, spacing: 14) {
                if experiences.isEmpty {
                    Text("No experience added yet. Add a few highlights below or skip.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(experiences, id: \.self) { exp in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.SwiftUIColors.green)
                                Text(exp)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                                Spacer()
                                Button(action: { experiences.removeAll { $0 == exp } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                                }
                            }
                            .padding(10)
                            .background(Color(hex: "#0E131E"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                HStack {
                    TextField("e.g. Undergraduate Research Assistant @ CV Lab...", text: $newExperienceInput)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Color(hex: "#0E131E"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onSubmit { addExperience() }
                    
                    Button("Add") { addExperience() }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppTheme.SwiftUIColors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(18)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    // MARK: - Step 6: Preferences
    private var step6Preferences: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(
                icon: "slider.horizontal.3",
                title: "Interests & Work Mode",
                subtitle: "Set your work style, target locations, and compensation."
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Work Modes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Work Mode")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    
                    HStack(spacing: 8) {
                        ForEach(allWorkModes, id: \.self) { mode in
                            let isSelected = selectedWorkModes.contains(mode)
                            Button(action: {
                                if isSelected { selectedWorkModes.remove(mode) }
                                else { selectedWorkModes.insert(mode) }
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
                compensationDropdown(title: "Target Compensation", selection: $compensationTarget)
                
                // Preferred Locations
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Locations")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(locationPreferences, id: \.self) { loc in
                            HStack(spacing: 6) {
                                Text(loc)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.SwiftUIColors.purple)
                                Button(action: { locationPreferences.removeAll { $0 == loc } }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(AppTheme.SwiftUIColors.purple)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.SwiftUIColors.purple.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.SwiftUIColors.purple.opacity(0.35), lineWidth: 1))
                        }
                    }
                    
                    HStack {
                        TextField("Add location...", text: $newLocationInput)
                            .font(.system(size: 14))
                            .padding(10)
                            .background(Color(hex: "#0E131E"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .onSubmit { addLocation() }
                        
                        Button("Add") { addLocation() }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppTheme.SwiftUIColors.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(18)
            .background(AppTheme.SwiftUIColors.glass)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r20))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r20).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
        }
    }
    
    // MARK: - Bottom Navigation Bar
    private var bottomNavigation: some View {
        VStack {
            HStack {
                if currentStep < totalSteps {
                    Button(action: {
                        if currentStep == 1, let parsed = parsedResumeData {
                            applyParsedDataToFields(parsed)
                        }
                        goToNextStep()
                    }) {
                        HStack(spacing: 6) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16))
                        .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.4), radius: 8, x: 0, y: 3)
                    }
                } else {
                    VStack(spacing: 12) {
                        Button(action: {
                            completeOnboarding()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Complete Setup & Start Matching")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.SwiftUIColors.green, AppTheme.SwiftUIColors.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16))
                            .shadow(color: AppTheme.SwiftUIColors.green.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        
                        Button(action: {
                            skipOnboarding()
                        }) {
                            Text("Skip & Continue Offline")
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(hex: "#090D14").opacity(0.95))
        }
    }
    
    // MARK: - UI Helpers
    private func stepTitle(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            }
            Text(subtitle)
                .font(.system(size: 13.5))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                .lineSpacing(3)
        }
    }
    
    private let compensationOptions: [String] = {
        var options: [String] = []
        for rate in stride(from: 15, through: 100, by: 5) {
            options.append("$\(rate)/hr")
        }
        for rate in stride(from: 105, through: 150, by: 5) {
            options.append("$\(rate)/hr")
        }
        options.append("$150+/hr")
        return options
    }()
    
    private func compensationDropdown(title: String, selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            
            Menu {
                ForEach(compensationOptions, id: \.self) { option in
                    Button(action: {
                        selection.wrappedValue = option
                    }) {
                        HStack {
                            Text(option)
                            if selection.wrappedValue == option || "\(selection.wrappedValue)/hr" == option || selection.wrappedValue == "\(option)+" {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.isEmpty ? "Select hourly compensation" : selection.wrappedValue)
                        .font(.system(size: 14))
                        .foregroundColor(selection.wrappedValue.isEmpty ? AppTheme.SwiftUIColors.textTertiary : AppTheme.SwiftUIColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                }
                .padding(10)
                .background(Color(hex: "#0E131E"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
            }
        }
    }
    
    private func fieldInput(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
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
    
    // MARK: - Actions
    private func addCourse() {
        let trimmed = newCourseInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !coursework.contains(trimmed) {
            coursework.append(trimmed)
            newCourseInput = ""
        }
    }
    
    private func addSkill() {
        let trimmed = newSkillInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !skills.contains(trimmed) {
            skills.append(trimmed)
            newSkillInput = ""
        }
    }
    
    private func addExperience() {
        let trimmed = newExperienceInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !experiences.contains(trimmed) {
            experiences.append(trimmed)
            newExperienceInput = ""
        }
    }
    
    private func addLocation() {
        let trimmed = newLocationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !locationPreferences.contains(trimmed) {
            locationPreferences.append(trimmed)
            newLocationInput = ""
        }
    }
    
    private func goToNextStep() {
        if currentStep < totalSteps {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    private func handleResumeUploaded(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileName = url.lastPathComponent
        self.uploadedFileName = fileName
        
        guard let data = try? Data(contentsOf: url) else { return }
        self.uploadedFileData = data
        self.isParsingResume = true
        
        Task {
            do {
                let parsed = try await APIService.shared.parseResume(pdfData: data, fileName: fileName)
                await MainActor.run {
                    self.isParsingResume = false
                    self.parsedResumeData = parsed
                    self.showParsedDecisionPrompt = true
                    self.applyParsedDataToFields(parsed)
                }
            } catch {
                await MainActor.run {
                    self.isParsingResume = false
                    self.extractLocalPDFInfo(data: data, fileName: fileName)
                }
            }
        }
    }
    
    private func extractLocalPDFInfo(data: Data, fileName: String) {
        guard let doc = PDFDocument(data: data) else { return }
        var fullText = ""
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i), let pageText = page.string {
                fullText += pageText + "\n"
            }
        }
        guard !fullText.isEmpty else { return }
        
        let lines = fullText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            
        if self.name.isEmpty, let first = lines.first, first.count < 40 {
            self.name = first
        }
        
        let lower = fullText.lowercased()
        let knownSkills = ["Python", "Swift", "Java", "C++", "JavaScript", "TypeScript", "React", "SQL", "PyTorch", "Git", "AWS", "Docker", "Machine Learning", "Data Structures", "HTML", "CSS", "Node.js"]
        for skill in knownSkills {
            if lower.contains(skill.lowercased()) && !self.skills.contains(skill) {
                self.skills.append(skill)
            }
        }
        
        let localParsed = ParsedResumeData(
            name: self.name.isEmpty ? nil : self.name,
            email: nil,
            university: self.university.isEmpty ? nil : self.university,
            major: self.major.isEmpty ? nil : self.major,
            graduationYear: Int(self.graduationYear),
            skills: self.skills.isEmpty ? nil : self.skills,
            coursework: self.coursework.isEmpty ? nil : self.coursework,
            experience: self.experiences.isEmpty ? nil : self.experiences
        )
        self.parsedResumeData = localParsed
    }
    
    private func applyParsedDataToFields(_ parsed: ParsedResumeData) {
        if let n = parsed.name, !n.isEmpty { self.name = n }
        if let u = parsed.university, !u.isEmpty { self.university = u }
        if let m = parsed.major, !m.isEmpty { self.major = m }
        if let y = parsed.graduationYear { self.graduationYear = "\(y)" }
        if let sk = parsed.skills, !sk.isEmpty {
            for s in sk {
                if !self.skills.contains(s) {
                    self.skills.append(s)
                }
            }
        }
        if let cw = parsed.coursework, !cw.isEmpty {
            for c in cw {
                if !self.coursework.contains(c) {
                    self.coursework.append(c)
                }
            }
        }
        if let ex = parsed.experience, !ex.isEmpty {
            for e in ex {
                if !self.experiences.contains(e) {
                    self.experiences.append(e)
                }
            }
        }
    }
    
    private func saveLocalProfile() {
        var profile = matchStore.studentProfile
        if !name.isEmpty { profile.name = name }
        if !university.isEmpty { profile.university = university }
        profile.degree = degree.isEmpty ? nil : degree
        if !major.isEmpty { profile.major = major }
        profile.minor = minor.isEmpty ? nil : minor
        if let gradYearInt = Int(graduationYear) {
            profile.graduationYear = gradYearInt
        }
        profile.gpa = Double(gpa)
        profile.coursework = coursework
        profile.skills = skills
        profile.experience = experiences
        profile.workModePreferences = Array(selectedWorkModes)
        profile.locationPreferences = locationPreferences
        profile.compensationPreference = compensationTarget.isEmpty ? nil : compensationTarget
        
        if let fileName = uploadedFileName {
            profile.resume = Resume(fileName: fileName, parsedData: parsedResumeData)
        } else {
            profile.resume = nil
        }
        
        matchStore.updateProfile(profile)
    }
    
    private func skipOnboarding() {
        saveLocalProfile()
        withAnimation {
            self.appState.hasCompletedOnboarding = true
        }
    }
    
    private func completeOnboarding() {
        saveLocalProfile()
        let profile = matchStore.studentProfile
        
        // Immediately navigate to main app so the user is never stuck without a backend connection
        withAnimation {
            self.appState.hasCompletedOnboarding = true
        }
        
        // Asynchronous background sync: push to backend if available
        Task {
            do {
                print("PROFILE SYNC: attempting background onboarding save...")
                try await APIService.shared.updateStudentProfile(studentId: profile.id, profile: profile)
                print("PROFILE SYNC: background onboarding save successful")
            } catch {
                print("PROFILE SYNC: background onboarding save skipped/failed (offline mode): \(error.localizedDescription)")
            }
        }
    }
}
