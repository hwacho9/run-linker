import Foundation
// import FirebaseFirestore
// import FirebaseAuth

/// Note: Add the Firebase SDK to Xcode to uncomment functionality.
class FirebaseSessionService: SessionRepositoryProtocol {
    // private let db = Firestore.firestore()
    
    func fetchMatchStatus() async throws -> MatchStatus {
        return .pending
    }
    
    func requestMatch(mode: RunMode, targetDistance: Double?) async throws -> MatchRequest {
        let request = MatchRequest(
            id: UUID().uuidString,
            userId: "auth-user-id",
            mode: mode,
            targetDistance: targetDistance,
            targetTime: nil,
            targetPace: nil,
            privacyEnabled: true,
            status: .finding
        )
        return request
    }
    
    func cancelMatchRequest() async throws { }
    
    func sendReaction() async throws { }
    
    func fetchLiveSyncScore() async -> Int {
        return 90
    }
    
    func getSessionHistory() async throws -> [RunSession] {
        return []
    }
    
    func getMyStats() async throws -> (totalDistance: Double, averagePace: Int, sessionsCount: Int) {
        return (totalDistance: 0.0, averagePace: 0, sessionsCount: 0)
    }
}
