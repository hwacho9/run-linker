import Foundation
import FirebaseFirestore

final class FirebaseUserRepository: UserRepositoryProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func upsertAuthenticatedUser(_ user: AuthenticatedUserProfile) async throws {
        let userRef = db.collection("users").document(user.id)
        let profileRef = db.collection("profiles").document(user.id)
        let existingUser = try await getDocument(userRef)
        let existingProfile = try await getDocument(profileRef)
        let avatarURL = user.photoURL?.absoluteString ?? ""

        var userData: [String: Any] = [
            "id": user.id,
            "authProvider": user.authProvider.rawValue,
            "email": user.email,
            "displayName": user.displayName,
            "photoURL": avatarURL,
            "status": "active",
            "updatedAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]

        if !existingUser.exists {
            userData["createdAt"] = FieldValue.serverTimestamp()
        }

        var profileData: [String: Any] = [
            "userId": user.id,
            "nickname": user.displayName,
            "avatarUrl": avatarURL,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if !existingProfile.exists {
            profileData["createdAt"] = FieldValue.serverTimestamp()
            profileData["bio"] = ""
            profileData["preferredRunMode"] = "friend"
        }

        try await setData(userData, for: userRef, merge: true)
        try await setData(profileData, for: profileRef, merge: true)
    }

    private func getDocument(_ reference: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            reference.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "RunLinkerFirestore",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Firestore 문서를 읽지 못했습니다."]
                    ))
                }
            }
        }
    }

    private func setData(_ data: [String: Any], for reference: DocumentReference, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data, merge: merge) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
