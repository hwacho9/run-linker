import Foundation

// MARK: - Enums
enum RunMode: String, Codable {
    case friend, random, solo
}

enum MatchStatus: String, Codable {
    case pending, finding, matched, ready, running, finished, cancelled
}

enum SessionFlowStep: String, Equatable {
    case setup
    case friendSelection
    case matching
    case readyRoom
    case liveRun
    case results
}

// MARK: - Models
struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var avatarUrl: String?
    var level: Int
    var averagePace: Int? = nil
    var weeklyRunCount: Int = 0
    var weeklyDistance: Double = 0
    var isAvailable: Bool = false
    var isFavorite: Bool = false
    var lastActiveAt: Date? = nil
    var friendshipId: String? = nil
}

struct MatchRequest: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let mode: RunMode
    let targetDistance: Double?
    let targetTime: Int? // In seconds
    let targetPace: Int? // seconds per km
    let privacyEnabled: Bool
    var status: MatchStatus
    var invitedUserId: String? = nil
    var matchedUserId: String? = nil
    var sessionId: String? = nil
    var expiresAt: Date? = nil
}

struct RunSession: Identifiable, Codable {
    let id: String
    let participants: [User]
    let mode: RunMode
    let startTime: Date
    var endTime: Date?
    var distance: Double
    var averagePace: Int
    var syncScore: Int? // 0-100 score of how synced the runners were
    
    // For local display
    var durationFormatted: String {
        let seconds = Int(endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime))
        let minutes = (seconds % 3600) / 60
        let hours = seconds / 3600
        return hours > 0 ? String(format: "%d:%02d", hours, minutes) : "\(minutes) min"
    }
}

struct RunStatistics: Equatable {
    let totalDistance: Double
    let averagePace: Int
    let sessionsCount: Int
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case cancelled
    case blocked
}

struct Friendship: Identifiable, Codable, Equatable {
    let id: String
    let requesterUserId: String
    let addresseeUserId: String
    let memberUserIds: [String]
    var status: FriendshipStatus
    var favoriteUserIds: [String]
    let createdAt: Date
    var updatedAt: Date
}

struct FriendRequestItem: Identifiable, Equatable {
    let friendship: Friendship
    let sender: User

    var id: String { friendship.id }
}

enum LiveReactionType: String, Codable {
    case cheer
    case nice
    case keepGoing = "keep_going"
    case together
}

struct LiveRunSnapshot: Equatable {
    let partnerDistance: Double
    let partnerElapsedTime: TimeInterval
    let partnerPace: Int
    let partnerIsPaused: Bool
    let syncScore: Int?

    static let empty = LiveRunSnapshot(
        partnerDistance: 0,
        partnerElapsedTime: 0,
        partnerPace: 0,
        partnerIsPaused: false,
        syncScore: nil
    )
}

struct UserSettings: Codable, Equatable {
    var locationSharing: Bool = true
    var randomMatchPublic: Bool = true
    var recordsPublic: Bool = true
    var blurStartEnd: Bool = true
    var cheerNotifications: Bool = true
    var runStartNotifications: Bool = true
    var voiceEnabled: Bool = true
    var weeklyDistanceGoal: Double = 20

    static let defaults = UserSettings()
}
