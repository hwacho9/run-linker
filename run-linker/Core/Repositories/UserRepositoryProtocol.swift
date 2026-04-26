import Foundation

enum AuthenticationProvider: String {
    case email
    case apple
    case google
}

struct AuthenticatedUserProfile {
    let id: String
    let authProvider: AuthenticationProvider
    let email: String
    let displayName: String
    let photoURL: URL?
    let createdAt: Date?
}

protocol UserRepositoryProtocol {
    func upsertAuthenticatedUser(_ user: AuthenticatedUserProfile) async throws
}
