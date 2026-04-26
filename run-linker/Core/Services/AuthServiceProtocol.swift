import Foundation

struct AuthServiceUser {
    let id: String
    let email: String
    let displayName: String
    let photoURL: URL?
    let createdAt: Date?
}

protocol AuthServiceProtocol {
    var currentUser: AuthServiceUser? { get }

    func signIn(email: String, password: String) async throws -> AuthServiceUser
    func createUser(email: String, password: String, displayName: String) async throws -> AuthServiceUser
    func signInWithGoogle(idToken: String, accessToken: String) async throws -> AuthServiceUser
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthServiceUser
    func signOut() throws
}
