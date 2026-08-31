import FirebaseAuth
import FirebaseFirestore
import Foundation

final class FirebaseSocialRepository: SocialRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore(database: "default")) {
        self.db = db
    }

    func fetchFriends() async throws -> [User] {
        let userId = try requireCurrentUserId()
        let snapshot = try await db.collection("friendships")
            .whereField("memberUids", arrayContains: userId)
            .limit(to: 200)
            .getDocuments()

        let friendships = snapshot.documents.compactMap(decodeFriendship)
            .filter { $0.status == .accepted }
        var result: [User] = []

        for friendship in friendships {
            guard let friendId = friendship.memberUserIds.first(where: { $0 != userId }) else { continue }
            do {
                var friend = try await fetchUser(id: friendId)
                friend.isFavorite = friendship.favoriteUserIds.contains(userId)
                friend.friendshipId = friendship.id
                result.append(friend)
            } catch {
                RunLinkerLogger.error("Failed to load a friend profile. uid=\(friendId)", error: error)
            }
        }

        return result.sorted {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite }
            if $0.isAvailable != $1.isAvailable { return $0.isAvailable }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func searchRunners(query: String) async throws -> [User] {
        let currentUserId = try requireCurrentUserId()
        let normalized = normalize(query)
        guard !normalized.isEmpty else { return [] }

        let snapshot = try await db.collection("public_profiles")
            .whereField("discoverable", isEqualTo: true)
            .limit(to: 100)
            .getDocuments()

        return snapshot.documents
            .filter { $0.documentID != currentUserId }
            .compactMap(decodeUser)
            .filter { normalize($0.name).contains(normalized) }
            .prefix(30)
            .map { $0 }
    }

    func fetchIncomingFriendRequests() async throws -> [FriendRequestItem] {
        let userId = try requireCurrentUserId()
        let snapshot = try await db.collection("friendships")
            .whereField("memberUids", arrayContains: userId)
            .limit(to: 100)
            .getDocuments()

        let friendships = snapshot.documents.compactMap(decodeFriendship)
            .filter { $0.status == .pending && $0.addresseeUserId == userId }
        var result: [FriendRequestItem] = []

        for friendship in friendships {
            do {
                let sender = try await fetchUser(id: friendship.requesterUserId)
                result.append(FriendRequestItem(friendship: friendship, sender: sender))
            } catch {
                RunLinkerLogger.error(
                    "Failed to load a friend request sender. uid=\(friendship.requesterUserId)",
                    error: error
                )
            }
        }
        return result.sorted { $0.friendship.createdAt > $1.friendship.createdAt }
    }

    func sendFriendRequest(to userId: String) async throws {
        let currentUserId = try requireCurrentUserId()
        guard currentUserId != userId else { throw FirebaseSocialRepositoryError.invalidRecipient }

        let pairId = [currentUserId, userId].sorted().joined(separator: "__")
        let reference = db.collection("friendships").document(pairId)
        let existing = try await reference.getDocument()
        if existing.exists {
            throw FirebaseSocialRepositoryError.requestAlreadyExists
        }

        try await reference.setData([
            "requesterUid": currentUserId,
            "addresseeUid": userId,
            "memberUids": [currentUserId, userId],
            "status": FriendshipStatus.pending.rawValue,
            "favoriteUids": [],
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func respondToFriendRequest(id: String, accept: Bool) async throws {
        _ = try requireCurrentUserId()
        try await db.collection("friendships").document(id).updateData([
            "status": accept ? FriendshipStatus.accepted.rawValue : FriendshipStatus.declined.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func setFavorite(friendshipId: String, isFavorite: Bool) async throws {
        let userId = try requireCurrentUserId()
        try await db.collection("friendships").document(friendshipId).updateData([
            "favoriteUids": isFavorite
                ? FieldValue.arrayUnion([userId])
                : FieldValue.arrayRemove([userId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func fetchUser(id: String) async throws -> User {
        let snapshot = try await db.collection("public_profiles").document(id).getDocument()
        guard let user = decodeUser(snapshot) else {
            throw FirebaseSocialRepositoryError.profileNotFound
        }
        return user
    }

    private func decodeUser(_ document: DocumentSnapshot) -> User? {
        guard let data = document.data(),
              (data["discoverable"] as? Bool) != false,
              let name = data["nickname"] as? String,
              !name.isEmpty else { return nil }

        let lastActiveAt = (data["lastActiveAt"] as? Timestamp)?.dateValue()
        let recentlyActive = lastActiveAt.map { Date().timeIntervalSince($0) < 15 * 60 } ?? false
        return User(
            id: document.documentID,
            name: name,
            avatarUrl: nonEmptyString(data["avatarUrl"]),
            level: (data["level"] as? NSNumber)?.intValue ?? 1,
            averagePace: (data["averagePaceSecPerKm"] as? NSNumber)?.intValue,
            weeklyRunCount: (data["weeklyRunCount"] as? NSNumber)?.intValue ?? 0,
            weeklyDistance: ((data["weeklyDistanceMeters"] as? NSNumber)?.doubleValue ?? 0) / 1_000,
            isAvailable: (data["isAvailable"] as? Bool) == true || recentlyActive,
            lastActiveAt: lastActiveAt
        )
    }

    private func decodeFriendship(_ document: QueryDocumentSnapshot) -> Friendship? {
        let data = document.data()
        guard let requester = data["requesterUid"] as? String,
              let addressee = data["addresseeUid"] as? String,
              let members = data["memberUids"] as? [String],
              let statusValue = data["status"] as? String,
              let status = FriendshipStatus(rawValue: statusValue) else { return nil }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
        return Friendship(
            id: document.documentID,
            requesterUserId: requester,
            addresseeUserId: addressee,
            memberUserIds: members,
            status: status,
            favoriteUserIds: data["favoriteUids"] as? [String] ?? [],
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private func nonEmptyString(_ value: Any?) -> String? {
        guard let value = value as? String, !value.isEmpty else { return nil }
        return value
    }

    private func requireCurrentUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseSocialRepositoryError.unauthenticated
        }
        return userId
    }
}

final class FirebaseUserSettingsRepository: UserSettingsRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore(database: "default")) {
        self.db = db
    }

    func fetchSettings() async throws -> UserSettings {
        let userId = try requireCurrentUserId()
        let snapshot = try await db.collection("user_settings").document(userId).getDocument()
        guard let data = snapshot.data() else { return .defaults }

        return UserSettings(
            locationSharing: data["locationSharing"] as? Bool ?? true,
            randomMatchPublic: data["randomMatchPublic"] as? Bool ?? true,
            recordsPublic: data["recordsPublic"] as? Bool ?? true,
            blurStartEnd: data["blurStartEnd"] as? Bool ?? true,
            cheerNotifications: data["cheerNotifications"] as? Bool ?? true,
            runStartNotifications: data["runStartNotifications"] as? Bool ?? true,
            voiceEnabled: data["voiceEnabled"] as? Bool ?? true,
            weeklyDistanceGoal: (data["weeklyDistanceGoalKm"] as? NSNumber)?.doubleValue ?? 20
        )
    }

    func saveSettings(_ settings: UserSettings) async throws {
        let userId = try requireCurrentUserId()
        try await db.collection("user_settings").document(userId).setData([
            "userId": userId,
            "locationSharing": settings.locationSharing,
            "randomMatchPublic": settings.randomMatchPublic,
            "recordsPublic": settings.recordsPublic,
            "blurStartEnd": settings.blurStartEnd,
            "cheerNotifications": settings.cheerNotifications,
            "runStartNotifications": settings.runStartNotifications,
            "voiceEnabled": settings.voiceEnabled,
            "weeklyDistanceGoalKm": max(1, min(settings.weeklyDistanceGoal, 500)),
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    private func requireCurrentUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseSocialRepositoryError.unauthenticated
        }
        return userId
    }
}

enum FirebaseSocialRepositoryError: LocalizedError {
    case unauthenticated
    case invalidRecipient
    case profileNotFound
    case requestAlreadyExists

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return String(localized: "auth.error.user_not_found")
        case .invalidRecipient:
            return "You cannot send a friend request to yourself."
        case .profileNotFound:
            return "The runner profile is unavailable."
        case .requestAlreadyExists:
            return "A friend request or friendship already exists."
        }
    }
}
