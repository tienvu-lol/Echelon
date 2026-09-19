import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(String)
    case decodingError
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Change this to your Windows machine's local IP (e.g., "http://192.168.1.100:8000") when testing on a physical device.
    // Use "http://localhost:8000" if running in the iOS Simulator on the same machine running the backend.
    private let baseURL = "http://localhost:8000"
    
    private init() {}
    
    func healthCheck() async throws -> HealthResponse {
        return try await fetch(endpoint: "/health")
    }
    
    func getRecommendations(studentId: String, limit: Int = 10) async throws -> [OpportunityCard] {
        struct RecResponse: Codable {
            let student_id: String
            let opportunities: [OpportunityCard]
        }
        let res: RecResponse = try await fetch(endpoint: "/api/opportunities/recommendations?student_id=\(studentId)&limit=\(limit)")
        return res.opportunities
    }
    
    func recordSwipe(studentId: String, opportunityId: String, direction: String) async throws -> SwipeResponse {
        let body = [
            "student_id": studentId,
            "opportunity_id": opportunityId,
            "direction": direction
        ]
        return try await post(endpoint: "/api/swipes", body: body)
    }
    
    // MARK: - Helpers
    
    private func fetch<T: Codable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw APIError.requestFailed(errorMsg)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
    
    private func post<T: Codable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw APIError.requestFailed(errorMsg)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}

