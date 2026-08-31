import Foundation

protocol SessionRepositoryProtocol {
    func fetchMatchRequest(id: String) async throws -> MatchRequest
    func fetchIncomingMatchRequests() async throws -> [MatchRequest]
    func requestMatch(
        mode: RunMode,
        targetDistance: Double?,
        targetPace: Int?,
        invitedUserId: String?,
        privacyEnabled: Bool
    ) async throws -> MatchRequest
    func cancelMatchRequest(id: String) async throws
    
    // Live Run Interactions
    func sendReaction(sessionId: String, receiverUserId: String, type: LiveReactionType) async throws
    func publishLiveProgress(
        sessionId: String,
        distance: Double,
        elapsedTime: TimeInterval,
        currentPace: Int,
        isPaused: Bool
    ) async throws
    func fetchLiveSnapshot(sessionId: String) async throws -> LiveRunSnapshot
    
    // Session Data
    func fetchSessionHistory() async throws -> [RunSession]
    func fetchStatistics() async throws -> RunStatistics
    func saveSession(_ session: RunSession, routePoints: [RunRoutePoint]) async throws
}
