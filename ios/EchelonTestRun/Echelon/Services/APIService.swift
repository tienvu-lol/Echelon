import Foundation
import FirebaseAuth

public enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case authenticationRequired
    case profileRequired
    case requestFailed(statusCode: Int, message: String)
    case serverError(statusCode: Int)
    case decodingError(Error?)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The requested URL is invalid."
        case .invalidResponse:
            return "Received invalid server response."
        case .authenticationRequired:
            return "Sign in with Firebase before loading recommendations."
        case .profileRequired:
            return "Complete onboarding before loading recommendations."
        case .requestFailed(let code, let message):
            return "Request failed (\(code)): \(message)"
        case .serverError(let code):
            return "Server error with status code \(code)."
        case .decodingError(let error):
            if let error = error {
                return "Failed to decode response: \(error.localizedDescription)"
            }
            return "Failed to decode response."
        }
    }
}

public final class APIService {
    public static let shared = APIService()
    
    public var baseURL = "http://localhost:8000"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Auth Header Helper
    private func applyAuthHeader(to request: inout URLRequest) async {
        if let token = await AuthService.shared.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    // MARK: - Health Check
    public func healthCheck() async throws -> HealthResponse {
        guard let url = URL(string: "\(baseURL)/health") else {
            throw APIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        try validateResponse(response)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
    
    // MARK: - Recommendations (Databricks + Gemini Pipeline)
    public func getRecommendations(limit: Int = 10) async throws -> RecommendationsResponse {
        var components = URLComponents(string: "\(baseURL)/api/opportunities/recommendations")
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12.0
        await applyAuthHeader(to: &request)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpRes = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpRes.statusCode == 401 {
            throw APIError.authenticationRequired
        } else if httpRes.statusCode == 404 {
            throw APIError.profileRequired
        } else if !(200...299).contains(httpRes.statusCode) {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw APIError.requestFailed(statusCode: httpRes.statusCode, message: errorMsg)
        }
        
        do {
            return try JSONDecoder().decode(RecommendationsResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - Opportunity Batch Recommendations (Batches of 7)
    public func getOpportunityBatch(studentId: String, limit: Int = 7, isRefresh: Bool = false) async throws -> OpportunityBatch {
        if isRefresh {
            MatchStore.shared.recordManualRefresh()
        }
        
        do {
            let recResponse = try await getRecommendations(limit: limit)
            let cards = recResponse.opportunities.map { $0.card }
            return OpportunityBatch(
                opportunities: Array(cards.prefix(limit)),
                canRefresh: MatchStore.shared.canRefresh,
                refreshesRemaining: MatchStore.shared.refreshesRemaining,
                nextRefreshAvailableAt: MatchStore.shared.nextRefreshAvailableAt
            )
        } catch {
            // Direct fetch attempt if direct OpportunityBatch returned
            guard var components = URLComponents(string: "\(baseURL)/api/opportunities/recommendations") else {
                throw error
            }
            components.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
            guard let url = components.url else { throw error }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10.0
            await applyAuthHeader(to: &request)
            
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            
            if let batch = try? JSONDecoder().decode(OpportunityBatch.self, from: data) {
                return batch
            }
            if let directCards = try? JSONDecoder().decode([OpportunityCard].self, from: data) {
                return OpportunityBatch(
                    opportunities: Array(directCards.prefix(limit)),
                    canRefresh: MatchStore.shared.canRefresh,
                    refreshesRemaining: MatchStore.shared.refreshesRemaining,
                    nextRefreshAvailableAt: MatchStore.shared.nextRefreshAvailableAt
                )
            }
            throw error
        }
    }
    
    public func getRecommendations(studentId: String, limit: Int = 7) async throws -> [OpportunityCard] {
        let batch = try await getOpportunityBatch(studentId: studentId, limit: limit, isRefresh: false)
        return batch.opportunities
    }
    
    // MARK: - Swipe Tracking
    public func recordSwipe(studentId: String, opportunityId: String, direction: String) async throws -> SwipeResponse {
        guard let url = URL(string: "\(baseURL)/api/swipes") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        await applyAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "student_id": studentId,
            "opportunity_id": opportunityId,
            "direction": direction
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(SwipeResponse.self, from: data)
    }
    
    // MARK: - Saved Opportunities (Databricks)
    public func getSavedOpportunities() async throws -> [OpportunityCard] {
        guard let url = URL(string: "\(baseURL)/api/saved") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8.0
        await applyAuthHeader(to: &request)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        struct SavedResponse: Decodable {
            let student_id: String?
            let opportunities: [Opportunity]
        }
        let saved = try JSONDecoder().decode(SavedResponse.self, from: data)
        return saved.opportunities.map { opp in
            OpportunityCard(
                id: opp.id,
                title: opp.title,
                organization: opp.organization,
                opportunityType: opp.opportunityType,
                description: opp.description,
                fullDescription: opp.description,
                skills: opp.skills,
                preferredSkills: opp.interests,
                qualifications: opp.eligibility,
                responsibilities: nil,
                coursework: opp.majors,
                location: opp.location,
                workMode: opp.remoteStatus,
                paid: opp.compensation != nil,
                deadline: opp.deadline,
                applyUrl: opp.applyUrl ?? opp.sourceUrl,
                explanation: nil,
                compensation: opp.compensation,
                duration: opp.timeCommitment,
                startDate: nil,
                matchPercentage: nil,
                matchAnalysis: nil,
                imageUrl: nil,
                organizationLogoUrl: nil,
                companyLogoName: nil,
                accentHex: nil
            )
        }
    }
    
    // MARK: - Opportunity Application Submission
    public func applyOpportunity(studentId: String, opportunityId: String) async throws -> ApplyResponse {
        guard let url = URL(string: "\(baseURL)/api/opportunities/\(opportunityId)/apply") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        await applyAuthHeader(to: &request)
        
        let body: [String: Any] = [
            "student_id": studentId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(ApplyResponse.self, from: data)
    }
    
    // MARK: - AI Match Chatbot (Calls Echelon Agent Service)
    public func sendChatMessage(
        opportunityId: String,
        studentId: String,
        message: String,
        context: OpportunityChatContext
    ) async throws -> String {
        // Backend agent conversational endpoint
        if let agentURL = URL(string: "\(baseURL)/api/agent/chat") {
            var request = URLRequest(url: agentURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15.0
            await applyAuthHeader(to: &request)
            
            let payload: [String: Any] = [
                "message": message
            ]
            if let bodyData = try? JSONSerialization.data(withJSONObject: payload) {
                request.httpBody = bodyData
                if let (data, resp) = try? await session.data(for: request),
                   let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let reply = json["reply"] as? String, !reply.isEmpty {
                    return reply
                }
            }
        }
        
        // Fallback to legacy chat route if deployed
        if let chatURL = URL(string: "\(baseURL)/api/chat") {
            var request = URLRequest(url: chatURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0
            await applyAuthHeader(to: &request)
            
            let payload: [String: Any] = [
                "opportunity_id": opportunityId,
                "student_id": studentId,
                "message": message,
                "opportunity_title": context.opportunityTitle,
                "organization": context.organization
            ]
            if let bodyData = try? JSONSerialization.data(withJSONObject: payload) {
                request.httpBody = bodyData
                if let (data, resp) = try? await session.data(for: request),
                   let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let reply = json["reply"] as? String ?? json["message"] as? String, !reply.isEmpty {
                    return reply
                }
            }
        }
        
        throw APIError.requestFailed(statusCode: 500, message: "Agent chat service unavailable.")
    }
    
    // MARK: - Resume Parsing (PDF Upload to /api/profile/parse)
    public func parseResume(pdfData: Data, fileName: String) async throws -> ParsedResumeData {
        guard let url = URL(string: "\(baseURL)/api/profile/parse") else {
            throw APIError.invalidURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        await applyAuthHeader(to: &request)
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"resume\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(pdfData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(ParsedResumeData.self, from: data)
    }
    
    // MARK: - Fetch Current Profile from Backend / Databricks
    public func fetchCurrentProfile() async throws -> StudentProfile {
        guard let url = URL(string: "\(baseURL)/api/profile/me") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        await applyAuthHeader(to: &request)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(StudentProfile.self, from: data)
    }
    
    // MARK: - Student Profile Updates & Account Deletion
    public func updateStudentProfile(studentId: String, profile: StudentProfile) async throws {
        guard let url = URL(string: "\(baseURL)/api/profile") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8.0
        await applyAuthHeader(to: &request)
        
        let payload: [String: Any] = [
            "major": profile.major,
            "graduation_year": profile.graduationYear,
            "skills": profile.skills,
            "interests": profile.skills,
            "coursework": profile.coursework,
            "experience": profile.experience,
            "bio": profile.bio ?? ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    public func deleteAccount(studentId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/students/\(studentId)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        await applyAuthHeader(to: &request)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    // MARK: - Auth Verification
    public func verifyAuthMe(token: String) async throws -> AuthMeResponse {
        guard let url = URL(string: "\(baseURL)/api/auth/me") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder().decode(AuthMeResponse.self, from: data)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
