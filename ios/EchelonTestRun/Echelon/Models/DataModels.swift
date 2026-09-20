import Foundation

// MARK: - Core Data Models

struct StudentProfile: Codable, Identifiable, Equatable {
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

struct OpportunityCard: Codable, Identifiable, Equatable, Hashable {
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
    
    // UI Enhancements
    let compensation: String?
    let duration: String?
    let matchPercentage: Int?
    let companyLogoName: String?
    let accentHex: String?

    enum CodingKeys: String, CodingKey {
        case id, title, organization, description, skills, location, paid, deadline, explanation
        case opportunityType = "opportunity_type"
        case applyUrl = "apply_url"
        case compensation, duration
        case matchPercentage = "match_percentage"
        case companyLogoName = "company_logo_name"
        case accentHex = "accent_hex"
    }

    init(
        id: String,
        title: String,
        organization: String,
        opportunityType: String,
        description: String,
        skills: [String],
        location: String? = nil,
        paid: Bool? = true,
        deadline: String? = nil,
        applyUrl: String? = nil,
        explanation: String? = nil,
        compensation: String? = nil,
        duration: String? = nil,
        matchPercentage: Int? = nil,
        companyLogoName: String? = nil,
        accentHex: String? = nil
    ) {
        self.id = id
        self.title = title
        self.organization = organization
        self.opportunityType = opportunityType
        self.description = description
        self.skills = skills
        self.location = location
        self.paid = paid
        self.deadline = deadline
        self.applyUrl = applyUrl
        self.explanation = explanation
        self.compensation = compensation
        self.duration = duration
        self.matchPercentage = matchPercentage
        self.companyLogoName = companyLogoName
        self.accentHex = accentHex
    }
}

struct MatchedOpportunity: Identifiable, Equatable, Hashable {
    let id: String
    let organization: String
    let title: String
    let opportunityType: String
    let iconSystemName: String
    let accentColorHex: String
    let applyUrl: String?
}

struct StudentStats: Equatable, Hashable {
    let exploredCount: Int
    let appliedCount: Int
    let interviewsCount: Int
}

struct SearchPreferences: Equatable, Hashable {
    let opportunityType: String
    let startDate: String
    let minPay: String
    let location: String
    let gpa: String
}

struct UserProfile: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let headline: String
    let ratingStars: Double
    let gpa: Double
    let bio: String
    let stats: StudentStats
    let skills: [String]
    let preferences: SearchPreferences
}

struct SwipeResponse: Codable, Identifiable, Equatable {
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

struct HealthResponse: Codable, Equatable {
    let status: String
}

struct AuthMeResponse: Codable, Equatable {
    let status: String
    let uid: String?
    let email: String?
}

// MARK: - Dummy / Mock Data for Visual Fidelity

extension OpportunityCard {
    static let mockDeck: [OpportunityCard] = [
        OpportunityCard(
            id: "opp-1",
            title: "Summer Research Program",
            organization: "MIT Lincoln Lab",
            opportunityType: "REU",
            description: "Undergraduate research in advanced defense systems. Work alongside staff researchers on radar, communications, and cyber security projects.",
            skills: ["Signal Processing", "MATLAB", "Python", "Radar"],
            location: "Lexington, MA",
            paid: true,
            deadline: "Feb 28, 2027",
            applyUrl: "https://www.ll.mit.edu",
            explanation: "High alignment with your systems and ML background",
            compensation: "$700/week",
            duration: "10 weeks",
            matchPercentage: 76,
            companyLogoName: "shield.lefthalf.filled",
            accentHex: "#22C55E"
        ),
        OpportunityCard(
            id: "opp-2",
            title: "Software Dev Intern",
            organization: "Amazon",
            opportunityType: "Internship",
            description: "Build scalable cloud services powering AWS. Collaborate with senior engineers on high-throughput distributed systems and customer-facing APIs.",
            skills: ["Java", "AWS", "Distributed Systems", "Docker"],
            location: "Seattle, WA",
            paid: true,
            deadline: "Mar 15, 2027",
            applyUrl: "https://amazon.jobs",
            explanation: "Matches your cloud computing and backend focus",
            compensation: "$9,500/mo",
            duration: "12 weeks",
            matchPercentage: 88,
            companyLogoName: "shippingbox.fill",
            accentHex: "#F59E0B"
        ),
        OpportunityCard(
            id: "opp-3",
            title: "AI Research Resident",
            organization: "Google DeepMind",
            opportunityType: "Fellowship",
            description: "Conduct cutting-edge research in foundation models, reinforcement learning, and autonomous agent evaluation with top research scientists.",
            skills: ["Python", "PyTorch", "ML", "C++"],
            location: "Mountain View, CA",
            paid: true,
            deadline: "Mar 30, 2027",
            applyUrl: "https://deepmind.google",
            explanation: "Superb fit for your autonomy and applied ML background",
            compensation: "$11,000/mo",
            duration: "16 weeks",
            matchPercentage: 94,
            companyLogoName: "sparkles",
            accentHex: "#3B82F6"
        ),
        OpportunityCard(
            id: "opp-4",
            title: "Autonomy Systems Intern",
            organization: "Waymo",
            opportunityType: "Internship",
            description: "Develop perception and motion planning algorithms for self-driving vehicles operating in urban environments.",
            skills: ["C++", "ROS", "Computer Vision", "Python"],
            location: "San Francisco, CA",
            paid: true,
            deadline: "Apr 01, 2027",
            applyUrl: "https://waymo.com/careers",
            explanation: "Directly leverages your YC startup robotics experience",
            compensation: "$10,200/mo",
            duration: "12 weeks",
            matchPercentage: 91,
            companyLogoName: "car.fill",
            accentHex: "#10B981"
        ),
        OpportunityCard(
            id: "opp-5",
            title: "Firmware Engineering Intern",
            organization: "Apple",
            opportunityType: "Internship",
            description: "Design low-level software and driver architecture for next-generation hardware platforms and spatial computing devices.",
            skills: ["C", "C++", "Embedded Systems", "Swift"],
            location: "Cupertino, CA",
            paid: true,
            deadline: "Apr 15, 2027",
            applyUrl: "https://apple.com/jobs",
            compensation: "$9,800/mo",
            duration: "12 weeks",
            matchPercentage: 83,
            companyLogoName: "apple.logo",
            accentHex: "#E2E8F0"
        ),
        OpportunityCard(
            id: "opp-6",
            title: "Space Systems Researcher",
            organization: "NASA JPL",
            opportunityType: "REU",
            description: "Investigate autonomous rover path-planning and communication protocols for planetary exploration missions.",
            skills: ["Python", "MATLAB", "Robotics", "Linux"],
            location: "Pasadena, CA",
            paid: true,
            deadline: "May 01, 2027",
            applyUrl: "https://jpl.nasa.gov",
            compensation: "$800/week",
            duration: "10 weeks",
            matchPercentage: 86,
            companyLogoName: "paperplane.fill",
            accentHex: "#F97316"
        ),
        OpportunityCard(
            id: "opp-7",
            title: "Infrastructure Intern",
            organization: "Stripe",
            opportunityType: "Internship",
            description: "Scale high-reliability payment infrastructure processing billions in global economic volume each day.",
            skills: ["Go", "Distributed Systems", "SQL", "Docker"],
            location: "San Francisco, CA",
            paid: true,
            deadline: "May 10, 2027",
            applyUrl: "https://stripe.com/jobs",
            compensation: "$10,500/mo",
            duration: "12 weeks",
            matchPercentage: 89,
            companyLogoName: "bolt.fill",
            accentHex: "#6366F1"
        )
    ]
}

extension MatchedOpportunity {
    static let mockMatches: [MatchedOpportunity] = [
        MatchedOpportunity(
            id: "match-1",
            organization: "Apple",
            title: "Software Engineering Intern",
            opportunityType: "Internship",
            iconSystemName: "apple.logo",
            accentColorHex: "#E2E8F0",
            applyUrl: "https://apple.com"
        ),
        MatchedOpportunity(
            id: "match-2",
            organization: "NSF",
            title: "Computer Science REU",
            opportunityType: "REU",
            iconSystemName: "microscope",
            accentColorHex: "#06B6D4",
            applyUrl: "https://nsf.gov"
        ),
        MatchedOpportunity(
            id: "match-3",
            organization: "Stripe",
            title: "Backend Engineering Intern",
            opportunityType: "Internship",
            iconSystemName: "bolt.fill",
            accentColorHex: "#6366F1",
            applyUrl: "https://stripe.com"
        ),
        MatchedOpportunity(
            id: "match-4",
            organization: "NASA JPL",
            title: "Robotics Software Fellow",
            opportunityType: "Fellowship",
            iconSystemName: "paperplane.fill",
            accentColorHex: "#F59E0B",
            applyUrl: "https://jpl.nasa.gov"
        )
    ]
}

extension UserProfile {
    static let mockProfile = UserProfile(
        name: "Alex Chen",
        headline: "CS Junior · Stanford University",
        ratingStars: 4.8,
        gpa: 3.92,
        bio: "Passionate about systems engineering and applied ML. Previously built autonomy software at a YC startup. Seeking research or engineering roles in AI infrastructure.",
        stats: StudentStats(
            exploredCount: 24,
            appliedCount: 8,
            interviewsCount: 3
        ),
        skills: [
            "React", "TypeScript", "Python", "Node.js", "SQL",
            "Git", "Docker", "AWS", "Swift", "C++"
        ],
        preferences: SearchPreferences(
            opportunityType: "Internship, REU",
            startDate: "Summer 2027",
            minPay: "$6,000/mo",
            location: "SF Bay Area · Remote",
            gpa: "3.92 / 4.0"
        )
    )
}
