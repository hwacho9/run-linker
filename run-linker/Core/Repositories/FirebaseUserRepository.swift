import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

final class FirebaseUserRepository: UserRepositoryProtocol {
    private let db: Firestore
    private let writeTimeoutSeconds: UInt64

    init(db: Firestore = Firestore.firestore(database: "default"), writeTimeoutSeconds: UInt64 = 30) {
        self.db = db
        self.writeTimeoutSeconds = writeTimeoutSeconds
    }

    func upsertAuthenticatedUser(_ user: AuthenticatedUserProfile) async throws {
        let userRef = db.collection("users").document(user.id)
        let profileRef = db.collection("profiles").document(user.id)
        let avatarURL = user.photoURL?.absoluteString ?? ""
        let createdAt: Any = user.createdAt.map { Timestamp(date: $0) } ?? FieldValue.serverTimestamp()
        let projectID = FirebaseApp.app()?.options.projectID ?? "<nil>"

        print("🔥 [Firestore] upsert START — projectID=\(projectID) uid=\(user.id) provider=\(user.authProvider.rawValue)")
        RunLinkerLogger.info("Firestore user upsert started. projectID=\(projectID) uid=\(user.id) email=\(RunLinkerLogger.maskedEmail(user.email)) provider=\(user.authProvider.rawValue)")
        RunLinkerLogger.info("Firestore target documents. users/\(user.id), profiles/\(user.id)")
        
        do {
            try await runPreflightChecks(for: user)
            print("🔥 [Firestore] preflight PASSED — uid=\(user.id)")
        } catch {
            print("❌ [Firestore] preflight FAILED — \(error)")
            throw error
        }

        let userData: [String: Any] = [
            "id": user.id,
            "authProvider": user.authProvider.rawValue,
            "email": user.email,
            "displayName": user.displayName,
            "photoURL": avatarURL,
            "status": "active",
            "createdAt": createdAt,
            "updatedAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]

        let profileData: [String: Any] = [
            "userId": user.id,
            "nickname": user.displayName,
            "avatarUrl": avatarURL,
            "createdAt": createdAt,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let batch = db.batch()
        batch.setData(userData, forDocument: userRef, merge: true)
        batch.setData(profileData, forDocument: profileRef, merge: true)
        
        print("🔥 [Firestore] batch commit START — uid=\(user.id) timeout=\(writeTimeoutSeconds)s")
        RunLinkerLogger.info("Firestore batch commit requested. uid=\(user.id) timeoutSeconds=\(writeTimeoutSeconds)")
        
        do {
            try await commit(batch)
            print("✅ [Firestore] batch commit SUCCESS — uid=\(user.id)")
            RunLinkerLogger.info("Firestore batch commit succeeded. uid=\(user.id)")
        } catch {
            print("❌ [Firestore] batch commit FAILED — \(error)")
            throw error
        }
    }

    private func runPreflightChecks(for user: AuthenticatedUserProfile) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            RunLinkerLogger.error("Firestore preflight failed. Firebase Auth currentUser is nil.")
            throw FirestorePreflightError.authUserMissing
        }

        RunLinkerLogger.info("Firestore preflight Auth currentUser. uid=\(currentUser.uid) expectedUid=\(user.id)")

        guard currentUser.uid == user.id else {
            RunLinkerLogger.error("Firestore preflight failed. Auth uid does not match profile uid.")
            throw FirestorePreflightError.authUserMismatch
        }

        do {
            let tokenResult = try await currentUser.getIDTokenResult(forcingRefresh: true)
            RunLinkerLogger.info("Firestore preflight Auth ID token ready. provider=\(tokenResult.signInProvider) expiresAt=\(tokenResult.expirationDate)")
        } catch {
            RunLinkerLogger.error("Firestore preflight Auth ID token failed.", error: error)
            throw error
        }

        RunLinkerLogger.info("Firestore preflight App Check skipped. Firebase App Check API is disabled for this project.")
    }

    private func commit(_ batch: WriteBatch) async throws {
        let timeoutSeconds = writeTimeoutSeconds

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let lock = NSLock()
            var didResume = false

            @discardableResult
            func resumeOnce(_ result: Result<Void, Error>) -> Bool {
                lock.lock()
                defer { lock.unlock() }

                guard !didResume else { return false }
                didResume = true

                switch result {
                case .success:
                    continuation.resume(returning: ())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }

                return true
            }

            let timeout = DispatchWorkItem {
                if resumeOnce(.failure(FirestoreWriteTimeoutError())) {
                    RunLinkerLogger.error("Firestore batch commit timed out after \(timeoutSeconds)s.")
                }
            }

            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(Int(timeoutSeconds)),
                execute: timeout
            )

            batch.commit { error in
                if let error = error {
                    RunLinkerLogger.error("Firestore batch commit failed.", error: error)
                    resumeOnce(.failure(error))
                } else {
                    resumeOnce(.success(()))
                }
            }
        }
    }
}

struct FirestoreWriteTimeoutError: LocalizedError {
    var errorDescription: String? {
        "Firestore write timed out."
    }
}

enum FirestorePreflightError: LocalizedError {
    case authUserMissing
    case authUserMismatch

    var errorDescription: String? {
        switch self {
        case .authUserMissing:
            return "Firebase Auth current user is missing."
        case .authUserMismatch:
            return "Firebase Auth current user does not match the profile being saved."
        }
    }
}
