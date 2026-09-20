import SwiftUI

public struct ChatConversationView: View {
    public let opportunity: OpportunityCard
    @ObservedObject private var matchStore = MatchStore.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showOpportunityDetail: Bool = false
    @FocusState private var isInputFocused: Bool
    
    public init(opportunity: OpportunityCard) {
        self.opportunity = opportunity
    }
    
    private let sampleSuggestions: [String] = [
        "What are the most valued skills for this role?",
        "Can you review my resume fit?",
        "What is the day-to-day work like?",
        "What is the interview process?"
    ]
    
    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Navigation Header (iMessage style)
            headerView
            
            Divider()
                .background(AppTheme.SwiftUIColors.border.opacity(0.6))
            
            // MARK: - Chat History Message Stream
            ScrollViewReader { scrollProxy in
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 14) {
                        // Opportunity Context Card Header
                        opportunityContextBanner
                            .padding(.top, 12)
                        
                        // Date Separator Pill
                        Text("Today")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                            .padding(.vertical, 6)
                        
                        // Message Bubbles
                        ForEach(messages) { msg in
                            messageRow(for: msg)
                        }
                        
                        // Typing Indicator
                        if isSending {
                            typingIndicatorRow
                        }
                        
                        // Error Notice
                        if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(AppTheme.SwiftUIColors.red)
                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.SwiftUIColors.red)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.SwiftUIColors.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        
                        Color.clear
                            .frame(height: 1)
                            .id("chatStreamBottom")
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onAppear {
                    self.messages = matchStore.chatHistory(for: opportunity.id)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollProxy.scrollTo("chatStreamBottom", anchor: .bottom)
                    }
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        scrollProxy.scrollTo("chatStreamBottom", anchor: .bottom)
                    }
                }
            }
            
            // MARK: - Suggested Quick Prompts
            if messages.count < 6 {
                suggestedPromptsBar
            }
            
            // MARK: - Liquid Glass Text Input Bar
            inputBarView
        }
        .background(AppTheme.SwiftUIColors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showOpportunityDetail) {
            OpportunityDetailView(opportunity: opportunity)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Chats")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppTheme.SwiftUIColors.cyan)
            }
            
            Spacer()
            
            // Recipient Info
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    companyIconView(size: 20)
                    Text(opportunity.organization)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                }
                
                Text(opportunity.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Article / Details Button
            Button(action: {
                showOpportunityDetail = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                    Text("Article")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Opportunity Context Banner
    private var opportunityContextBanner: some View {
        Button(action: {
            showOpportunityDetail = true
        }) {
            HStack(spacing: 12) {
                companyIconView(size: 38)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(opportunity.organization)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        
                        if let match = opportunity.matchPercentage {
                            Text("\(match)% Match")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.SwiftUIColors.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.SwiftUIColors.green.opacity(0.16))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(opportunity.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                        .lineLimit(1)
                    
                    Text("Tap to view full article & role specifications")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(AppTheme.SwiftUIColors.cyan)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radii.r16, style: .continuous)
                    .stroke(AppTheme.SwiftUIColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Message Rows
    @ViewBuilder
    private func messageRow(for msg: ChatMessage) -> some View {
        if msg.sender == .user {
            // User message bubble (Trailing, Vibrant Blue)
            HStack {
                Spacer(minLength: 44)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(msg.text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.SwiftUIColors.blue, Color(hex: "#0066CC")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .shadow(color: AppTheme.SwiftUIColors.blue.opacity(0.25), radius: 6, x: 0, y: 3)
                    
                    Text(formatTimestamp(msg.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                        .padding(.trailing, 4)
                }
            }
        } else {
            // Advisor / Company message bubble (Leading, Frosted Liquid Glass)
            HStack(alignment: .top, spacing: 8) {
                companyIconView(size: 28)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(msg.text)
                        .font(.system(size: 14.5))
                        .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                        .lineSpacing(3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.09))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    Text(formatTimestamp(msg.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                        .padding(.leading, 4)
                }
                
                Spacer(minLength: 40)
            }
        }
    }
    
    // MARK: - Typing Indicator
    private var typingIndicatorRow: some View {
        HStack(alignment: .top, spacing: 8) {
            companyIconView(size: 28)
                .padding(.top, 4)
            
            HStack(spacing: 5) {
                Circle()
                    .fill(AppTheme.SwiftUIColors.cyan)
                    .frame(width: 7, height: 7)
                    .opacity(0.8)
                Circle()
                    .fill(AppTheme.SwiftUIColors.cyan)
                    .frame(width: 7, height: 7)
                    .opacity(0.5)
                Circle()
                    .fill(AppTheme.SwiftUIColors.cyan)
                    .frame(width: 7, height: 7)
                    .opacity(0.3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            
            Spacer()
        }
    }
    
    // MARK: - Quick Prompts Bar
    private var suggestedPromptsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sampleSuggestions, id: \.self) { prompt in
                    Button(action: {
                        sendMessage(prompt)
                    }) {
                        Text(prompt)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.SwiftUIColors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Input Bar
    private var inputBarView: some View {
        HStack(spacing: 10) {
            HStack {
                TextField("Message \(opportunity.organization)...", text: $inputText)
                    .font(.system(size: 14.5))
                    .foregroundColor(AppTheme.SwiftUIColors.textPrimary)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage(inputText)
                    }
                
                if !inputText.isEmpty {
                    Button(action: { inputText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.SwiftUIColors.textTertiary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            
            Button(action: {
                sendMessage(inputText)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.SwiftUIColors.textTertiary : AppTheme.SwiftUIColors.blue)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helpers
    private func sendMessage(_ text: String) {
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
    
    private func companyIconView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: opportunity.accentHex ?? "#3B82F6").opacity(0.2))
                .frame(width: size, height: size)
            
            Image(systemName: opportunity.companyLogoName ?? "building.2.fill")
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(Color(hex: opportunity.accentHex ?? "#3B82F6"))
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
