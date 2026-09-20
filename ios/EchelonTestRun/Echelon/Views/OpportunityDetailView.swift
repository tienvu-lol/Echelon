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
        GeometryReader { geometry in
            let contentWidth = geometry.size.width
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 0) {
                        // 1. Large Hero Header Section with Apple Liquid Glass Controls
                        heroSection(width: contentWidth)
                        
                        // 2. Main Article Content
                        VStack(alignment: .leading, spacing: 20) {
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
                        .padding(.top, 18)
                        .padding(.bottom, 80)
                        .frame(width: contentWidth, alignment: .leading)
                    }
                    .frame(width: contentWidth)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        scrollProxy.scrollTo("chatBottomAnchor", anchor: .bottom)
                    }
                }
            }
        }
        .background(AppTheme.SwiftUIColors.background.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            if showApplySuccessToast {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppTheme.SwiftUIColors.green)
                    Text("Application recorded! Moved to Applied.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 4)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            self.messages = matchStore.chatHistory(for: opportunity.id)
        }
    }
    
    // MARK: - 1. Hero Header Section
    private func heroSection(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Background Image
            RemoteImageView(
                urlString: opportunity.imageUrl,
                fallbackSystemName: "building.2.crop.circle",
                contentMode: .fill
            )
            .frame(width: width, height: 320)
            .clipped()
            
            // Gradient Overlay for Readability
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.60), location: 0.0),
                    .init(color: Color.clear, location: 0.35),
                    .init(color: AppTheme.SwiftUIColors.background.opacity(0.75), location: 0.72),
                    .init(color: AppTheme.SwiftUIColors.background, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: 320)
            
            // Top Bar Controls: Apple Liquid Glass Floating Controls
            HStack {
                // Circular Frosted Glass Dismiss Button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 1))
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
                }
                
                Spacer()
                
                // Floating Liquid Glass Action Capsule (Share + Apply)
                HStack(spacing: 12) {
                    Button(action: shareAction) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 1, height: 14)
                    
                    if isApplied {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Applied")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(AppTheme.SwiftUIColors.green)
                    } else {
                        Button(action: applyAction) {
                            HStack(spacing: 5) {
                                Text("Apply")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.24), lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(width: width)
            
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 10) {
                    if let logoUrl = opportunity.organizationLogoUrl, !logoUrl.isEmpty {
                        RemoteImageView(urlString: logoUrl, fallbackSystemName: "building.2.fill", contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Image(systemName: opportunity.companyLogoName ?? "shield.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.SwiftUIColors.blue)
                    }
                    
                    Text(opportunity.organization)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .frame(width: width, alignment: .bottomLeading)
            .frame(maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(width: width, height: 320)
        .clipped()
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    if value.translation.height > 60 && abs(value.translation.width) < 100 {
                        dismiss()
                    }
                }
        )
    }
    
    // MARK: - Specs Grid (Apple System Material Tiles)
    @ViewBuilder
    private var specsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
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
        .frame(maxWidth: .infinity)
    }
    
    private func specTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.SwiftUIColors.cyan)
                .frame(width: 26, height: 26)
                .background(AppTheme.SwiftUIColors.cyan.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous)
                .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Description Section (Apple Liquid Glass)
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About the Role")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
            
            let desc = (opportunity.fullDescription?.isEmpty == false ? opportunity.fullDescription! : opportunity.description)
            Text(desc.isEmpty ? "No description available." : desc)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: AppTheme.Radii.r20)
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
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: AppTheme.Radii.r20)
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
        .liquidGlass(cornerRadius: AppTheme.Radii.r20)
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
        .liquidGlass(cornerRadius: AppTheme.Radii.r20)
    }
    
    // MARK: - 3. AI Chatbot Section (Apple Liquid Glass)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: AppTheme.Radii.r22)
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
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous)
                .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
        )
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .background(AppTheme.SwiftUIColors.cyan.opacity(0.14))
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
            .frame(maxWidth: .infinity)
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
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.SwiftUIColors.border, lineWidth: 1))
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask a question about this role...", text: $inputText)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
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
        .frame(maxWidth: .infinity)
        .id("chatBottomAnchor")
    }
    
    // MARK: - Actions
    private func shareAction() {
        let text = "\(opportunity.title) at \(opportunity.organization)"
        var items: [Any] = [text]
        if let applyUrlStr = opportunity.applyUrl, let url = URL(string: applyUrlStr) {
            items.append(url)
        }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(av, animated: true)
        }
    }
    
    private func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        inputText = ""
        errorMessage = nil
        
        let userMsg = ChatMessage(sender: .user, text: trimmed)
        messages.append(userMsg)
        matchStore.appendChatMessage(opportunityId: opportunity.id, message: userMsg, opportunity: opportunity)
        
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
                    self.matchStore.appendChatMessage(opportunityId: opportunity.id, message: aiMsg, opportunity: opportunity)
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
                        .fill(Color(white: 1.0, opacity: 0.12))
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

// MARK: - Chat Bubble View (Frosted Glass & Vibrant Blue)
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
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.SwiftUIColors.cyan)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.SwiftUIColors.cyan.opacity(0.18))
                    .clipShape(Circle())
                
                Text(msg.text)
                    .font(.system(size: 13.5))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
                    )
                Spacer()
            }
        }
    }
}
