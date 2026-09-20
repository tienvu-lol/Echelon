import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(String)
    case decodingError(Error?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The requested URL is invalid."
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .decodingError(let error):
            if let error = error {
                return "Failed to decode response: \(error.localizedDescription)"
            }
            return "Failed to decode response."
        }
    }
}

final class APIService {
    static let shared = APIService()
    
    // Change this to your Windows machine's local IP (e.g., "http://192.168.1.100:8000") when testing on a physical device.
    // Use "http://localhost:8000" if running in the iOS Simulator on the same machine running the backend.
    private let baseURL = "http://localhost:8000"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    func healthCheck() async throws -> HealthResponse {
        return try await fetch(endpoint: "/health")
    }
    
    func getRecommendations(studentId: String, limit: Int = 10) async throws -> [OpportunityCard] {
        struct RecResponse: Codable {
            let student_id: String
            let opportunities: [OpportunityCard]
        }
        
        let queryItems = [
            URLQueryItem(name: "student_id", value: studentId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        let res: RecResponse = try await fetch(endpoint: "/api/opportunities/recommendations", queryItems: queryItems)
        return res.opportunities
    }
    
    func recordSwipe(studentId: String, opportunityId: String, direction: String) async throws -> SwipeResponse {
        let body: [String: String] = [
            "student_id": studentId,
            "opportunity_id": opportunityId,
            "direction": direction
        ]
        return try await post(endpoint: "/api/swipes", body: body)
    }
    
    // MARK: - Auth & Session Endpoints
    
    func verifyAuthMe(token: String) async throws -> AuthMeResponse {
        let headers = ["Authorization": "Bearer \(token)"]
        return try await fetch(endpoint: "/api/auth/me", headers: headers)
    }
    
    // MARK: - Networking Helpers
    
    private func fetch<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw APIError.requestFailed(errorMsg)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    private func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw APIError.requestFailed(errorMsg)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

