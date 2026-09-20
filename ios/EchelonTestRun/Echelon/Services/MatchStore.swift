import Foundation
import SwiftUI
import Combine

@MainActor
public final class MatchStore: ObservableObject {
    public static let shared = MatchStore()
    
    // MARK: - Published Properties
    @Published public private(set) var notAppliedMatches: [MatchedOpportunity] = []
    @Published public private(set) var appliedMatches: [MatchedOpportunity] = []
    @Published public private(set) var passedOpportunityIds: Set<String> = []
    @Published public var studentProfile: StudentProfile
    @Published public private(set) var chatHistories: [String: [ChatMessage]] = [:]
    
    // Refresh & Rate Limiting State (Backend-authoritative with fallback)
    @Published public private(set) var refreshesRemaining: Int = 3
    @Published public private(set) var nextRefreshAvailableAt: Date? = nil
    @Published public private(set) var canRefresh: Bool = true
    
    private let notAppliedKey = "echelon_matches_not_applied"
    private let appliedKey = "echelon_matches_applied"
    private let passedKey = "echelon_passed_ids"
    private let profileKey = "echelon_student_profile"
    private let refreshTimestampsKey = "echelon_refresh_timestamps"
    
    private init() {
        let currentEmail = AuthService.shared.userEmail ?? "alex.chen@vt.edu"
        let currentName = AuthService.shared.userDisplayName ?? "Alex Chen"
        self.studentProfile = StudentProfile(
            name: currentName,
            email: currentEmail,
            phoneNumber: "+1 (540) 555-0199",
            university: "Virginia Tech",
            major: "Computer Science",
            minor: "Mathematics",
            degree: "Bachelor of Science",
            graduationYear: 2027,
            gpa: 3.92,
            skills: ["Python", "Swift", "C++", "PyTorch", "Docker", "AWS", "SQL", "Git"],
            coursework: ["Data Structures", "Algorithms", "Operating Systems", "Cloud Computing", "Machine Learning"],
            experience: ["Autonomy Software Intern @ YC Startup", "Undergraduate ML Researcher @ VT AI Lab"],
            interests: ["Internship", "Research"],
            fields: ["Software Engineering", "AI/ML"],
            workModePreferences: ["Hybrid", "In-Person", "Remote"],
            locationPreferences: ["San Francisco, CA", "New York, NY", "Remote"],
            compensationPreference: "$45/hr+",
            bio: "Passionate about systems engineering and applied ML. Previously built autonomy software at a YC startup. Seeking research or engineering roles in AI infrastructure.",
            profilePictureUrl: nil,
            resume: Resume(
                fileName: "Alex_Chen_Resume_2027.pdf",
                parsedData: ParsedResumeData(
                    name: "Alex Chen",
                    email: "alex.chen@vt.edu",
                    phoneNumber: "+1 (540) 555-0199",
                    university: "Virginia Tech",
                    major: "Computer Science",
                    minor: "Mathematics",
                    degree: "Bachelor of Science",
                    graduationYear: 2027,
                    gpa: 3.92,
                    skills: ["Python", "Swift", "C++", "PyTorch", "Docker", "AWS", "SQL", "Git"],
                    coursework: ["Data Structures", "Algorithms", "Operating Systems", "Cloud Computing", "Machine Learning"],
                    experience: ["Autonomy Software Intern @ YC Startup", "Undergraduate ML Researcher @ VT AI Lab"]
                )
            )
        )
        
        loadPersistedState()
        evaluateRateLimit()
    }
    
    // MARK: - Matches & Swipe Interactions
    
    public func recordSwipe(opportunity: OpportunityCard, direction: OpportunityInteraction) {
        switch direction {
        case .matched:
            // Right swipe = match (Not Applied)
            if !notAppliedMatches.contains(where: { $0.opportunity.id == opportunity.id }) &&
               !appliedMatches.contains(where: { $0.opportunity.id == opportunity.id }) {
                let match = MatchedOpportunity(
                    id: UUID().uuidString,
                    opportunity: opportunity,
                    applicationStatus: .notApplied,
                    matchedAt: Date()
                )
                notAppliedMatches.insert(match, at: 0)
                saveState()
            }
        case .passed:
            passedOpportunityIds.insert(opportunity.id)
            saveState()
        case .unseen:
            break
        }
    }
    
    public func applyToOpportunity(id: String) {
        if let index = notAppliedMatches.firstIndex(where: { $0.opportunity.id == id }) {
            var match = notAppliedMatches.remove(at: index)
            match.applicationStatus = .applied
            match.appliedAt = Date()
            appliedMatches.insert(match, at: 0)
            saveState()
        } else if let _ = appliedMatches.firstIndex(where: { $0.opportunity.id == id }) {
            // Already applied
            return
        } else if let opp = OpportunityCard.mockDeck.first(where: { $0.id == id }) {
            let match = MatchedOpportunity(id: UUID().uuidString, opportunity: opp, applicationStatus: .applied, appliedAt: Date())
            appliedMatches.insert(match, at: 0)
            saveState()
        }
    }
    
    public func removeMatch(opportunityId: String) {
        notAppliedMatches.removeAll { $0.opportunity.id == opportunityId }
        appliedMatches.removeAll { $0.opportunity.id == opportunityId }
        saveState()
    }
    
    public func applicationStatus(for opportunityId: String) -> ApplicationStatus {
        if appliedMatches.contains(where: { $0.opportunity.id == opportunityId }) {
            return .applied
        }
        return .notApplied
    }
    
    // MARK: - Chatbot History Management
    
    public func chatHistory(for opportunityId: String) -> [ChatMessage] {
        return chatHistories[opportunityId] ?? []
    }
    
    public func appendChatMessage(opportunityId: String, message: ChatMessage) {
        var list = chatHistories[opportunityId] ?? []
        list.append(message)
        chatHistories[opportunityId] = list
    }
    
    public func updateChatMessage(opportunityId: String, messageId: UUID, text: String, status: ChatMessageStatus) {
        guard var list = chatHistories[opportunityId],
              let index = list.firstIndex(where: { $0.id == messageId }) else { return }
        list[index] = ChatMessage(id: messageId, sender: list[index].sender, text: text, timestamp: list[index].timestamp, status: status)
        chatHistories[opportunityId] = list
    }
    
    // MARK: - Rate Limiting Management
    
    public func updateRateLimit(canRefresh: Bool, refreshesRemaining: Int, nextRefreshAvailableAt: Date?) {
        self.canRefresh = canRefresh
        self.refreshesRemaining = refreshesRemaining
        self.nextRefreshAvailableAt = nextRefreshAvailableAt
    }
    
    public func recordManualRefresh() {
        var timestamps = getRefreshTimestamps()
        timestamps.append(Date())
        UserDefaults.standard.set(timestamps.map { $0.timeIntervalSince1970 }, forKey: refreshTimestampsKey)
        evaluateRateLimit()
    }
    
    public func evaluateRateLimit() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        var timestamps = getRefreshTimestamps().filter { $0 > oneHourAgo }
        UserDefaults.standard.set(timestamps.map { $0.timeIntervalSince1970 }, forKey: refreshTimestampsKey)
        
        let used = timestamps.count
        let remaining = max(0, 3 - used)
        self.refreshesRemaining = remaining
        self.canRefresh = remaining > 0
        
        if remaining == 0, let oldest = timestamps.first {
            self.nextRefreshAvailableAt = oldest.addingTimeInterval(3600)
        } else {
            self.nextRefreshAvailableAt = nil
        }
    }
    
    private func getRefreshTimestamps() -> [Date] {
        let raw = UserDefaults.standard.array(forKey: refreshTimestampsKey) as? [Double] ?? []
        return raw.map { Date(timeIntervalSince1970: $0) }
    }
    
    // MARK: - Profile Updates
    
    public func updateProfile(_ profile: StudentProfile) {
        self.studentProfile = profile
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    public func syncProfileWithBackend() {
        Task {
            if let profile = try? await APIService.shared.fetchCurrentProfile() {
                self.updateProfile(profile)
            }
        }
    }
    
    public func clearAllData() {
        notAppliedMatches.removeAll()
        appliedMatches.removeAll()
        passedOpportunityIds.removeAll()
        chatHistories.removeAll()
        refreshesRemaining = 3
        canRefresh = true
        nextRefreshAvailableAt = nil
        
        UserDefaults.standard.removeObject(forKey: notAppliedKey)
        UserDefaults.standard.removeObject(forKey: appliedKey)
        UserDefaults.standard.removeObject(forKey: passedKey)
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: refreshTimestampsKey)
    }
    
    // MARK: - Persistence
    
    public func saveState() {
        if let encodedNotApplied = try? JSONEncoder().encode(notAppliedMatches.map { $0.opportunity }) {
            UserDefaults.standard.set(encodedNotApplied, forKey: notAppliedKey)
        }
        if let encodedApplied = try? JSONEncoder().encode(appliedMatches.map { $0.opportunity }) {
            UserDefaults.standard.set(encodedApplied, forKey: appliedKey)
        }
        UserDefaults.standard.set(Array(passedOpportunityIds), forKey: passedKey)
    }
    
    private func loadPersistedState() {
        let decoder = JSONDecoder()
        
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? decoder.decode(StudentProfile.self, from: profileData) {
            self.studentProfile = savedProfile
        }
        
        if let notAppliedData = UserDefaults.standard.data(forKey: notAppliedKey),
           let opps = try? decoder.decode([OpportunityCard].self, from: notAppliedData),
           !opps.isEmpty {
            self.notAppliedMatches = opps.map {
                MatchedOpportunity(id: UUID().uuidString, opportunity: $0, applicationStatus: .notApplied)
            }
        } else {
            let deck = OpportunityCard.mockDeck
            self.notAppliedMatches = [
                MatchedOpportunity(
                    id: "match-1",
                    opportunity: deck.indices.contains(4) ? deck[4] : deck[0],
                    applicationStatus: .notApplied
                ),
                MatchedOpportunity(
                    id: "match-2",
                    opportunity: deck[0],
                    applicationStatus: .notApplied
                )
            ]
        }
        
        if let appliedData = UserDefaults.standard.data(forKey: appliedKey),
           let opps = try? decoder.decode([OpportunityCard].self, from: appliedData),
           !opps.isEmpty {
            self.appliedMatches = opps.map {
                MatchedOpportunity(id: UUID().uuidString, opportunity: $0, applicationStatus: .applied, appliedAt: Date())
            }
        } else {
            let deck = OpportunityCard.mockDeck
            self.appliedMatches = [
                MatchedOpportunity(
                    id: "match-3",
                    opportunity: deck.indices.contains(6) ? deck[6] : deck[1],
                    applicationStatus: .applied,
                    appliedAt: Date().addingTimeInterval(-3600)
                ),
                MatchedOpportunity(
                    id: "match-4",
                    opportunity: deck.indices.contains(5) ? deck[5] : deck[2],
                    applicationStatus: .applied,
                    appliedAt: Date().addingTimeInterval(-86400)
                )
            ]
        }
        
        if let passedList = UserDefaults.standard.array(forKey: passedKey) as? [String] {
            self.passedOpportunityIds = Set(passedList)
        }
    }
}
