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
    case matching
    case readyRoom
    case liveRun
    case results
}

// MARK: - Models
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var avatarUrl: String?
    var level: Int
}

struct MatchRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let mode: RunMode
    let targetDistance: Double?
    let targetTime: Int? // In seconds
    let targetPace: Int? // seconds per km
    let privacyEnabled: Bool
    var status: MatchStatus
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
