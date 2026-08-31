import Foundation
import FirebaseAuth

final class FirebaseAuthService: AuthServiceProtocol {
    var currentUser: AuthServiceUser? {
        Auth.auth().currentUser.map(AuthServiceUser.init)
    }

    func signIn(email: String, password: String) async throws -> AuthServiceUser {
        RunLinkerLogger.info("Email sign-in started. email=\(RunLinkerLogger.maskedEmail(email))")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            RunLinkerLogger.info("Email sign-in succeeded. uid=\(result.user.uid) email=\(RunLinkerLogger.maskedEmail(result.user.email ?? email))")
            return AuthServiceUser(user: result.user)
        } catch {
            RunLinkerLogger.error("Email sign-in failed. email=\(RunLinkerLogger.maskedEmail(email))", error: error)
            throw error
        }
    }

    func createUser(email: String, password: String, displayName: String) async throws -> AuthServiceUser {
        RunLinkerLogger.info("Email sign-up started. email=\(RunLinkerLogger.maskedEmail(email)) displayName=\(displayName)")
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            RunLinkerLogger.info("Firebase Auth user created. uid=\(result.user.uid) email=\(RunLinkerLogger.maskedEmail(result.user.email ?? email))")
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            RunLinkerLogger.info("Firebase Auth profile displayName committed. uid=\(result.user.uid)")
            return AuthServiceUser(
                id: result.user.uid,
                email: result.user.email ?? email,
                displayName: displayName,
                photoURL: result.user.photoURL,
                createdAt: result.user.metadata.creationDate
            )
        } catch {
            RunLinkerLogger.error("Email sign-up failed. email=\(RunLinkerLogger.maskedEmail(email))", error: error)
            throw error
        }
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> AuthServiceUser {
        RunLinkerLogger.info("Google Firebase sign-in started.")
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            RunLinkerLogger.info("Google Firebase sign-in succeeded. uid=\(result.user.uid) email=\(RunLinkerLogger.maskedEmail(result.user.email ?? ""))")
            return AuthServiceUser(user: result.user)
        } catch {
            RunLinkerLogger.error("Google Firebase sign-in failed.", error: error)
            throw error
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthServiceUser {
        RunLinkerLogger.info("Apple Firebase sign-in started.")
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            RunLinkerLogger.info("Apple Firebase sign-in succeeded. uid=\(result.user.uid) email=\(RunLinkerLogger.maskedEmail(result.user.email ?? ""))")
            return AuthServiceUser(user: result.user)
        } catch {
            RunLinkerLogger.error("Apple Firebase sign-in failed.", error: error)
            throw error
        }
    }

    func signInWithCustomToken(
        _ customToken: String,
        email: String,
        displayName: String,
        photoURL: URL?
    ) async throws -> AuthServiceUser {
        RunLinkerLogger.info("GymLinker custom-token sign-in started.")
        do {
            let result = try await Auth.auth().signIn(withCustomToken: customToken)
            let changeRequest = result.user.createProfileChangeRequest()
            var shouldCommitProfile = false

            if !displayName.isEmpty, result.user.displayName != displayName {
                changeRequest.displayName = displayName
                shouldCommitProfile = true
            }
            if let photoURL, result.user.photoURL != photoURL {
                changeRequest.photoURL = photoURL
                shouldCommitProfile = true
            }
            if shouldCommitProfile {
                do {
                    try await changeRequest.commitChanges()
                } catch {
                    RunLinkerLogger.error("GymLinker profile metadata update failed after sign-in.", error: error)
                }
            }

            RunLinkerLogger.info("GymLinker custom-token sign-in succeeded. uid=\(result.user.uid)")
            return AuthServiceUser(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                photoURL: photoURL,
                createdAt: result.user.metadata.creationDate
            )
        } catch {
            RunLinkerLogger.error("GymLinker custom-token sign-in failed.", error: error)
            throw error
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

private extension AuthServiceUser {
    nonisolated init(user: FirebaseAuth.User) {
        self.init(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            photoURL: user.photoURL,
            createdAt: user.metadata.creationDate
        )
    }
}
