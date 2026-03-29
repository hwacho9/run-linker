import Foundation

protocol SessionRepositoryProtocol {
    func fetchMatchStatus() async throws -> MatchStatus
    func requestMatch(mode: RunMode, targetDistance: Double?) async throws -> MatchRequest
    func cancelMatchRequest() async throws
    
    // Live Run Interactions
    func sendReaction() async throws
    func fetchLiveSyncScore() async -> Int
    
    // Session Data
    func getSessionHistory() async throws -> [RunSession]
    func getMyStats() async throws -> (totalDistance: Double, averagePace: Int, sessionsCount: Int)
}
