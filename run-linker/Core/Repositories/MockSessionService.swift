import Foundation

class MockSessionService: SessionRepositoryProtocol {
    private var isSimulatingMatch: Bool = false
    private var savedSessions: [RunSession] = []
    
    func fetchMatchStatus() async throws -> MatchStatus {
        if isSimulatingMatch {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return .matched
        }
        return .pending
    }
    
    func requestMatch(mode: RunMode, targetDistance: Double?) async throws -> MatchRequest {
        isSimulatingMatch = true
        return MatchRequest(
            id: UUID().uuidString,
            userId: "mock-user-1",
            mode: mode,
            targetDistance: targetDistance,
            targetTime: nil,
            targetPace: nil,
            privacyEnabled: true,
            status: .finding
        )
    }
    
    func cancelMatchRequest() async throws {
        isSimulatingMatch = false
    }
    
    func sendReaction() async throws {
        print("Mock: Sent reaction! 👏")
    }
    
    func fetchLiveSyncScore() async -> Int {
        return Int.random(in: 80...100)
    }
    
    func getSessionHistory() async throws -> [RunSession] {
        return savedSessions + [
            RunSession(
                id: "1",
                participants: [User(id: "1", name: "You", level: 5), User(id: "2", name: "Jane", level: 6)],
                mode: .friend,
                startTime: Date().addingTimeInterval(-86400),
                endTime: Date().addingTimeInterval(-82800),
                distance: 5.2,
                averagePace: 320,
                syncScore: 92
            ),
            RunSession(
                id: "2",
                participants: [User(id: "1", name: "You", level: 5)],
                mode: .solo,
                startTime: Date().addingTimeInterval(-172800),
                endTime: Date().addingTimeInterval(-170000),
                distance: 3.0,
                averagePace: 345,
                syncScore: nil
            )
        ]
    }
    
    func getMyStats() async throws -> (totalDistance: Double, averagePace: Int, sessionsCount: Int) {
        return (totalDistance: 154.2, averagePace: 335, sessionsCount: 42)
    }

    func saveSession(_ session: RunSession, routePoints: [RunRoutePoint]) async throws {
        savedSessions.insert(session, at: 0)
    }
}
