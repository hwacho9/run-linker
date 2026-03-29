import Foundation
// import FirebaseFirestore
// import FirebaseAuth

/// Note: Uncomment Firebase imports and add the Firebase SDK via SPM to use this service.
class FirebaseSessionService: SessionRepositoryProtocol {
    
    // private let db = Firestore.firestore()
    
    func fetchMatchStatus() async throws -> MatchStatus {
        // let snapshot = try await db.collection("matches").document("my-match").getDocument()
        return .pending
    }
    
    func requestMatch(mode: RunMode, targetDistance: Double?) async throws -> MatchRequest {
        let request = MatchRequest(
            id: UUID().uuidString,
            userId: "auth-user-id", // Auth.auth().currentUser?.uid ?? ""
            mode: mode,
            targetDistance: targetDistance,
            targetTime: nil,
            targetPace: nil,
            privacyEnabled: true,
            status: .finding
        )
        // try await db.collection("matches").document(request.id).setData(try! Firestore.Encoder().encode(request))
        return request
    }
    
    func cancelMatchRequest() async throws {
        // try await db.collection("matches").document("my-match").delete()
    }
    
    func sendReaction() async throws {
        // Publish to real-time sync / pubsub node
        print("Firebase: Sent reaction to session.")
    }
    
    func fetchLiveSyncScore() async -> Int {
        // Listen to active session document for SyncScore updates
        return 90
    }
    
    func getSessionHistory() async throws -> [RunSession] {
        // let snapshot = try await db.collection("sessions").whereField("participants", arrayContains: "my-id").getDocuments()
        // return snapshot.documents.compactMap { try? $0.data(as: RunSession.self) }
        return []
    }
    
    func getMyStats() async throws -> (totalDistance: Double, averagePace: Int, sessionsCount: Int) {
        // let snapshot = try await db.collection("users").document("my-id").getDocument()
        return (totalDistance: 0.0, averagePace: 0, sessionsCount: 0)
    }
}
