import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseSessionRepository: SessionRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore(database: "default")) {
        self.db = db
    }

    func fetchMatchRequest(id: String) async throws -> MatchRequest {
        let user = try requireCurrentUser()
        let snapshot = try await db.collection("match_requests").document(id).getDocument()
        guard let data = snapshot.data(),
              let request = decodeMatchRequest(id: snapshot.documentID, data: data),
              request.userId == user.uid || request.invitedUserId == user.uid || request.matchedUserId == user.uid else {
            throw FirebaseSessionRepositoryError.matchRequestNotFound
        }
        return request
    }

    func fetchIncomingMatchRequests() async throws -> [MatchRequest] {
        let user = try requireCurrentUser()
        let snapshot = try await db.collection("match_requests")
            .whereField("invitedUid", isEqualTo: user.uid)
            .whereField("status", isEqualTo: MatchStatus.finding.rawValue)
            .limit(to: 50)
            .getDocuments()
        return snapshot.documents.compactMap { decodeMatchRequest(id: $0.documentID, data: $0.data()) }
            .filter { ($0.expiresAt ?? .distantPast) > Date() }
    }

    func requestMatch(
        mode: RunMode,
        targetDistance: Double?,
        targetPace: Int?,
        invitedUserId: String?,
        privacyEnabled: Bool
    ) async throws -> MatchRequest {
        let user = try requireCurrentUser()
        guard mode != .solo else { throw FirebaseSessionRepositoryError.invalidMatchMode }
        if mode == .friend, invitedUserId == nil {
            throw FirebaseSessionRepositoryError.missingInvitedUser
        }

        let reference = db.collection("match_requests").document()
        let expiresAt = Date().addingTimeInterval(10 * 60)
        let request = MatchRequest(
            id: reference.documentID,
            userId: user.uid,
            mode: mode,
            targetDistance: targetDistance,
            targetTime: nil,
            targetPace: targetPace,
            privacyEnabled: privacyEnabled,
            status: .finding,
            invitedUserId: invitedUserId,
            expiresAt: expiresAt
        )

        var data: [String: Any] = [
            "requesterUid": user.uid,
            "mode": mode.rawValue,
            "status": MatchStatus.finding.rawValue,
            "privacyEnabled": privacyEnabled,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "expiresAt": Timestamp(date: expiresAt)
        ]
        if let targetDistance { data["targetDistanceMeters"] = targetDistance * 1_000 }
        if let targetPace { data["targetPaceSecPerKm"] = targetPace }
        if let invitedUserId { data["invitedUid"] = invitedUserId }

        try await reference.setData(data)
        return request
    }

    func cancelMatchRequest(id: String) async throws {
        _ = try requireCurrentUser()
        try await db.collection("match_requests").document(id).updateData([
            "status": MatchStatus.cancelled.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func sendReaction(sessionId: String, receiverUserId: String, type: LiveReactionType) async throws {
        let user = try requireCurrentUser()
        let reference = db.collection("live_sessions").document(sessionId)
            .collection("reactions").document()
        try await reference.setData([
            "senderUid": user.uid,
            "receiverUid": receiverUserId,
            "type": type.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    func publishLiveProgress(
        sessionId: String,
        distance: Double,
        elapsedTime: TimeInterval,
        currentPace: Int,
        isPaused: Bool
    ) async throws {
        let user = try requireCurrentUser()
        try await db.collection("live_sessions").document(sessionId)
            .collection("participants").document(user.uid).setData([
                "userUid": user.uid,
                "distanceMeters": max(distance, 0) * 1_000,
                "elapsedTimeSec": max(Int(elapsedTime), 0),
                "currentPaceSecPerKm": max(currentPace, 0),
                "isPaused": isPaused,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    func fetchLiveSnapshot(sessionId: String) async throws -> LiveRunSnapshot {
        let user = try requireCurrentUser()
        let sessionReference = db.collection("live_sessions").document(sessionId)
        async let sessionDocument = sessionReference.getDocument()
        async let participantsSnapshot = sessionReference.collection("participants").getDocuments()
        let (session, participants) = try await (sessionDocument, participantsSnapshot)

        guard let sessionData = session.data(),
              let participantUids = sessionData["participantUids"] as? [String],
              participantUids.contains(user.uid) else {
            throw FirebaseSessionRepositoryError.liveSessionNotFound
        }

        let partnerData = participants.documents.first { $0.documentID != user.uid }?.data()
        let partnerDistanceMeters = (partnerData?["distanceMeters"] as? NSNumber)?.doubleValue ?? 0
        let myDistanceMeters = participants.documents
            .first { $0.documentID == user.uid }
            .flatMap { ($0.data()["distanceMeters"] as? NSNumber)?.doubleValue } ?? 0
        let targetDistanceMeters = (sessionData["targetDistanceMeters"] as? NSNumber)?.doubleValue ?? 0
        let syncScore: Int?
        if targetDistanceMeters > 0, partnerData != nil {
            let progressGap = abs(myDistanceMeters - partnerDistanceMeters) / targetDistanceMeters
            syncScore = max(0, min(100, Int((1 - min(progressGap, 1)) * 100)))
        } else {
            syncScore = nil
        }

        return LiveRunSnapshot(
            partnerDistance: partnerDistanceMeters / 1_000,
            partnerElapsedTime: (partnerData?["elapsedTimeSec"] as? NSNumber)?.doubleValue ?? 0,
            partnerPace: (partnerData?["currentPaceSecPerKm"] as? NSNumber)?.intValue ?? 0,
            partnerIsPaused: partnerData?["isPaused"] as? Bool ?? false,
            syncScore: syncScore
        )
    }

    func fetchSessionHistory() async throws -> [RunSession] {
        let user = try requireCurrentUser()
        let snapshot = try await db.collection("run_sessions")
            .whereField("ownerUid", isEqualTo: user.uid)
            .order(by: "startedAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let modeValue = data["mode"] as? String,
                  let mode = RunMode(rawValue: modeValue),
                  let startedAt = data["startedAt"] as? Timestamp,
                  let endedAt = data["endedAt"] as? Timestamp,
                  let distanceMeters = data["distanceMeters"] as? NSNumber,
                  let averagePace = data["averagePaceSecPerKm"] as? NSNumber else {
                RunLinkerLogger.error("Skipped malformed run session. id=\(document.documentID)")
                return nil
            }

            let participantSnapshots = (data["participants"] as? [[String: Any]])?.compactMap { participant -> User? in
                guard let id = participant["userId"] as? String,
                      let name = participant["name"] as? String else { return nil }
                return User(
                    id: id,
                    name: name,
                    avatarUrl: participant["avatarUrl"] as? String,
                    level: (participant["level"] as? NSNumber)?.intValue ?? 1
                )
            } ?? []
            let participants = participantSnapshots.isEmpty ? [
                User(
                    id: user.uid,
                    name: user.displayName?.isEmpty == false ? user.displayName! : String(localized: "session.you"),
                    avatarUrl: user.photoURL?.absoluteString,
                    level: 1
                )
            ] : participantSnapshots

            return RunSession(
                id: document.documentID,
                participants: participants,
                mode: mode,
                startTime: startedAt.dateValue(),
                endTime: endedAt.dateValue(),
                distance: distanceMeters.doubleValue / 1_000,
                averagePace: averagePace.intValue,
                syncScore: (data["syncScore"] as? NSNumber)?.intValue
            )
        }
    }

    func fetchStatistics() async throws -> RunStatistics {
        let sessions = try await fetchSessionHistory()
        let totalDistance = sessions.reduce(0) { $0 + $1.distance }
        let averagePace: Int
        if sessions.isEmpty {
            averagePace = 0
        } else {
            averagePace = sessions.reduce(0) { $0 + $1.averagePace } / sessions.count
        }
        return RunStatistics(
            totalDistance: totalDistance,
            averagePace: averagePace,
            sessionsCount: sessions.count
        )
    }

    func saveSession(_ session: RunSession, routePoints: [RunRoutePoint]) async throws {
        let user = try requireCurrentUser()
        guard let endTime = session.endTime else {
            throw FirebaseSessionRepositoryError.incompleteSession
        }

        let sessionRef = db.collection("run_sessions").document(session.id)
        var participantUids = session.participants.map { participant in
            participant.id == "current-user" ? user.uid : participant.id
        }
        if !participantUids.contains(user.uid) {
            participantUids.append(user.uid)
        }

        var data: [String: Any] = [
            "ownerUid": user.uid,
            "participantUids": Array(Set(participantUids)),
            "participants": session.participants.map { participant in
                [
                    "userId": participant.id == "current-user" ? user.uid : participant.id,
                    "name": participant.id == "current-user"
                        ? (user.displayName?.isEmpty == false ? user.displayName! : String(localized: "session.you"))
                        : participant.name,
                    "avatarUrl": participant.avatarUrl ?? "",
                    "level": participant.level
                ] as [String: Any]
            },
            "mode": session.mode.rawValue,
            "status": "completed",
            "startedAt": Timestamp(date: session.startTime),
            "endedAt": Timestamp(date: endTime),
            "distanceMeters": session.distance * 1_000,
            "averagePaceSecPerKm": session.averagePace,
            "schemaVersion": 1,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let syncScore = session.syncScore {
            data["syncScore"] = syncScore
        }

        try await sessionRef.setData(data)
        try await saveRoutePoints(routePoints, sessionRef: sessionRef)
        RunLinkerLogger.info("Run session saved. id=\(session.id) routePointCount=\(routePoints.count)")
    }

    private func saveRoutePoints(_ points: [RunRoutePoint], sessionRef: DocumentReference) async throws {
        let chunkSize = 400
        for chunkStart in stride(from: 0, to: points.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, points.count)
            let batch = db.batch()

            for index in chunkStart..<chunkEnd {
                let point = points[index]
                let pointId = String(format: "%08d", index)
                let pointRef = sessionRef.collection("route_points").document(pointId)
                batch.setData([
                    "latitude": point.latitude,
                    "longitude": point.longitude,
                    "capturedAt": Timestamp(date: point.timestamp),
                    "sequence": index
                ], forDocument: pointRef)
            }

            try await batch.commit()
        }
    }

    private func requireCurrentUser() throws -> FirebaseAuth.User {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseSessionRepositoryError.unauthenticated
        }
        return user
    }

    private func decodeMatchRequest(id: String, data: [String: Any]) -> MatchRequest? {
        guard let requesterUid = data["requesterUid"] as? String,
              let modeValue = data["mode"] as? String,
              let mode = RunMode(rawValue: modeValue),
              let statusValue = data["status"] as? String,
              let status = MatchStatus(rawValue: statusValue) else { return nil }

        return MatchRequest(
            id: id,
            userId: requesterUid,
            mode: mode,
            targetDistance: (data["targetDistanceMeters"] as? NSNumber).map { $0.doubleValue / 1_000 },
            targetTime: (data["targetTimeSec"] as? NSNumber)?.intValue,
            targetPace: (data["targetPaceSecPerKm"] as? NSNumber)?.intValue,
            privacyEnabled: data["privacyEnabled"] as? Bool ?? true,
            status: status,
            invitedUserId: data["invitedUid"] as? String,
            matchedUserId: data["matchedUid"] as? String,
            sessionId: data["sessionId"] as? String,
            expiresAt: (data["expiresAt"] as? Timestamp)?.dateValue()
        )
    }
}

enum FirebaseSessionRepositoryError: LocalizedError {
    case unauthenticated
    case incompleteSession
    case invalidMatchMode
    case missingInvitedUser
    case matchRequestNotFound
    case liveSessionNotFound

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            String(localized: "auth.error.user_not_found")
        case .incompleteSession:
            "Completed run session is missing an end time."
        case .invalidMatchMode:
            "Solo runs do not require a match request."
        case .missingInvitedUser:
            "Select a friend before requesting a friend run."
        case .matchRequestNotFound:
            "The match request is no longer available."
        case .liveSessionNotFound:
            "The live run session is no longer available."
        }
    }
}
