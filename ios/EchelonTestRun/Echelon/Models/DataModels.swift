import Foundation

// MARK: - Core Data Models

// MARK: - Application & Interaction Enums

public enum OpportunityInteraction: String, Codable, Equatable {
    case unseen
    case passed
    case matched
}

public enum ApplicationStatus: String, Codable, Equatable {
    case notApplied = "not_applied"
    case applied = "applied"
}

// MARK: - Match Analysis

public struct MatchAnalysis: Codable, Equatable, Hashable {
    public let overallMatch: Int?
    public let skillsMatch: Int?
    public let courseworkMatch: Int?
    public let experienceMatch: Int?
    public let preferencesMatch: Int?
    public let explanation: String?

    public enum CodingKeys: String, CodingKey {
        case overallMatch = "overall_match"
        case skillsMatch = "skills_match"
        case courseworkMatch = "coursework_match"
        case experienceMatch = "experience_match"
        case preferencesMatch = "preferences_match"
        case explanation
    }

    public init(
        overallMatch: Int? = nil,
        skillsMatch: Int? = nil,
        courseworkMatch: Int? = nil,
        experienceMatch: Int? = nil,
        preferencesMatch: Int? = nil,
        explanation: String? = nil
    ) {
        self.overallMatch = overallMatch
        self.skillsMatch = skillsMatch
        self.courseworkMatch = courseworkMatch
        self.experienceMatch = experienceMatch
        self.preferencesMatch = preferencesMatch
        self.explanation = explanation
    }
}

// MARK: - Backend Recommendation Models

public struct CareerTrackAffinity: Codable, Equatable, Hashable {
    public let track: String
    public let weight: Double

    public init(track: String, weight: Double) {
        self.track = track
        self.weight = weight
    }
}

public struct Opportunity: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let organization: String
    public let opportunityType: String
    public let description: String
    public let sourceUrl: String
    public let sourceName: String?
    public let sourceAge: String?
    public let active: Bool
    public let firstSeenAt: String?
    public let lastSeenAt: String?
    public let skills: [String]
    public let interests: [String]
    public let eligibility: [String]
    public let majors: [String]
    public let classYears: [String]
    public let schoolRestrictions: [String]
    public let eligibilityNotes: [String]
    public let degreeLevels: [String]
    public let workAuthorizationRequirements: [String]
    public let careerTracks: [CareerTrackAffinity]
    public let location: String?
    public let remoteStatus: String?
    public let timeCommitment: String?
    public let compensation: String?
    public let deadline: String?
    public let applyUrl: String?
    public let contactName: String?
    public let contactEmail: String?

    enum CodingKeys: String, CodingKey {
        case id, title, organization, description, active, skills, interests
        case eligibility, majors, location, compensation, deadline
        case opportunityType = "opportunity_type"
        case sourceUrl = "source_url"
        case sourceName = "source_name"
        case sourceAge = "source_age"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
        case classYears = "class_years"
        case schoolRestrictions = "school_restrictions"
        case eligibilityNotes = "eligibility_notes"
        case degreeLevels = "degree_levels"
        case workAuthorizationRequirements = "work_authorization_requirements"
        case careerTracks = "career_tracks"
        case remoteStatus = "remote_status"
        case timeCommitment = "time_commitment"
        case applyUrl = "apply_url"
        case contactName = "contact_name"
        case contactEmail = "contact_email"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.organization = try container.decode(String.self, forKey: .organization)
        self.opportunityType = (try? container.decodeIfPresent(String.self, forKey: .opportunityType)) ?? "Internship"
        self.description = (try? container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        self.sourceUrl = (try? container.decodeIfPresent(String.self, forKey: .sourceUrl)) ?? ""
        self.sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        self.sourceAge = try container.decodeIfPresent(String.self, forKey: .sourceAge)
        self.active = (try? container.decodeIfPresent(Bool.self, forKey: .active)) ?? true
        self.firstSeenAt = try container.decodeIfPresent(String.self, forKey: .firstSeenAt)
        self.lastSeenAt = try container.decodeIfPresent(String.self, forKey: .lastSeenAt)
        self.skills = (try? container.decodeIfPresent([String].self, forKey: .skills)) ?? []
        self.interests = (try? container.decodeIfPresent([String].self, forKey: .interests)) ?? []
        self.eligibility = (try? container.decodeIfPresent([String].self, forKey: .eligibility)) ?? []
        self.majors = (try? container.decodeIfPresent([String].self, forKey: .majors)) ?? []
        self.classYears = (try? container.decodeIfPresent([String].self, forKey: .classYears)) ?? []
        self.schoolRestrictions = (try? container.decodeIfPresent([String].self, forKey: .schoolRestrictions)) ?? []
        self.eligibilityNotes = (try? container.decodeIfPresent([String].self, forKey: .eligibilityNotes)) ?? []
        self.degreeLevels = (try? container.decodeIfPresent([String].self, forKey: .degreeLevels)) ?? []
        self.workAuthorizationRequirements = (try? container.decodeIfPresent([String].self, forKey: .workAuthorizationRequirements)) ?? []
        self.careerTracks = (try? container.decodeIfPresent([CareerTrackAffinity].self, forKey: .careerTracks)) ?? []
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.remoteStatus = try container.decodeIfPresent(String.self, forKey: .remoteStatus)
        self.timeCommitment = try container.decodeIfPresent(String.self, forKey: .timeCommitment)
        self.compensation = try container.decodeIfPresent(String.self, forKey: .compensation)
        self.deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        self.applyUrl = try container.decodeIfPresent(String.self, forKey: .applyUrl)
        self.contactName = try container.decodeIfPresent(String.self, forKey: .contactName)
        self.contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail)
    }
}

public struct RecommendationItem: Codable, Identifiable, Equatable, Hashable {
    public let opportunity: Opportunity
    public let score: Double
    public let matchReason: String
    public let matchedTraits: [String]
    public let gaps: [String]
    public let careerTrackFit: [String]
    public let eligibilityStatus: String
    public let eligibilityNotes: [String]

    public var id: String { opportunity.id }

    enum CodingKeys: String, CodingKey {
        case opportunity, score, gaps
        case matchReason = "match_reason"
        case matchedTraits = "matched_traits"
        case careerTrackFit = "career_track_fit"
        case eligibilityStatus = "eligibility_status"
        case eligibilityNotes = "eligibility_notes"
    }

    public var card: OpportunityCard {
        OpportunityCard(
            id: opportunity.id,
            title: opportunity.title,
            organization: opportunity.organization,
            opportunityType: opportunity.opportunityType,
            description: opportunity.description,
            fullDescription: opportunity.description,
            skills: opportunity.skills,
            preferredSkills: opportunity.interests,
            qualifications: opportunity.eligibility,
            responsibilities: nil,
            coursework: opportunity.majors,
            location: opportunity.location,
            workMode: opportunity.remoteStatus,
            paid: opportunity.compensation != nil,
            deadline: opportunity.deadline,
            applyUrl: opportunity.applyUrl ?? opportunity.sourceUrl,
            explanation: matchReason,
            compensation: opportunity.compensation,
            duration: opportunity.timeCommitment,
            startDate: nil,
            matchPercentage: min(100, max(0, Int(score.rounded()))),
            matchAnalysis: MatchAnalysis(
                overallMatch: min(100, max(0, Int(score.rounded()))),
                skillsMatch: min(100, max(0, Int(score.rounded()))),
                courseworkMatch: nil,
                experienceMatch: nil,
                preferencesMatch: nil,
                explanation: matchReason
            ),
            imageUrl: nil,
            organizationLogoUrl: nil,
            companyLogoName: nil,
            accentHex: nil
        )
    }
}

public struct RecommendationsResponse: Codable, Equatable {
    public let studentId: String
    public let opportunities: [RecommendationItem]

    enum CodingKeys: String, CodingKey {
        case opportunities
        case studentId = "student_id"
    }
}

// MARK: - Resume Models

public struct ParsedResumeData: Codable, Equatable, Hashable {
    public var name: String?
    public var email: String?
    public var phoneNumber: String?
    public var university: String?
    public var major: String?
    public var minor: String?
    public var degree: String?
    public var graduationYear: Int?
    public var gpa: Double?
    public var skills: [String]?
    public var coursework: [String]?
    public var experience: [String]?

    public enum CodingKeys: String, CodingKey {
        case name, email, university, major, minor, degree, gpa, skills, coursework, experience
        case phoneNumber = "phone_number"
        case graduationYear = "graduation_year"
        case classYear = "class_year"
    }

    public init(
        name: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        university: String? = nil,
        major: String? = nil,
        minor: String? = nil,
        degree: String? = nil,
        graduationYear: Int? = nil,
        gpa: Double? = nil,
        skills: [String]? = nil,
        coursework: [String]? = nil,
        experience: [String]? = nil
    ) {
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.university = university
        self.major = major
        self.minor = minor
        self.degree = degree
        self.graduationYear = graduationYear
        self.gpa = gpa
        self.skills = skills
        self.coursework = coursework
        self.experience = experience
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.university = try container.decodeIfPresent(String.self, forKey: .university)
        self.major = try container.decodeIfPresent(String.self, forKey: .major)
        self.minor = try container.decodeIfPresent(String.self, forKey: .minor)
        self.degree = try container.decodeIfPresent(String.self, forKey: .degree)
        self.gpa = try container.decodeIfPresent(Double.self, forKey: .gpa)
        self.skills = try container.decodeIfPresent([String].self, forKey: .skills)
        self.coursework = try container.decodeIfPresent([String].self, forKey: .coursework)
        self.experience = try container.decodeIfPresent([String].self, forKey: .experience)

        if let gradInt = try? container.decodeIfPresent(Int.self, forKey: .graduationYear) {
            self.graduationYear = gradInt
        } else if let gradStr = try? container.decodeIfPresent(String.self, forKey: .graduationYear), let parsed = Int(gradStr) {
            self.graduationYear = parsed
        } else if let classYearStr = try? container.decodeIfPresent(String.self, forKey: .classYear) {
            if let yearInt = Int(classYearStr) {
                self.graduationYear = yearInt
            } else {
                switch classYearStr.lowercased() {
                case "freshman": self.graduationYear = 2029
                case "sophomore": self.graduationYear = 2028
                case "junior": self.graduationYear = 2027
                case "senior": self.graduationYear = 2026
                default: self.graduationYear = 2027
                }
            }
        } else {
            self.graduationYear = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(university, forKey: .university)
        try container.encodeIfPresent(major, forKey: .major)
        try container.encodeIfPresent(minor, forKey: .minor)
        try container.encodeIfPresent(degree, forKey: .degree)
        try container.encodeIfPresent(graduationYear, forKey: .graduationYear)
        try container.encodeIfPresent(gpa, forKey: .gpa)
        try container.encodeIfPresent(skills, forKey: .skills)
        try container.encodeIfPresent(coursework, forKey: .coursework)
        try container.encodeIfPresent(experience, forKey: .experience)
    }
}

public struct Resume: Codable, Equatable, Hashable {
    public let id: String?
    public let fileName: String
    public let fileUrl: String?
    public let uploadedAt: Date?
    public var parsedData: ParsedResumeData?

    public enum CodingKeys: String, CodingKey {
        case id
        case fileName = "file_name"
        case fileUrl = "file_url"
        case uploadedAt = "uploaded_at"
        case parsedData = "parsed_data"
    }

    public init(
        id: String? = UUID().uuidString,
        fileName: String,
        fileUrl: String? = nil,
        uploadedAt: Date? = Date(),
        parsedData: ParsedResumeData? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.fileUrl = fileUrl
        self.uploadedAt = uploadedAt
        self.parsedData = parsedData
    }
}

// MARK: - Student Profile

public struct StudentProfile: Codable, Identifiable, Equatable {
    public var id: String
    public var name: String?
    public var email: String?
    public var phoneNumber: String?
    public var university: String?
    public var major: String
    public var minor: String?
    public var degree: String?
    public var graduationYear: Int
    public var gpa: Double?
    public var skills: [String]
    public var coursework: [String]
    public var experience: [String]
    public var interests: [String]
    public var fields: [String]
    public var workModePreferences: [String]
    public var locationPreferences: [String]
    public var compensationPreference: String?
    public var bio: String?
    public var profilePictureUrl: String?
    public var resume: Resume?
    public var createdAt: String?

    public enum CodingKeys: String, CodingKey {
        case id, name, email, university, major, minor, degree, gpa, skills, coursework, experience, interests, fields, bio
        case phoneNumber = "phone_number"
        case graduationYear = "graduation_year"
        case classYear = "class_year"
        case workModePreferences = "work_mode_preferences"
        case locationPreferences = "location_preferences"
        case compensationPreference = "compensation_preference"
        case profilePictureUrl = "profile_picture_url"
        case resume
        case createdAt = "created_at"
    }

    public init(
        id: String = UUID().uuidString,
        name: String? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        university: String? = "Virginia Tech",
        major: String = "Computer Science",
        minor: String? = nil,
        degree: String? = "Bachelor of Science",
        graduationYear: Int = 2027,
        gpa: Double? = 3.8,
        skills: [String] = [],
        coursework: [String] = [],
        experience: [String] = [],
        interests: [String] = ["Internship", "Research"],
        fields: [String] = ["Software Engineering", "AI/ML"],
        workModePreferences: [String] = ["Hybrid", "Remote", "In-Person"],
        locationPreferences: [String] = ["San Francisco, CA", "New York, NY", "Remote"],
        compensationPreference: String? = "$40/hr+",
        bio: String? = nil,
        profilePictureUrl: String? = nil,
        resume: Resume? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.university = university
        self.major = major
        self.minor = minor
        self.degree = degree
        self.graduationYear = graduationYear
        self.gpa = gpa
        self.skills = skills
        self.coursework = coursework
        self.experience = experience
        self.interests = interests
        self.fields = fields
        self.workModePreferences = workModePreferences
        self.locationPreferences = locationPreferences
        self.compensationPreference = compensationPreference
        self.bio = bio
        self.profilePictureUrl = profilePictureUrl
        self.resume = resume
        self.createdAt = createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.email = try container.decodeIfPresent(String.self, forKey: .email)
        self.phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        self.university = (try? container.decodeIfPresent(String.self, forKey: .university)) ?? "Virginia Tech"
        self.major = (try? container.decodeIfPresent(String.self, forKey: .major)) ?? "Computer Science"
        self.minor = try container.decodeIfPresent(String.self, forKey: .minor)
        self.degree = (try? container.decodeIfPresent(String.self, forKey: .degree)) ?? "Bachelor of Science"
        self.gpa = try container.decodeIfPresent(Double.self, forKey: .gpa) ?? 3.8
        self.skills = (try? container.decodeIfPresent([String].self, forKey: .skills)) ?? []
        self.coursework = (try? container.decodeIfPresent([String].self, forKey: .coursework)) ?? []
        self.experience = (try? container.decodeIfPresent([String].self, forKey: .experience)) ?? []
        self.interests = (try? container.decodeIfPresent([String].self, forKey: .interests)) ?? ["Internship", "Research"]
        self.fields = (try? container.decodeIfPresent([String].self, forKey: .fields)) ?? ["Software Engineering", "AI/ML"]
        self.workModePreferences = (try? container.decodeIfPresent([String].self, forKey: .workModePreferences)) ?? ["Hybrid", "Remote", "In-Person"]
        self.locationPreferences = (try? container.decodeIfPresent([String].self, forKey: .locationPreferences)) ?? ["San Francisco, CA", "New York, NY", "Remote"]
        self.compensationPreference = try container.decodeIfPresent(String.self, forKey: .compensationPreference) ?? "$40/hr+"
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl)
        self.resume = try container.decodeIfPresent(Resume.self, forKey: .resume)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)

        if let gradInt = try? container.decodeIfPresent(Int.self, forKey: .graduationYear) {
            self.graduationYear = gradInt
        } else if let gradStr = try? container.decodeIfPresent(String.self, forKey: .graduationYear), let parsed = Int(gradStr) {
            self.graduationYear = parsed
        } else if let classYearStr = try? container.decodeIfPresent(String.self, forKey: .classYear) {
            if let yearInt = Int(classYearStr) {
                self.graduationYear = yearInt
            } else {
                switch classYearStr.lowercased() {
                case "freshman": self.graduationYear = 2029
                case "sophomore": self.graduationYear = 2028
                case "junior": self.graduationYear = 2027
                case "senior": self.graduationYear = 2026
                default: self.graduationYear = 2027
                }
            }
        } else {
            self.graduationYear = 2027
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(university, forKey: .university)
        try container.encode(major, forKey: .major)
        try container.encodeIfPresent(minor, forKey: .minor)
        try container.encodeIfPresent(degree, forKey: .degree)
        try container.encode(graduationYear, forKey: .graduationYear)
        try container.encodeIfPresent(gpa, forKey: .gpa)
        try container.encode(skills, forKey: .skills)
        try container.encode(coursework, forKey: .coursework)
        try container.encode(experience, forKey: .experience)
        try container.encode(interests, forKey: .interests)
        try container.encode(fields, forKey: .fields)
        try container.encode(workModePreferences, forKey: .workModePreferences)
        try container.encode(locationPreferences, forKey: .locationPreferences)
        try container.encodeIfPresent(compensationPreference, forKey: .compensationPreference)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(profilePictureUrl, forKey: .profilePictureUrl)
        try container.encodeIfPresent(resume, forKey: .resume)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

// MARK: - Opportunity Card Model

public struct OpportunityCard: Codable, Identifiable, Equatable, Hashable {
    public var id: String
    public let title: String
    public let organization: String
    public let opportunityType: String
    public let description: String
    public let fullDescription: String?
    public let skills: [String]
    public let preferredSkills: [String]?
    public let qualifications: [String]?
    public let responsibilities: [String]?
    public let coursework: [String]?
    public let location: String?
    public let workMode: String?
    public let paid: Bool?
    public let deadline: String?
    public let applyUrl: String?
    public var explanation: String?
    public let compensation: String?
    public let duration: String?
    public let startDate: String?
    public var matchPercentage: Int?
    public let matchAnalysis: MatchAnalysis?
    public let imageUrl: String?
    public let organizationLogoUrl: String?
    public let companyLogoName: String?
    public let accentHex: String?

    public enum CodingKeys: String, CodingKey {
        case id, title, organization, description, skills, location, paid, deadline, explanation
        case fullDescription = "full_description"
        case opportunityType = "opportunity_type"
        case applyUrl = "apply_url"
        case compensation, duration
        case startDate = "start_date"
        case workMode = "work_mode"
        case preferredSkills = "preferred_skills"
        case qualifications, responsibilities, coursework
        case matchPercentage = "match_percentage"
        case matchAnalysis = "match_analysis"
        case imageUrl = "image_url"
        case organizationLogoUrl = "organization_logo_url"
        case companyLogoName = "company_logo_name"
        case accentHex = "accent_hex"
        case remoteStatus = "remote_status"
        case sourceUrl = "source_url"
        case timeCommitment = "time_commitment"
        case eligibility
    }

    public init(
        id: String,
        title: String,
        organization: String,
        opportunityType: String,
        description: String,
        fullDescription: String? = nil,
        skills: [String],
        preferredSkills: [String]? = nil,
        qualifications: [String]? = nil,
        responsibilities: [String]? = nil,
        coursework: [String]? = nil,
        location: String? = nil,
        workMode: String? = nil,
        paid: Bool? = true,
        deadline: String? = nil,
        applyUrl: String? = nil,
        explanation: String? = nil,
        compensation: String? = nil,
        duration: String? = nil,
        startDate: String? = nil,
        matchPercentage: Int? = nil,
        matchAnalysis: MatchAnalysis? = nil,
        imageUrl: String? = nil,
        organizationLogoUrl: String? = nil,
        companyLogoName: String? = nil,
        accentHex: String? = nil
    ) {
        self.id = id
        self.title = title
        self.organization = organization
        self.opportunityType = opportunityType
        self.description = description
        self.fullDescription = fullDescription
        self.skills = skills
        self.preferredSkills = preferredSkills
        self.qualifications = qualifications
        self.responsibilities = responsibilities
        self.coursework = coursework
        self.location = location
        self.workMode = workMode
        self.paid = paid
        self.deadline = deadline
        self.applyUrl = applyUrl
        self.explanation = explanation
        self.compensation = compensation
        self.duration = duration
        self.startDate = startDate
        self.matchPercentage = matchPercentage
        self.matchAnalysis = matchAnalysis
        self.imageUrl = imageUrl
        self.organizationLogoUrl = organizationLogoUrl
        self.companyLogoName = companyLogoName
        self.accentHex = accentHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.organization = try container.decode(String.self, forKey: .organization)
        self.opportunityType = try container.decodeIfPresent(String.self, forKey: .opportunityType) ?? "Internship"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.fullDescription = try container.decodeIfPresent(String.self, forKey: .fullDescription)
        self.skills = try container.decodeIfPresent([String].self, forKey: .skills) ?? []
        self.preferredSkills = try container.decodeIfPresent([String].self, forKey: .preferredSkills)
        self.qualifications = (try? container.decodeIfPresent([String].self, forKey: .qualifications)) ?? (try? container.decodeIfPresent([String].self, forKey: .eligibility))
        self.responsibilities = try container.decodeIfPresent([String].self, forKey: .responsibilities)
        self.coursework = try container.decodeIfPresent([String].self, forKey: .coursework)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)
        self.workMode = (try? container.decodeIfPresent(String.self, forKey: .workMode)) ?? (try? container.decodeIfPresent(String.self, forKey: .remoteStatus))
        self.paid = try container.decodeIfPresent(Bool.self, forKey: .paid)
        self.deadline = try container.decodeIfPresent(String.self, forKey: .deadline)
        self.applyUrl = (try? container.decodeIfPresent(String.self, forKey: .applyUrl)) ?? (try? container.decodeIfPresent(String.self, forKey: .sourceUrl))
        self.explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        self.compensation = try container.decodeIfPresent(String.self, forKey: .compensation)
        self.duration = (try? container.decodeIfPresent(String.self, forKey: .duration)) ?? (try? container.decodeIfPresent(String.self, forKey: .timeCommitment))
        self.startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        self.matchPercentage = try container.decodeIfPresent(Int.self, forKey: .matchPercentage)
        self.matchAnalysis = try container.decodeIfPresent(MatchAnalysis.self, forKey: .matchAnalysis)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.organizationLogoUrl = try container.decodeIfPresent(String.self, forKey: .organizationLogoUrl)
        self.companyLogoName = try container.decodeIfPresent(String.self, forKey: .companyLogoName)
        self.accentHex = try container.decodeIfPresent(String.self, forKey: .accentHex)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(organization, forKey: .organization)
        try container.encode(opportunityType, forKey: .opportunityType)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(fullDescription, forKey: .fullDescription)
        try container.encode(skills, forKey: .skills)
        try container.encodeIfPresent(preferredSkills, forKey: .preferredSkills)
        try container.encodeIfPresent(qualifications, forKey: .qualifications)
        try container.encodeIfPresent(responsibilities, forKey: .responsibilities)
        try container.encodeIfPresent(coursework, forKey: .coursework)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(workMode, forKey: .workMode)
        try container.encodeIfPresent(paid, forKey: .paid)
        try container.encodeIfPresent(deadline, forKey: .deadline)
        try container.encodeIfPresent(applyUrl, forKey: .applyUrl)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encodeIfPresent(compensation, forKey: .compensation)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(matchPercentage, forKey: .matchPercentage)
        try container.encodeIfPresent(matchAnalysis, forKey: .matchAnalysis)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(organizationLogoUrl, forKey: .organizationLogoUrl)
        try container.encodeIfPresent(companyLogoName, forKey: .companyLogoName)
        try container.encodeIfPresent(accentHex, forKey: .accentHex)
    }
}

// MARK: - Opportunity Batch Response

public struct OpportunityBatch: Codable, Equatable {
    public let opportunities: [OpportunityCard]
    public let canRefresh: Bool
    public let refreshesRemaining: Int
    public let nextRefreshAvailableAt: Date?

    public enum CodingKeys: String, CodingKey {
        case opportunities
        case canRefresh = "can_refresh"
        case refreshesRemaining = "refreshes_remaining"
        case nextRefreshAvailableAt = "next_refresh_available_at"
    }

    public init(
        opportunities: [OpportunityCard],
        canRefresh: Bool = true,
        refreshesRemaining: Int = 3,
        nextRefreshAvailableAt: Date? = nil
    ) {
        self.opportunities = opportunities
        self.canRefresh = canRefresh
        self.refreshesRemaining = refreshesRemaining
        self.nextRefreshAvailableAt = nextRefreshAvailableAt
    }
}

// MARK: - Matched Opportunity Item

public struct MatchedOpportunity: Identifiable, Equatable, Hashable {
    public let id: String
    public let opportunity: OpportunityCard
    public var applicationStatus: ApplicationStatus
    public let matchedAt: Date
    public var appliedAt: Date?

    public var organization: String { opportunity.organization }
    public var title: String { opportunity.title }
    public var opportunityType: String { opportunity.opportunityType }
    public var iconSystemName: String { opportunity.companyLogoName ?? "sparkles" }
    public var accentColorHex: String { opportunity.accentHex ?? "#0A84FF" }
    public var applyUrl: String? { opportunity.applyUrl }
    public var logoUrl: String? { opportunity.organizationLogoUrl }

    public init(
        id: String,
        opportunity: OpportunityCard,
        applicationStatus: ApplicationStatus = .notApplied,
        matchedAt: Date = Date(),
        appliedAt: Date? = nil
    ) {
        self.id = id
        self.opportunity = opportunity
        self.applicationStatus = applicationStatus
        self.matchedAt = matchedAt
        self.appliedAt = appliedAt
    }
}

// MARK: - Chat Models

public enum ChatSender: String, Codable, Equatable {
    case user
    case ai
}

public enum ChatMessageStatus: String, Codable, Equatable {
    case sending
    case sent
    case error
}

public struct ChatMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let sender: ChatSender
    public let text: String
    public let timestamp: Date
    public var status: ChatMessageStatus

    public init(
        id: UUID = UUID(),
        sender: ChatSender,
        text: String,
        timestamp: Date = Date(),
        status: ChatMessageStatus = .sent
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.status = status
    }
}

public struct OpportunityChatContext: Codable {
    public let opportunityId: String
    public let opportunityTitle: String
    public let organization: String
    public let studentProfile: StudentProfile?
    public let matchAnalysis: MatchAnalysis?

    public init(
        opportunityId: String,
        opportunityTitle: String,
        organization: String,
        studentProfile: StudentProfile?,
        matchAnalysis: MatchAnalysis?
    ) {
        self.opportunityId = opportunityId
        self.opportunityTitle = opportunityTitle
        self.organization = organization
        self.studentProfile = studentProfile
        self.matchAnalysis = matchAnalysis
    }
}

// MARK: - Legacy / Auth Models

public struct StudentStats: Equatable, Hashable {
    public let exploredCount: Int
    public let appliedCount: Int
    public let interviewsCount: Int

    public init(exploredCount: Int, appliedCount: Int, interviewsCount: Int) {
        self.exploredCount = exploredCount
        self.appliedCount = appliedCount
        self.interviewsCount = interviewsCount
    }
}

public struct SearchPreferences: Equatable, Hashable {
    public let opportunityType: String
    public let startDate: String
    public let minPay: String
    public let location: String
    public let gpa: String

    public init(opportunityType: String, startDate: String, minPay: String, location: String, gpa: String) {
        self.opportunityType = opportunityType
        self.startDate = startDate
        self.minPay = minPay
        self.location = location
        self.gpa = gpa
    }
}

public struct UserProfile: Identifiable, Equatable {
    public var id: String { name }
    public var name: String
    public var headline: String
    public var ratingStars: Double
    public var gpa: Double
    public var bio: String
    public var stats: StudentStats
    public var skills: [String]
    public var preferences: SearchPreferences
    public var university: String?
    public var major: String?
    public var graduationYear: Int?
    public var coursework: [String]?
    public var experience: [String]?
    public var profilePictureUrl: String?
    public var resumeFileName: String?

    public init(
        name: String,
        headline: String,
        ratingStars: Double,
        gpa: Double,
        bio: String,
        stats: StudentStats,
        skills: [String],
        preferences: SearchPreferences,
        university: String? = nil,
        major: String? = nil,
        graduationYear: Int? = nil,
        coursework: [String]? = nil,
        experience: [String]? = nil,
        profilePictureUrl: String? = nil,
        resumeFileName: String? = nil
    ) {
        self.name = name
        self.headline = headline
        self.ratingStars = ratingStars
        self.gpa = gpa
        self.bio = bio
        self.stats = stats
        self.skills = skills
        self.preferences = preferences
        self.university = university
        self.major = major
        self.graduationYear = graduationYear
        self.coursework = coursework
        self.experience = experience
        self.profilePictureUrl = profilePictureUrl
        self.resumeFileName = resumeFileName
    }
}

public struct SwipeResponse: Codable, Identifiable, Equatable {
    public let id: String
    public let studentId: String
    public let opportunityId: String
    public let direction: String
    public let createdAt: String

    public enum CodingKeys: String, CodingKey {
        case id, direction
        case studentId = "student_id"
        case opportunityId = "opportunity_id"
        case createdAt = "created_at"
    }
}

public struct ApplyResponse: Codable, Equatable {
    public let success: Bool?
    public let message: String?

    public init(success: Bool? = true, message: String? = nil) {
        self.success = success
        self.message = message
    }
}

public struct HealthResponse: Codable, Equatable {
    public let status: String
}

public struct AuthMeResponse: Codable, Equatable {
    public let status: String
    public let uid: String?
    public let email: String?
}

// MARK: - Dummy / Fallback Mock Data for Visual Fidelity

extension OpportunityCard {
    public static let mockDeck: [OpportunityCard] = [
        OpportunityCard(
            id: "opp-1",
            title: "Summer Research Program",
            organization: "MIT Lincoln Lab",
            opportunityType: "REU",
            description: "Undergraduate research in advanced defense systems. Work alongside staff researchers on radar, communications, and cyber security projects.",
            fullDescription: "Join MIT Lincoln Laboratory's Summer Research Program. You will contribute to mission-critical technologies including radar systems, optical communications, and cybersecurity architectures. You'll work closely with full-time staff scientists and gain exposure to state-of-the-art laboratory facilities.",
            skills: ["Signal Processing", "MATLAB", "Python", "Radar"],
            preferredSkills: ["C++", "DSP", "Linux"],
            qualifications: [
                "Pursuing a BS or MS in Electrical Engineering, Computer Science, or Physics",
                "Minimum 3.5 GPA preferred",
                "US Citizenship required due to security clearance requirements"
            ],
            responsibilities: [
                "Develop and test novel signal processing algorithms in MATLAB/Python",
                "Run hardware-in-the-loop experiments on RF hardware testbeds",
                "Document technical findings and deliver a symposium presentation"
            ],
            coursework: ["Signals & Systems", "Probability & Statistics", "Algorithms"],
            location: "Lexington, MA",
            workMode: "In-Person",
            paid: true,
            deadline: "Feb 28, 2027",
            applyUrl: "https://www.ll.mit.edu",
            explanation: "High alignment with your systems and ML background",
            compensation: "$700/week",
            duration: "10 weeks",
            startDate: "June 2027",
            matchPercentage: 76,
            matchAnalysis: MatchAnalysis(
                overallMatch: 76,
                skillsMatch: 82,
                courseworkMatch: 75,
                experienceMatch: 70,
                preferencesMatch: 80,
                explanation: "Your strong background in Python and mathematics aligns well with defense system modeling."
            ),
            imageUrl: "https://images.unsplash.com/photo-1507668077129-56e32842fceb?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "shield.lefthalf.filled",
            accentHex: "#22C55E"
        ),
        OpportunityCard(
            id: "opp-2",
            title: "Software Dev Intern",
            organization: "Amazon",
            opportunityType: "Internship",
            description: "Build scalable cloud services powering AWS. Collaborate with senior engineers on high-throughput distributed systems and customer-facing APIs.",
            fullDescription: "As an Amazon SDE Intern on AWS, you'll own an end-to-end project from design to deployment. You will design, develop, and test high-scale distributed services that handle millions of requests per second.",
            skills: ["Java", "AWS", "Distributed Systems", "Docker"],
            preferredSkills: ["Kotlin", "DynamoDB", "CloudFormation"],
            qualifications: [
                "Currently enrolled in a Bachelor's or Master's in Computer Science or related field",
                "Experience with object-oriented programming (Java, C++, or Python)",
                "Solid understanding of data structures, algorithms, and complexity"
            ],
            responsibilities: [
                "Collaborate with experienced mentors to design and implement cloud microservices",
                "Write clean, unit-tested, and maintainable production code",
                "Participate in code reviews and operational metrics reviews"
            ],
            coursework: ["Data Structures", "Operating Systems", "Cloud Computing"],
            location: "Seattle, WA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Mar 15, 2027",
            applyUrl: "https://amazon.jobs",
            explanation: "Matches your cloud computing and backend focus",
            compensation: "$9,500/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 88,
            matchAnalysis: MatchAnalysis(
                overallMatch: 88,
                skillsMatch: 92,
                courseworkMatch: 88,
                experienceMatch: 85,
                preferencesMatch: 90,
                explanation: "Excellent match for your distributed systems coursework and AWS experience."
            ),
            imageUrl: "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "shippingbox.fill",
            accentHex: "#F59E0B"
        ),
        OpportunityCard(
            id: "opp-3",
            title: "AI Research Resident",
            organization: "Google DeepMind",
            opportunityType: "Fellowship",
            description: "Conduct cutting-edge research in foundation models, reinforcement learning, and autonomous agent evaluation with top research scientists.",
            fullDescription: "The Google DeepMind Research Residency is an intensive program designed to nurture the next generation of artificial intelligence researchers. You will work on open problems in generative models, multimodal understanding, and reinforcement learning.",
            skills: ["Python", "PyTorch", "ML", "C++"],
            preferredSkills: ["JAX", "Distributed Training", "CUDA"],
            qualifications: [
                "Degree in Computer Science, Mathematics, or computational science",
                "Hands-on experience implementing modern deep learning architectures",
                "Publications or major open-source research contributions are a plus"
            ],
            responsibilities: [
                "Formulate research hypotheses and design experimental benchmarks",
                "Train large-scale neural network models using TPU/GPU clusters",
                "Co-author papers targeted at conferences such as NeurIPS, ICML, or ICLR"
            ],
            coursework: ["Deep Learning", "Linear Algebra", "Machine Learning"],
            location: "Mountain View, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Mar 30, 2027",
            applyUrl: "https://deepmind.google",
            explanation: "Superb fit for your autonomy and applied ML background",
            compensation: "$11,000/mo",
            duration: "16 weeks",
            startDate: "June 2027",
            matchPercentage: 94,
            matchAnalysis: MatchAnalysis(
                overallMatch: 94,
                skillsMatch: 96,
                courseworkMatch: 92,
                experienceMatch: 94,
                preferencesMatch: 95,
                explanation: "Outstanding match with your PyTorch expertise and research trajectory in foundation models."
            ),
            imageUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "sparkles",
            accentHex: "#3B82F6"
        ),
        OpportunityCard(
            id: "opp-4",
            title: "Autonomy Systems Intern",
            organization: "Waymo",
            opportunityType: "Internship",
            description: "Develop perception and motion planning algorithms for self-driving vehicles operating in urban environments.",
            fullDescription: "Join Waymo's Autonomy Software team. You will work on real-time sensor fusion, lidar/camera object detection, and motion prediction for our fully autonomous commercial ride-hailing fleet.",
            skills: ["C++", "ROS", "Computer Vision", "Python"],
            preferredSkills: ["CUDA", "Point Cloud Processing", "Kalman Filtering"],
            qualifications: [
                "Proficiency in modern C++ (C++17 or later)",
                "Experience with robotics frameworks or computer vision pipelines",
                "Passion for autonomous vehicle safety and system reliability"
            ],
            responsibilities: [
                "Design and optimize high-efficiency perception components running on vehicle hardware",
                "Validate system behavior against large real-world driving simulation datasets",
                "Collaborate with safety and infrastructure engineering teams"
            ],
            coursework: ["Computer Vision", "Robotics", "Autonomous Systems"],
            location: "San Francisco, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "Apr 01, 2027",
            applyUrl: "https://waymo.com/careers",
            explanation: "Directly leverages your YC startup robotics experience",
            compensation: "$10,200/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 91,
            matchAnalysis: MatchAnalysis(
                overallMatch: 91,
                skillsMatch: 93,
                courseworkMatch: 90,
                experienceMatch: 92,
                preferencesMatch: 90,
                explanation: "Matches your robotics and C++ perception experience."
            ),
            imageUrl: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "car.fill",
            accentHex: "#10B981"
        ),
        OpportunityCard(
            id: "opp-5",
            title: "Firmware Engineering Intern",
            organization: "Apple",
            opportunityType: "Internship",
            description: "Design low-level software and driver architecture for next-generation hardware platforms and spatial computing devices.",
            fullDescription: "As an Apple Firmware Intern, you will work at the boundary of hardware and software. You will develop bare-metal firmware, device drivers, and low-latency communication protocols for Apple's cutting-edge products.",
            skills: ["C", "C++", "Embedded Systems", "Swift"],
            preferredSkills: ["ARM Assembly", "I2C/SPI", "RTOS"],
            qualifications: [
                "Enrolled in Electrical Engineering, Computer Engineering, or Computer Science",
                "Strong understanding of computer architecture and low-level memory management",
                "Comfort with oscilloscopes, logic analyzers, and hardware debugging"
            ],
            responsibilities: [
                "Write and test embedded firmware drivers for sensor subsystems",
                "Optimize power efficiency and latency profiles on custom silicon",
                "Collaborate with hardware design teams during board bring-up"
            ],
            coursework: ["Computer Architecture", "Embedded Systems", "Operating Systems"],
            location: "Cupertino, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "Apr 15, 2027",
            applyUrl: "https://apple.com/jobs",
            compensation: "$9,800/mo",
            duration: "12 weeks",
            startDate: "June 2027",
            matchPercentage: 83,
            matchAnalysis: MatchAnalysis(
                overallMatch: 83,
                skillsMatch: 85,
                courseworkMatch: 80,
                experienceMatch: 82,
                preferencesMatch: 86,
                explanation: "Good alignment with your low-level systems coursework."
            ),
            imageUrl: "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "apple.logo",
            accentHex: "#E2E8F0"
        ),
        OpportunityCard(
            id: "opp-6",
            title: "Space Systems Researcher",
            organization: "NASA JPL",
            opportunityType: "REU",
            description: "Investigate autonomous rover path-planning and communication protocols for planetary exploration missions.",
            fullDescription: "At the Jet Propulsion Laboratory, participate in planetary robotics research. You will study rover navigation algorithms in challenging simulated Martian terrain environments.",
            skills: ["Python", "MATLAB", "Robotics", "Linux"],
            preferredSkills: ["ROS", "Path Planning", "Simulation"],
            qualifications: [
                "Undergraduate student in STEM with strong interest in aerospace and robotics",
                "Experience with algorithmic path planning (A*, RRT, D*)",
                "U.S. Citizenship or Permanent Residency"
            ],
            responsibilities: [
                "Simulate rover traversal under high slip and rough terrain conditions",
                "Benchmark computational performance of trajectory optimization",
                "Present project results to NASA JPL scientific teams"
            ],
            coursework: ["Robotics", "Algorithms", "Calculus"],
            location: "Pasadena, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "May 01, 2027",
            applyUrl: "https://jpl.nasa.gov",
            compensation: "$800/week",
            duration: "10 weeks",
            startDate: "June 2027",
            matchPercentage: 86,
            matchAnalysis: MatchAnalysis(
                overallMatch: 86,
                skillsMatch: 88,
                courseworkMatch: 85,
                experienceMatch: 84,
                preferencesMatch: 88,
                explanation: "High alignment with your robotics and simulation background."
            ),
            imageUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "paperplane.fill",
            accentHex: "#F97316"
        ),
        OpportunityCard(
            id: "opp-7",
            title: "Infrastructure Intern",
            organization: "Stripe",
            opportunityType: "Internship",
            description: "Scale high-reliability payment infrastructure processing billions in global economic volume each day.",
            fullDescription: "Stripe infrastructure engineers build the distributed platforms that keep global commerce running 24/7/365. You'll work on database sharding, zero-downtime migrations, and distributed transaction pipelines.",
            skills: ["Go", "Distributed Systems", "SQL", "Docker"],
            preferredSkills: ["Kubernetes", "Kafka", "Observability"],
            qualifications: [
                "Enrolled in a Computer Science or related degree",
                "Solid foundation in networking, concurrency, and databases",
                "Strong communicator with a focus on code readability"
            ],
            responsibilities: [
                "Build resilient services for high-availability payment routing",
                "Design and run automated stress and fault injection tests",
                "Contribute to open source tooling and internal developer experience"
            ],
            coursework: ["Distributed Systems", "Database Systems", "Computer Networks"],
            location: "San Francisco, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "May 10, 2027",
            applyUrl: "https://stripe.com/jobs",
            compensation: "$10,500/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 89,
            matchAnalysis: MatchAnalysis(
                overallMatch: 89,
                skillsMatch: 91,
                courseworkMatch: 87,
                experienceMatch: 88,
                preferencesMatch: 92,
                explanation: "Strong fit for your backend infrastructure interest."
            ),
            imageUrl: "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "bolt.fill",
            accentHex: "#6366F1"
        ),
        OpportunityCard(
            id: "opp-8",
            title: "AI Alignment & Safety Fellow",
            organization: "OpenAI",
            opportunityType: "Fellowship",
            description: "Research alignment techniques, RLHF, and constitutional safety boundaries for frontier multimodal reasoning models.",
            fullDescription: "Join the OpenAI Safety & Alignment team. You will research automated alignment verification, reinforcement learning from human and AI feedback (RLHF/RLAIF), and interpretability methods to ensure frontier models remain helpful and safe.",
            skills: ["Python", "PyTorch", "RLHF", "Transformers"],
            preferredSkills: ["JAX", "Distributed Training", "CUDA"],
            qualifications: [
                "Pursuing a degree in Computer Science, Machine Learning, or related field",
                "Strong theoretical grounding in reinforcement learning and neural scaling",
                "Experience reading and reproducing cutting-edge ML research papers"
            ],
            responsibilities: [
                "Develop novel reward modeling and red-teaming benchmarks",
                "Run fine-tuning experiments across large transformer architectures",
                "Contribute to technical safety reports and academic publications"
            ],
            coursework: ["Machine Learning", "Deep Learning", "Probability & Statistics"],
            location: "San Francisco, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Apr 20, 2027",
            applyUrl: "https://openai.com/careers",
            explanation: "Excellent fit for your ML theory and deep learning foundation",
            compensation: "$11,500/mo",
            duration: "16 weeks",
            startDate: "June 2027",
            matchPercentage: 93,
            matchAnalysis: MatchAnalysis(
                overallMatch: 93,
                skillsMatch: 95,
                courseworkMatch: 92,
                experienceMatch: 90,
                preferencesMatch: 95,
                explanation: "Strong alignment with your deep learning and PyTorch background."
            ),
            imageUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "sparkles.rectangle.stack",
            accentHex: "#10A37F"
        ),
        OpportunityCard(
            id: "opp-9",
            title: "Quantitative Trading Systems Intern",
            organization: "Citadel",
            opportunityType: "Internship",
            description: "Architect ultra-low-latency execution engines, algorithmic order routers, and distributed market simulation clusters.",
            fullDescription: "As a Software Engineering Intern on Citadel's Core Execution platform, you will optimize latency-critical C++ infrastructure handling massive concurrent market data streams with sub-microsecond requirements.",
            skills: ["C++", "Linux", "Low Latency", "Algorithms"],
            preferredSkills: ["C++20", "Kernel Bypass", "Multi-threading"],
            qualifications: [
                "Degree in Computer Science, Computer Engineering, or Mathematics",
                "Exceptional mastery of C++ memory management and cache optimization",
                "Strong understanding of operating systems and networking"
            ],
            responsibilities: [
                "Optimize critical trading paths for sub-microsecond throughput",
                "Build hardware-accelerated telemetry and lock-free data structures",
                "Collaborate with quantitative researchers to deploy automated strategies"
            ],
            coursework: ["Computer Systems", "Operating Systems", "Algorithms"],
            location: "New York, NY",
            workMode: "In-Person",
            paid: true,
            deadline: "Apr 25, 2027",
            applyUrl: "https://www.citadel.com/careers",
            explanation: "Great match for your low-level systems and high-throughput background",
            compensation: "$14,000/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 90,
            matchAnalysis: MatchAnalysis(
                overallMatch: 90,
                skillsMatch: 92,
                courseworkMatch: 88,
                experienceMatch: 88,
                preferencesMatch: 92,
                explanation: "Matches your systems architecture coursework and C++ proficiency."
            ),
            imageUrl: "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "chart.xyaxis.line",
            accentHex: "#0284C7"
        ),
        OpportunityCard(
            id: "opp-10",
            title: "Autopilot Computer Vision Intern",
            organization: "Tesla",
            opportunityType: "Internship",
            description: "Develop end-to-end neural network models for occupancy networks, multi-camera tracking, and trajectory generation.",
            fullDescription: "Join the Tesla Autopilot vision team. You will train multi-task vision models operating across eight cameras in real-time, processing petabytes of fleet video data for full self-driving capabilities.",
            skills: ["Python", "C++", "PyTorch", "Computer Vision"],
            preferredSkills: ["TensorRT", "CUDA", "Sensor Fusion"],
            qualifications: [
                "Enrolled in Computer Science, Electrical Engineering, or Robotics",
                "Hands-on experience with modern convolutional and vision transformer architectures",
                "Familiarity with training neural nets on large-scale distributed clusters"
            ],
            responsibilities: [
                "Train 3D temporal vision networks for dynamic obstacle prediction",
                "Benchmark and optimize model inference latency on Tesla custom FSD silicon",
                "Validate model accuracy against tricky edge-case fleet interventions"
            ],
            coursework: ["Computer Vision", "Deep Learning", "Linear Algebra"],
            location: "Palo Alto, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "May 01, 2027",
            applyUrl: "https://www.tesla.com/careers",
            explanation: "Directly matches your computer vision and autonomous robotics focus",
            compensation: "$9,600/mo",
            duration: "12 weeks",
            startDate: "June 2027",
            matchPercentage: 88,
            matchAnalysis: MatchAnalysis(
                overallMatch: 88,
                skillsMatch: 90,
                courseworkMatch: 86,
                experienceMatch: 86,
                preferencesMatch: 90,
                explanation: "Your computer vision and perception projects align well with the Autopilot vision team."
            ),
            imageUrl: "https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "bolt.car.fill",
            accentHex: "#E11D48"
        ),
        OpportunityCard(
            id: "opp-11",
            title: "Cloud Systems & Kernel Research Intern",
            organization: "Microsoft Research",
            opportunityType: "Internship",
            description: "Investigate next-generation virtualization, eBPF telemetry, and AI cluster networking topologies for Azure.",
            fullDescription: "Microsoft Research Systems group explores the future of hyperscale cloud computing. You will research kernel optimizations, programmable switches (P4), and RDMA communication fabrics powering Azure AI supercomputers.",
            skills: ["Rust", "C", "Linux Kernel", "Distributed Systems"],
            preferredSkills: ["eBPF", "RDMA", "InfiniBand"],
            qualifications: [
                "Enrolled in an undergraduate or graduate degree in Computer Science",
                "Knowledge of operating system fundamentals, memory subsystems, and drivers",
                "Passion for foundational systems research"
            ],
            responsibilities: [
                "Implement kernel bypass drivers for low-latency AI interconnects",
                "Collect and analyze network congestion traces from multi-thousand GPU clusters",
                "Write research papers and open source tools"
            ],
            coursework: ["Operating Systems", "Networking", "Computer Architecture"],
            location: "Redmond, WA",
            workMode: "Hybrid",
            paid: true,
            deadline: "May 15, 2027",
            applyUrl: "https://www.microsoft.com/en-us/research/careers/",
            explanation: "Great match for your operating systems and networking expertise",
            compensation: "$10,000/mo",
            duration: "12 weeks",
            startDate: "June 2027",
            matchPercentage: 85,
            matchAnalysis: MatchAnalysis(
                overallMatch: 85,
                skillsMatch: 88,
                courseworkMatch: 84,
                experienceMatch: 80,
                preferencesMatch: 88,
                explanation: "Solid match for your systems coursework and systems programming experience."
            ),
            imageUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "server.rack",
            accentHex: "#00A4EF"
        ),
        OpportunityCard(
            id: "opp-12",
            title: "Robotic Manipulation Research Fellow",
            organization: "Stanford AI Lab",
            opportunityType: "REU",
            description: "Train diffusion-based vision-language-action (VLA) models for dexterous robotic manipulation and tactile feedback.",
            fullDescription: "At the Stanford Artificial Intelligence Laboratory (SAIL), collaborate with top robotics faculty. You will work on real bimanual robot arms executing complex household and industrial manipulation tasks via imitation learning.",
            skills: ["Python", "PyTorch", "Robotics", "Reinforcement Learning"],
            preferredSkills: ["ROS2", "MuJoCo", "Tactile Sensing"],
            qualifications: [
                "Undergraduate student in STEM with strong interest in robotics",
                "Proficiency in PyTorch and simulation environments (Isaac Gym / MuJoCo)",
                "Previous experience with robot kinematics and control"
            ],
            responsibilities: [
                "Collect teleoperated demonstration data using VR headsets",
                "Train policy networks with behavioral cloning and diffusion objectives",
                "Deploy and evaluate policies on physical robotic hardware testbeds"
            ],
            coursework: ["Robotics", "Reinforcement Learning", "Linear Algebra"],
            location: "Stanford, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "May 20, 2027",
            applyUrl: "https://ai.stanford.edu",
            explanation: "High alignment with your robotics background and ML residency aspirations",
            compensation: "$850/week",
            duration: "10 weeks",
            startDate: "June 2027",
            matchPercentage: 92,
            matchAnalysis: MatchAnalysis(
                overallMatch: 92,
                skillsMatch: 94,
                courseworkMatch: 90,
                experienceMatch: 90,
                preferencesMatch: 94,
                explanation: "Exceptional synergy between your robotics coursework and research focus."
            ),
            imageUrl: "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "hand.raised.fill",
            accentHex: "#8C1515"
        ),
        OpportunityCard(
            id: "opp-13",
            title: "Distributed Query Engine Intern",
            organization: "Databricks",
            opportunityType: "Internship",
            description: "Work on the Photon vectorized query engine, Apache Spark internals, and large-scale data lakehouse storage.",
            fullDescription: "Databricks engine team builds the core data processing runtime used by thousands of enterprises worldwide. You will write high-performance C++ vectorized execution primitives, query plan optimizers, and cache managers.",
            skills: ["C++", "Scala", "Distributed Systems", "SQL"],
            preferredSkills: ["LLVM", "SIMD", "Apache Arrow"],
            qualifications: [
                "Pursuing BS or MS in Computer Science or related engineering discipline",
                "Solid understanding of database internals, compilers, or distributed systems",
                "Strong grasp of concurrency and multithreading in C++"
            ],
            responsibilities: [
                "Design vectorized operators leveraging AVX-512 and ARM Neon SIMD intrinsics",
                "Profile memory latency and CPU cache misses on multi-terabyte analytical queries",
                "Participate in daily architecture design reviews and benchmarks"
            ],
            coursework: ["Database Systems", "Compilers", "Distributed Computing"],
            location: "San Francisco, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "May 25, 2027",
            applyUrl: "https://www.databricks.com/company/careers",
            explanation: "Directly matches your distributed systems and high-throughput data focus",
            compensation: "$10,800/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 87,
            matchAnalysis: MatchAnalysis(
                overallMatch: 87,
                skillsMatch: 89,
                courseworkMatch: 85,
                experienceMatch: 85,
                preferencesMatch: 89,
                explanation: "Great match for your interest in large-scale distributed systems and data engineering."
            ),
            imageUrl: "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "cube.transparent.fill",
            accentHex: "#FF3621"
        ),
        OpportunityCard(
            id: "opp-14",
            title: "Mission Software & Starship Guidance Intern",
            organization: "SpaceX",
            opportunityType: "Internship",
            description: "Implement flight-critical guidance, navigation, and control (GNC) flight software for reusable orbital launch vehicles.",
            fullDescription: "Join SpaceX Flight Software. You will write deterministic C++ code controlling Falcon and Starship vehicles during launch, orbit insertion, atmospheric reentry, and precision landing burns.",
            skills: ["C++", "Python", "Flight Software", "Simulation"],
            preferredSkills: ["Real-Time Linux", "Embedded Systems", "Aerospace GNC"],
            qualifications: [
                "Undergraduate student in Aerospace, Computer Science, or Computer Engineering",
                "Strong proficiency in modern C++ and real-time computing constraints",
                "US Citizenship or Permanent Resident status required by ITAR regulations"
            ],
            responsibilities: [
                "Develop guidance and flight logic for multi-engine vehicle maneuvers",
                "Execute hardware-in-the-loop (HITL) simulations testing fault tolerance",
                "Collaborate with propulsion and structures engineering leads"
            ],
            coursework: ["Control Systems", "Physics", "Algorithms"],
            location: "Hawthorne, CA",
            workMode: "In-Person",
            paid: true,
            deadline: "May 30, 2027",
            applyUrl: "https://www.spacex.com/careers",
            explanation: "Matches your high-reliability systems and flight simulation background",
            compensation: "$9,200/mo",
            duration: "12 weeks",
            startDate: "June 2027",
            matchPercentage: 89,
            matchAnalysis: MatchAnalysis(
                overallMatch: 89,
                skillsMatch: 90,
                courseworkMatch: 88,
                experienceMatch: 87,
                preferencesMatch: 91,
                explanation: "Strong fit for your physics, simulation, and real-time C++ background."
            ),
            imageUrl: "https://images.unsplash.com/photo-1517976487502-5f79e944c0dd?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "airplane.departure",
            accentHex: "#475569"
        ),
        OpportunityCard(
            id: "opp-15",
            title: "Constitutional AI & Alignment Researcher",
            organization: "Anthropic",
            opportunityType: "Fellowship",
            description: "Develop automated red-teaming protocols, interpretability probes, and constitutional principles for Claude models.",
            fullDescription: "Anthropic is dedicated to building reliable, beneficial artificial intelligence. As a research fellow, you will investigate how neural network representations represent concepts like honesty, sycophancy, and tool safety.",
            skills: ["Python", "PyTorch", "AI Safety", "NLP"],
            preferredSkills: ["TransformerLens", "Mechanistic Interpretability", "RL"],
            qualifications: [
                "Degree in Computer Science, Philosophy of Mind, or Cognitive Science",
                "Demonstrated track record of technical curiosity in AI safety",
                "Solid coding fundamentals in PyTorch or JAX"
            ],
            responsibilities: [
                "Train linear probes and dictionary learning models to extract internal features",
                "Design automated prompt perturbations testing alignment robustness",
                "Participate in weekly safety frontier discussions"
            ],
            coursework: ["Natural Language Processing", "Machine Learning", "Linear Algebra"],
            location: "San Francisco, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Jun 05, 2027",
            applyUrl: "https://www.anthropic.com/careers",
            explanation: "High alignment with your AI safety and language modeling focus",
            compensation: "$11,200/mo",
            duration: "14 weeks",
            startDate: "June 2027",
            matchPercentage: 91,
            matchAnalysis: MatchAnalysis(
                overallMatch: 91,
                skillsMatch: 92,
                courseworkMatch: 90,
                experienceMatch: 89,
                preferencesMatch: 93,
                explanation: "Great match for your NLP coursework and interest in frontier AI safety."
            ),
            imageUrl: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "brain.head.profile",
            accentHex: "#D97706"
        ),
        OpportunityCard(
            id: "opp-16",
            title: "Generative AI TensorRT Intern",
            organization: "NVIDIA",
            opportunityType: "Internship",
            description: "Optimize large language model inference pipelines and diffusion kernels on Blackwell GPU architectures.",
            fullDescription: "Join NVIDIA's Deep Learning Software organization. You will optimize inference performance for state-of-the-art transformer models using TensorRT-LLM, FlashAttention-3, and FP4 quantization techniques.",
            skills: ["CUDA", "C++", "Python", "GPU Computing"],
            preferredSkills: ["Triton", "Cutlass", "Kernel Profiling"],
            qualifications: [
                "Pursuing a degree in Electrical Engineering, Computer Engineering, or Computer Science",
                "Familiarity with GPU parallel programming paradigms and memory hierarchy",
                "Experience debugging CUDA kernels using Nsight Compute"
            ],
            responsibilities: [
                "Implement customized fused attention and matrix multiplication kernels",
                "Benchmark end-to-end token generation latency on DGX SuperPOD systems",
                "Contribute optimizations to NVIDIA open-source deep learning libraries"
            ],
            coursework: ["Parallel Computing", "Computer Architecture", "Deep Learning"],
            location: "Santa Clara, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Jun 10, 2027",
            applyUrl: "https://www.nvidia.com/en-us/about-nvidia/careers/",
            explanation: "Top tier alignment with your CUDA and high-performance computing experience",
            compensation: "$10,600/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 92,
            matchAnalysis: MatchAnalysis(
                overallMatch: 92,
                skillsMatch: 94,
                courseworkMatch: 91,
                experienceMatch: 90,
                preferencesMatch: 93,
                explanation: "Matches your CUDA programming background and systems acceleration focus."
            ),
            imageUrl: "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "cpu.fill",
            accentHex: "#76B900"
        ),
        OpportunityCard(
            id: "opp-17",
            title: "Real-Time Collaboration Engine Intern",
            organization: "Figma",
            opportunityType: "Internship",
            description: "Build multiplayer CRDT synchronizers, WebAssembly graphics pipelines, and canvas rendering optimizations.",
            fullDescription: "Figma is the industry standard collaborative design platform. As an intern on the Canvas and Multiplayer team, you will write high-performance C++ compiled to WebAssembly, ensuring 60fps rendering with dozens of simultaneous active cursors.",
            skills: ["TypeScript", "C++", "WebAssembly", "Graphics"],
            preferredSkills: ["WebGL / WebGPU", "CRDTs", "Distributed Systems"],
            qualifications: [
                "Enrolled in Computer Science or related degree",
                "Strong passion for building delightful, highly responsive user experiences",
                "Solid understanding of algorithms, state synchronization, and vector math"
            ],
            responsibilities: [
                "Optimize spatial scene-graph indexing for ultra-large design files",
                "Improve conflict-free replicated data types (CRDTs) for offline sync",
                "Ship customer-facing canvas rendering improvements directly to production"
            ],
            coursework: ["Computer Graphics", "Algorithms", "Web Systems"],
            location: "San Francisco, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Jun 15, 2027",
            applyUrl: "https://www.figma.com/careers/",
            explanation: "Superb fit for your UI systems, graphics, and concurrency background",
            compensation: "$10,400/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 86,
            matchAnalysis: MatchAnalysis(
                overallMatch: 86,
                skillsMatch: 88,
                courseworkMatch: 85,
                experienceMatch: 84,
                preferencesMatch: 87,
                explanation: "Great match for your interest in interactive systems and low-level rendering."
            ),
            imageUrl: "https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "paintpalette.fill",
            accentHex: "#A259FF"
        ),
        OpportunityCard(
            id: "opp-18",
            title: "Quantum Hardware Simulation Fellow",
            organization: "Harvard Quantum Initiative",
            opportunityType: "REU",
            description: "Simulate neutral-atom quantum processors and Rydberg array entanglement fidelity using high-performance cluster computing.",
            fullDescription: "At the Harvard Quantum Initiative (HQI), join pioneering research groups in neutral atom quantum computing. You will simulate quantum many-body dynamics, laser pulse shaping, and quantum error correction codes.",
            skills: ["Python", "Julia", "Quantum Mechanics", "Linear Algebra"],
            preferredSkills: ["Qiskit / Cirq", "High Performance Computing", "GPU Acceleration"],
            qualifications: [
                "Undergraduate student in Physics, Mathematics, or Computer Science",
                "Strong linear algebra and quantum mechanics mathematical preparation",
                "Familiarity with scientific computing in Python or Julia"
            ],
            responsibilities: [
                "Model laser-induced Rydberg blockade interactions across 2D optical tweezers",
                "Optimize gate fidelity via numerical optimal control algorithms (GRAPE)",
                "Present research at the New England Quantum Symposium"
            ],
            coursework: ["Quantum Physics", "Linear Algebra", "Numerical Methods"],
            location: "Cambridge, MA",
            workMode: "In-Person",
            paid: true,
            deadline: "Jun 20, 2027",
            applyUrl: "https://quantum.harvard.edu",
            explanation: "Unique opportunity aligning with your physics and advanced computation coursework",
            compensation: "$800/week",
            duration: "10 weeks",
            startDate: "June 2027",
            matchPercentage: 84,
            matchAnalysis: MatchAnalysis(
                overallMatch: 84,
                skillsMatch: 86,
                courseworkMatch: 84,
                experienceMatch: 80,
                preferencesMatch: 86,
                explanation: "Good alignment with your advanced mathematics and physics interests."
            ),
            imageUrl: "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "atom",
            accentHex: "#6366F1"
        ),
        OpportunityCard(
            id: "opp-19",
            title: "Forward Deployed Engineer Intern",
            organization: "Palantir",
            opportunityType: "Internship",
            description: "Deploy mission-critical data integration pipelines and AI-assisted operational workflows for defense and health clients.",
            fullDescription: "As an FDE Intern at Palantir, you sit at the intersection of high-leverage software engineering and mission impact. You will architect ontology-driven data backends and real-time operational applications using Palantir Foundry and AIP.",
            skills: ["TypeScript", "Java", "Python", "Data Architecture"],
            preferredSkills: ["React", "PostgreSQL", "System Design"],
            qualifications: [
                "Degree in Computer Science, Software Engineering, or related technical field",
                "Exceptional communication skills and ability to solve ambiguous operational problems",
                "Strong technical acumen across full-stack and backend systems"
            ],
            responsibilities: [
                "Build end-to-end data transformation pipelines handling real-world noisy data",
                "Prototype and deploy customized LLM operational workflows on Foundry AIP",
                "Work on-site with customer technical leadership to accelerate mission objectives"
            ],
            coursework: ["Software Engineering", "Database Systems", "Web Architecture"],
            location: "Washington, DC",
            workMode: "Hybrid",
            paid: true,
            deadline: "Jun 25, 2027",
            applyUrl: "https://www.palantir.com/careers/",
            explanation: "Strong fit for your full-stack product building and system design skills",
            compensation: "$10,000/mo",
            duration: "12 weeks",
            startDate: "May 2027",
            matchPercentage: 87,
            matchAnalysis: MatchAnalysis(
                overallMatch: 87,
                skillsMatch: 89,
                courseworkMatch: 86,
                experienceMatch: 85,
                preferencesMatch: 88,
                explanation: "Solid match for your full-stack and product engineering experience."
            ),
            imageUrl: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "shield.checkerboard",
            accentHex: "#0EA5E9"
        ),
        OpportunityCard(
            id: "opp-20",
            title: "High Performance Systems Intern",
            organization: "Jane Street",
            opportunityType: "Internship",
            description: "Design type-safe trading automation platforms, compiler tools, and high-frequency network protocols in OCaml.",
            fullDescription: "Jane Street is a quantitative trading firm where functional programming powers every aspect of the technology stack. You will use OCaml to design concurrent, high-availability market connectors, statistical arbitrage runners, and internal developer tools.",
            skills: ["OCaml / Functional", "C", "Algorithms", "Concurrency"],
            preferredSkills: ["Type Systems", "Linux Internals", "Networking"],
            qualifications: [
                "Enrolled in an undergraduate or graduate degree in Computer Science or Math",
                "Interest in expressive type systems, functional programming, and algorithmic efficiency",
                "Deep curiosity about complex distributed market mechanisms"
            ],
            responsibilities: [
                "Write robust, test-driven OCaml systems deployed into real-time trading loops",
                "Build interactive terminal and graphical monitoring tools for trading desks",
                "Participate in daily mathematical puzzles and technology seminars"
            ],
            coursework: ["Programming Languages", "Algorithms", "Discrete Mathematics"],
            location: "New York, NY",
            workMode: "In-Person",
            paid: true,
            deadline: "Jun 30, 2027",
            applyUrl: "https://www.janestreet.com/join-jane-street/",
            explanation: "Top tier match for your algorithm analysis and systems curiosity",
            compensation: "$14,500/mo",
            duration: "12 weeks",
            startDate: "June 2027",
            matchPercentage: 89,
            matchAnalysis: MatchAnalysis(
                overallMatch: 89,
                skillsMatch: 90,
                courseworkMatch: 88,
                experienceMatch: 88,
                preferencesMatch: 90,
                explanation: "Great match for your strong algorithmic foundations and interest in type-safe systems."
            ),
            imageUrl: "https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "chart.bar.xaxis",
            accentHex: "#14B8A6"
        ),
        OpportunityCard(
            id: "opp-21",
            title: "Multimodal Foundation Models Fellow",
            organization: "Berkeley AI Research (BAIR)",
            opportunityType: "REU",
            description: "Explore vision-language pretraining, continuous diffusion transformers, and embodied agent reasoning.",
            fullDescription: "At the Berkeley Artificial Intelligence Research Lab (BAIR), collaborate with world-renowned AI faculty and PhD candidates. You will research multimodal tokenizers, sparse mixture-of-experts (MoE) architectures, and synthetic data generation pipelines.",
            skills: ["Python", "PyTorch", "Transformers", "Computer Vision"],
            preferredSkills: ["DeepSpeed", "HuggingFace", "Diffusion Models"],
            qualifications: [
                "Undergraduate student majoring in Computer Science, EECS, or Statistics",
                "Demonstrated proficiency writing modular deep learning code in PyTorch",
                "Experience training vision-language or generative diffusion models"
            ],
            responsibilities: [
                "Train multimodal transformer checkpoints on high-performance GPU clusters",
                "Benchmark zero-shot spatial reasoning and visual question answering",
                "Co-author a submission to CVPR, ICCV, or NeurIPS"
            ],
            coursework: ["Computer Vision", "Deep Learning", "Linear Algebra"],
            location: "Berkeley, CA",
            workMode: "Hybrid",
            paid: true,
            deadline: "Jul 05, 2027",
            applyUrl: "https://bair.berkeley.edu",
            explanation: "Superb alignment with your computer vision and foundation model aspirations",
            compensation: "$850/week",
            duration: "10 weeks",
            startDate: "June 2027",
            matchPercentage: 94,
            matchAnalysis: MatchAnalysis(
                overallMatch: 94,
                skillsMatch: 96,
                courseworkMatch: 93,
                experienceMatch: 92,
                preferencesMatch: 95,
                explanation: "Outstanding alignment with your multimodal research ambitions and ML foundations."
            ),
            imageUrl: "https://images.unsplash.com/photo-1534972195531-a756b1126f24?w=800&auto=format&fit=crop&q=80",
            companyLogoName: "eye.trianglebadge.exclamationmark",
            accentHex: "#3B82F6"
        )
    ]
}

extension MatchedOpportunity {
    public static let mockMatches: [MatchedOpportunity] = [
        MatchedOpportunity(
            id: "match-1",
            opportunity: OpportunityCard.mockDeck[4],
            applicationStatus: .notApplied
        ),
        MatchedOpportunity(
            id: "match-2",
            opportunity: OpportunityCard.mockDeck[0],
            applicationStatus: .notApplied
        ),
        MatchedOpportunity(
            id: "match-3",
            opportunity: OpportunityCard.mockDeck[6],
            applicationStatus: .applied,
            appliedAt: Date()
        ),
        MatchedOpportunity(
            id: "match-4",
            opportunity: OpportunityCard.mockDeck[5],
            applicationStatus: .applied,
            appliedAt: Date().addingTimeInterval(-86400)
        )
    ]
}

extension UserProfile {
    public static let mockProfile = UserProfile(
        name: "Alex Chen",
        headline: "CS Junior · Virginia Tech",
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
        ),
        university: "Virginia Tech",
        major: "Computer Science",
        graduationYear: 2027,
        coursework: ["Data Structures", "Algorithms", "Operating Systems", "Cloud Computing"],
        experience: ["Autonomy Software Intern @ YC Startup", "Undergraduate ML Researcher @ VT AI Lab"],
        profilePictureUrl: nil,
        resumeFileName: "Alex_Chen_Resume_2027.pdf"
    )
}
