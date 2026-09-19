import Foundation

struct StudentProfile: Codable, Identifiable {
    let id: String
    let major: String
    let graduationYear: Int
    let skills: [String]
    let interests: [String]
    let coursework: [String]
    let experience: [String]
    let bio: String?
    let profileText: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, major, skills, interests, coursework, experience, bio
        case graduationYear = "graduation_year"
        case profileText = "profile_text"
        case createdAt = "created_at"
    }
}

struct OpportunityCard: Codable, Identifiable {
    let id: String
    let title: String
    let organization: String
    let opportunityType: String
    let description: String
    let skills: [String]
    let location: String?
    let paid: Bool?
    let deadline: String?
    let applyUrl: String?
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case id, title, organization, description, skills, location, paid, deadline, explanation
        case opportunityType = "opportunity_type"
        case applyUrl = "apply_url"
    }
}

struct SwipeResponse: Codable, Identifiable {
    let id: String
    let studentId: String
    let opportunityId: String
    let direction: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, direction
        case studentId = "student_id"
        case opportunityId = "opportunity_id"
        case createdAt = "created_at"
    }
}

struct HealthResponse: Codable {
    let status: String
}

