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
    @Published public private(set) var chatOpportunities: [String: OpportunityCard] = [:]
    
    // Refresh & Rate Limiting State (Backend-authoritative with fallback)
    @Published public private(set) var refreshesRemaining: Int = 3
    @Published public private(set) var nextRefreshAvailableAt: Date? = nil
    @Published public private(set) var canRefresh: Bool = true
    
    private let notAppliedKey = "echelon_matches_not_applied"
    private let appliedKey = "echelon_matches_applied"
    private let passedKey = "echelon_passed_ids"
    private let profileKey = "echelon_student_profile"
    private let refreshTimestampsKey = "echelon_refresh_timestamps"
    private let chatHistoriesKey = "echelon_chat_histories"
    private let chatOpportunitiesKey = "echelon_chat_opportunities"
    
    private init() {
        let currentEmail = AuthService.shared.userEmail
        let currentName = AuthService.shared.userDisplayName
        let currentPhone = AuthService.shared.userPhoneNumber
        self.studentProfile = StudentProfile(
            name: currentName,
            email: currentEmail,
            phoneNumber: currentPhone,
            university: nil,
            major: "",
            minor: nil,
            degree: nil,
            graduationYear: 2027,
            gpa: nil,
            skills: [],
            coursework: [],
            experience: [],
            interests: [],
            fields: [],
            workModePreferences: [],
            locationPreferences: [],
            compensationPreference: nil,
            bio: nil,
            profilePictureUrl: nil,
            resume: nil
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
    
    public func appendChatMessage(opportunityId: String, message: ChatMessage, opportunity: OpportunityCard? = nil) {
        if let opp = opportunity {
            chatOpportunities[opp.id] = opp
        } else if chatOpportunities[opportunityId] == nil {
            if let found = self.opportunity(for: opportunityId) {
                chatOpportunities[opportunityId] = found
            }
        }
        var list = chatHistories[opportunityId] ?? []
        list.append(message)
        chatHistories[opportunityId] = list
        saveState()
    }
    
    public func updateChatMessage(opportunityId: String, messageId: UUID, text: String, status: ChatMessageStatus) {
        guard var list = chatHistories[opportunityId],
              let index = list.firstIndex(where: { $0.id == messageId }) else { return }
        list[index] = ChatMessage(id: messageId, sender: list[index].sender, text: text, timestamp: list[index].timestamp, status: status)
        chatHistories[opportunityId] = list
        saveState()
    }
    
    public func opportunity(for id: String) -> OpportunityCard? {
        if let opp = chatOpportunities[id] {
            return opp
        }
        if let opp = notAppliedMatches.first(where: { $0.opportunity.id == id })?.opportunity {
            return opp
        }
        if let opp = appliedMatches.first(where: { $0.opportunity.id == id })?.opportunity {
            return opp
        }
        return nil
    }
    
    public var activeChatOpportunityIds: [String] {
        return chatHistories.keys
            .filter { !(chatHistories[$0]?.isEmpty ?? true) }
            .sorted { id1, id2 in
                let t1 = chatHistories[id1]?.last?.timestamp ?? Date.distantPast
                let t2 = chatHistories[id2]?.last?.timestamp ?? Date.distantPast
                return t1 > t2
            }
    }
    
    public func deleteChatHistory(for opportunityId: String) {
        chatHistories.removeValue(forKey: opportunityId)
        chatOpportunities.removeValue(forKey: opportunityId)
        saveState()
    }
    
    // MARK: - Backend Databricks Saved Opportunities Sync
    public func fetchSavedOpportunitiesFromBackend() {
        Task {
            do {
                let savedCards = try await APIService.shared.getSavedOpportunities()
                await MainActor.run {
                    for opp in savedCards {
                        if !self.notAppliedMatches.contains(where: { $0.opportunity.id == opp.id }) &&
                           !self.appliedMatches.contains(where: { $0.opportunity.id == opp.id }) {
                            let match = MatchedOpportunity(
                                id: UUID().uuidString,
                                opportunity: opp,
                                applicationStatus: .notApplied,
                                matchedAt: Date()
                            )
                            self.notAppliedMatches.append(match)
                        }
                    }
                    self.saveState()
                }
            } catch {
                // Ignore background sync errors
            }
        }
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
        let timestamps = getRefreshTimestamps().filter { $0 > oneHourAgo }
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
        chatOpportunities.removeAll()
        refreshesRemaining = 3
        canRefresh = true
        nextRefreshAvailableAt = nil
        
        UserDefaults.standard.removeObject(forKey: notAppliedKey)
        UserDefaults.standard.removeObject(forKey: appliedKey)
        UserDefaults.standard.removeObject(forKey: passedKey)
        UserDefaults.standard.removeObject(forKey: profileKey)
        UserDefaults.standard.removeObject(forKey: refreshTimestampsKey)
        UserDefaults.standard.removeObject(forKey: chatHistoriesKey)
        UserDefaults.standard.removeObject(forKey: chatOpportunitiesKey)
    }
    
    public func resetForNewUser(name: String? = nil, email: String? = nil, phoneNumber: String? = nil) {
        clearAllData()
        let resolvedName = (name?.isEmpty == false) ? name : AuthService.shared.userDisplayName
        let resolvedEmail = (email?.isEmpty == false) ? email : AuthService.shared.userEmail
        let resolvedPhone = (phoneNumber?.isEmpty == false) ? phoneNumber : AuthService.shared.userPhoneNumber
        self.studentProfile = StudentProfile(
            name: resolvedName,
            email: resolvedEmail,
            phoneNumber: resolvedPhone,
            university: nil,
            major: "",
            minor: nil,
            degree: nil,
            graduationYear: 2027,
            gpa: nil,
            skills: [],
            coursework: [],
            experience: [],
            interests: [],
            fields: [],
            workModePreferences: [],
            locationPreferences: [],
            compensationPreference: nil,
            bio: nil,
            profilePictureUrl: nil,
            resume: nil
        )
        updateProfile(self.studentProfile)
        saveState()
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
        
        if let encodedChats = try? JSONEncoder().encode(chatHistories) {
            UserDefaults.standard.set(encodedChats, forKey: chatHistoriesKey)
        }
        if let encodedChatOpps = try? JSONEncoder().encode(chatOpportunities) {
            UserDefaults.standard.set(encodedChatOpps, forKey: chatOpportunitiesKey)
        }
    }
    
    private func loadPersistedState() {
        let decoder = JSONDecoder()
        
        if let profileData = UserDefaults.standard.data(forKey: profileKey),
           let savedProfile = try? decoder.decode(StudentProfile.self, from: profileData) {
            self.studentProfile = savedProfile
        }
        
        if let notAppliedData = UserDefaults.standard.data(forKey: notAppliedKey),
           let opps = try? decoder.decode([OpportunityCard].self, from: notAppliedData) {
            self.notAppliedMatches = opps.map {
                MatchedOpportunity(id: UUID().uuidString, opportunity: $0, applicationStatus: .notApplied)
            }
        } else {
            self.notAppliedMatches = []
        }
        
        if let appliedData = UserDefaults.standard.data(forKey: appliedKey),
           let opps = try? decoder.decode([OpportunityCard].self, from: appliedData) {
            self.appliedMatches = opps.map {
                MatchedOpportunity(id: UUID().uuidString, opportunity: $0, applicationStatus: .applied, appliedAt: Date())
            }
        } else {
            self.appliedMatches = []
        }
        
        if let passedList = UserDefaults.standard.array(forKey: passedKey) as? [String] {
            self.passedOpportunityIds = Set(passedList)
        }
        
        if let chatData = UserDefaults.standard.data(forKey: chatHistoriesKey),
           let savedChats = try? decoder.decode([String: [ChatMessage]].self, from: chatData) {
            self.chatHistories = savedChats
        } else {
            self.chatHistories = [:]
        }
        
        if let oppData = UserDefaults.standard.data(forKey: chatOpportunitiesKey),
           let savedOpps = try? decoder.decode([String: OpportunityCard].self, from: oppData) {
            self.chatOpportunities = savedOpps
        } else {
            self.chatOpportunities = [:]
        }
        
    }
}
