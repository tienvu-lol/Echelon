import SwiftUI

public struct OpportunityDetailView: View {
    public let opportunity: OpportunityCard
    @ObservedObject private var matchStore = MatchStore.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showApplySuccessToast: Bool = false
    
    public init(opportunity: OpportunityCard) {
        self.opportunity = opportunity
    }
    
    private var isApplied: Bool {
        matchStore.applicationStatus(for: opportunity.id) == .applied
    }
    
    public var body: some View {
        ZStack {
            AppTheme.SwiftUIColors.background
                .ignoresSafeArea()
            
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 1. Large Hero Header Section
                        heroSection
                        
                        // 2. Main Article Content
                        VStack(alignment: .leading, spacing: 22) {
                            // Quick Specs Grid
                            specsGrid
                            
                            // Overview & Full Description
                            descriptionSection
                            
                            // Responsibilities
                            if let responsibilities = opportunity.responsibilities, !responsibilities.isEmpty {
                                listSection(title: "Key Responsibilities", icon: "checklist", items: responsibilities)
                            }
                            
                            // Qualifications
                            if let qualifications = opportunity.qualifications, !qualifications.isEmpty {
                                listSection(title: "Qualifications", icon: "checkmark.seal.fill", items: qualifications)
                            }
                            
                            // Required & Preferred Skills
                            skillsSection
                            
                            // Relevant Coursework
                            if let coursework = opportunity.coursework, !coursework.isEmpty {
                                courseworkSection(coursework: coursework)
                            }
                            
                            Divider()
                                .background(AppTheme.SwiftUIColors.border)
                                .padding(.vertical, 8)
                            
                            // 3. AI Match & Chatbot Section
                            chatbotSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                    }
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        scrollProxy.scrollTo("chatBottomAnchor", anchor: .bottom)
                    }
                }
            }
            
            // Top Bar Floating Controls
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.65))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    // Apply Action Pill
                    if isApplied {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.SwiftUIColors.green)
                            Text("Applied")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.green)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.SwiftUIColors.green.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.green.opacity(0.4), lineWidth: 1))
                    } else {
                        Button(action: applyAction) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                Text("Apply Now")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.5), radius: 8, x: 0, y: 3)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
            
            // Toast Notification
            if showApplySuccessToast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.SwiftUIColors.green)
                        Text("Application recorded! Moved to Applied.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#161D27").opacity(0.95))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            self.messages = matchStore.chatHistory(for: opportunity.id)
        }
    }
    
    // MARK: - 1. Hero Header Section
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            RemoteImageView(
                urlString: opportunity.imageUrl,
                fallbackSystemName: "building.2.crop.circle",
                contentMode: .fill
            )
            .frame(height: 320)
            .clipped()
            
            // Gradient Overlay for Readability
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.5), location: 0.0),
                    .init(color: Color.clear, location: 0.3),
                    .init(color: AppTheme.SwiftUIColors.background.opacity(0.7), location: 0.65),
                    .init(color: AppTheme.SwiftUIColors.background, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Hero Title & Organization Overlay
            VStack(alignment: .leading, spacing: 8) {
                // Type & WorkMode Pills
                HStack(spacing: 8) {
                    Text(opportunity.opportunityType.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.SwiftUIColors.cyan.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.cyan.opacity(0.4), lineWidth: 1))
                    
                    if let workMode = opportunity.workMode {
                        Text(workMode)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.SwiftUIColors.pillBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    if let match = opportunity.matchPercentage {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("\(match)% Match")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppTheme.SwiftUIColors.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.SwiftUIColors.green.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.green.opacity(0.4), lineWidth: 1))
                    }
                }
                
                Text(opportunity.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .lineLimit(3)
                
                HStack(spacing: 10) {
                    if let logoUrl = opportunity.organizationLogoUrl, !logoUrl.isEmpty {
                        RemoteImageView(urlString: logoUrl, fallbackSystemName: "building.2.fill", contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: opportunity.companyLogoName ?? "shield.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.SwiftUIColors.blue)
                    }
                    
                    Text(opportunity.organization)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
    
    // MARK: - Specs Grid
    @ViewBuilder
    private var specsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if let location = opportunity.location {
                specTile(icon: "mappin.and.ellipse", title: "Location", value: location)
            }
            if let comp = opportunity.compensation {
                specTile(icon: "dollarsign.circle.fill", title: "Compensation", value: comp)
            }
            if let dur = opportunity.duration {
                specTile(icon: "clock.fill", title: "Duration", value: dur)
            }
            if let start = opportunity.startDate {
                specTile(icon: "calendar", title: "Start Date", value: start)
            }
            if let deadline = opportunity.deadline {
                specTile(icon: "hourglass.bottomhalf.filled", title: "Deadline", value: deadline)
            }
        }
    }
    
    private func specTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.SwiftUIColors.cyan)
                .frame(width: 28, height: 28)
                .background(AppTheme.SwiftUIColors.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r16).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About the Role")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            Text(opportunity.fullDescription ?? opportunity.description)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                .lineSpacing(5)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r18))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r18).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - List Section (Responsibilities / Qualifications)
    private func listSection(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(AppTheme.SwiftUIColors.cyan)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)
                        Text(item)
                            .font(.system(size: 13.5))
                            .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r18))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r18).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Skills Section
    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills & Technologies")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            // Required Skills
            VStack(alignment: .leading, spacing: 6) {
                Text("Required:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(opportunity.skills, id: \.self) { skill in
                        skillPill(text: skill, isPreferred: false)
                    }
                }
            }
            
            // Preferred Skills if present
            if let preferred = opportunity.preferredSkills, !preferred.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Preferred:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(preferred, id: \.self) { skill in
                            skillPill(text: skill, isPreferred: true)
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r18))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r18).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private func skillPill(text: String, isPreferred: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(isPreferred ? AppTheme.SwiftUIColors.yellow : AppTheme.SwiftUIColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isPreferred ? AppTheme.SwiftUIColors.yellow.opacity(0.12) : AppTheme.SwiftUIColors.pillBackground)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isPreferred ? AppTheme.SwiftUIColors.yellow.opacity(0.3) : AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - Coursework Section
    private func courseworkSection(coursework: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Relevant Coursework")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            FlowLayout(spacing: 8) {
                ForEach(coursework, id: \.self) { course in
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.SwiftUIColors.cyan)
                        Text(course)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.SwiftUIColors.cyan.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.SwiftUIColors.cyan.opacity(0.3), lineWidth: 1))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r18))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r18).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    // MARK: - 3. AI Chatbot Section Decomposition
    @ViewBuilder
    private var chatbotSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            chatbotHeader
            
            if let analysis = opportunity.matchAnalysis {
                matchAnalysisCard(analysis: analysis)
            }
            
            suggestedQuestionsSection
            
            chatMessagesList
            
            if isSending {
                typingIndicator
            }
            
            if let err = errorMessage {
                errorBanner(err: err)
            }
            
            chatInputBar
        }
        .padding(18)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r22))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r22).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private var chatbotHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.SwiftUIColors.blue.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Echelon AI Advisor")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                Text("Ask questions or see why you match")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private func matchAnalysisCard(analysis: MatchAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let overall = analysis.overallMatch {
                HStack {
                    Text("Your Overall Match")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    Spacer()
                    Text("\(overall)%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.green)
                }
            }
            
            VStack(spacing: 8) {
                if let skills = analysis.skillsMatch {
                    BreakdownProgressBar(title: "Skills Alignment", percent: skills)
                }
                if let coursework = analysis.courseworkMatch {
                    BreakdownProgressBar(title: "Relevant Coursework", percent: coursework)
                }
                if let exp = analysis.experienceMatch {
                    BreakdownProgressBar(title: "Experience Fit", percent: exp)
                }
                if let pref = analysis.preferencesMatch {
                    BreakdownProgressBar(title: "Role Preferences", percent: pref)
                }
            }
            
            if let explanation = analysis.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 12.5))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color(hex: "#111722"))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radii.r16).stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
    }
    
    private var suggestedQuestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Questions")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    promptChip(title: "Tell me more about this opportunity")
                    promptChip(title: "Why am I a good match?")
                    promptChip(title: "Tell me about related opportunities")
                }
            }
        }
    }
    
    private func promptChip(title: String) -> some View {
        Button(action: {
            self.sendMessage(text: title)
        }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.SwiftUIColors.cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppTheme.SwiftUIColors.cyan.opacity(0.12))
                .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var chatMessagesList: some View {
        if !messages.isEmpty {
            VStack(spacing: 12) {
                ForEach(messages) { msg in
                    ChatBubbleView(msg: msg)
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 6) {
            Circle().fill(AppTheme.SwiftUIColors.cyan).frame(width: 6, height: 6)
            Circle().fill(AppTheme.SwiftUIColors.cyan).frame(width: 6, height: 6)
            Circle().fill(AppTheme.SwiftUIColors.cyan).frame(width: 6, height: 6)
            Text("Advisor is typing...")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.SwiftUIColors.glass)
        .clipShape(Capsule())
    }
    
    private func errorBanner(err: String) -> some View {
        HStack {
            Text(err)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.SwiftUIColors.red)
            Spacer()
            Button("Retry") {
                if let lastUser = self.messages.last(where: { $0.sender == .user }) {
                    self.sendMessage(text: lastUser.text)
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(AppTheme.SwiftUIColors.cyan)
        }
        .padding(10)
        .background(AppTheme.SwiftUIColors.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask a question about this role...", text: $inputText)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#0E131E"))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
                .onSubmit {
                    if !self.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.sendMessage(text: self.inputText)
                    }
                }
            
            Button(action: {
                self.sendMessage(text: self.inputText)
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending
                            ? Color.gray.opacity(0.4)
                            : AppTheme.SwiftUIColors.blue
                    )
                    .clipShape(Circle())
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .id("chatBottomAnchor")
    }
    
    // MARK: - Actions
    private func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        inputText = ""
        errorMessage = nil
        
        let userMsg = ChatMessage(sender: .user, text: trimmed)
        messages.append(userMsg)
        matchStore.appendChatMessage(opportunityId: opportunity.id, message: userMsg)
        
        isSending = true
        
        let context = OpportunityChatContext(
            opportunityId: opportunity.id,
            opportunityTitle: opportunity.title,
            organization: opportunity.organization,
            studentProfile: matchStore.studentProfile,
            matchAnalysis: opportunity.matchAnalysis
        )
        
        Task {
            do {
                let response = try await APIService.shared.sendChatMessage(
                    opportunityId: opportunity.id,
                    studentId: matchStore.studentProfile.id,
                    message: trimmed,
                    context: context
                )
                
                await MainActor.run {
                    self.isSending = false
                    let aiMsg = ChatMessage(sender: .ai, text: response)
                    self.messages.append(aiMsg)
                    self.matchStore.appendChatMessage(opportunityId: opportunity.id, message: aiMsg)
                }
            } catch {
                await MainActor.run {
                    self.isSending = false
                    self.errorMessage = "Unable to connect to AI Advisor. Please try again."
                }
            }
        }
    }
    
    private func applyAction() {
        // Open URL if available
        if let applyUrlStr = opportunity.applyUrl, let url = URL(string: applyUrlStr) {
            UIApplication.shared.open(url)
        }
        
        matchStore.applyToOpportunity(id: opportunity.id)
        
        Task {
            _ = try? await APIService.shared.applyOpportunity(
                studentId: matchStore.studentProfile.id,
                opportunityId: opportunity.id
            )
        }
        
        withAnimation {
            showApplySuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showApplySuccessToast = false
            }
        }
    }
}

// MARK: - Breakdown Progress Bar
public struct BreakdownProgressBar: View {
    public let title: String
    public let percent: Int
    
    public init(title: String, percent: Int) {
        self.title = title
        self.percent = percent
    }
    
    private var fraction: CGFloat {
        CGFloat(max(0, min(100, percent))) / 100.0
    }
    
    public var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#1E2738"))
                        .frame(height: 5)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.SwiftUIColors.blue, AppTheme.SwiftUIColors.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * fraction, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Chat Bubble View
public struct ChatBubbleView: View {
    public let msg: ChatMessage
    
    public init(msg: ChatMessage) {
        self.msg = msg
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.sender == .user {
                Spacer()
                Text(msg.text)
                    .font(.system(size: 13.5))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.SwiftUIColors.blue)
                    .cornerRadius(16)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.SwiftUIColors.cyan.opacity(0.15))
                    .clipShape(Circle())
                
                Text(msg.text)
                    .font(.system(size: 13.5))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#1A2230"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
                    )
                Spacer()
            }
        }
    }
}
