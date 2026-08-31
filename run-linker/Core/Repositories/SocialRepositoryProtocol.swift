import Foundation

protocol SocialRepositoryProtocol {
    func fetchFriends() async throws -> [User]
    func searchRunners(query: String) async throws -> [User]
    func fetchIncomingFriendRequests() async throws -> [FriendRequestItem]
    func sendFriendRequest(to userId: String) async throws
    func respondToFriendRequest(id: String, accept: Bool) async throws
    func setFavorite(friendshipId: String, isFavorite: Bool) async throws
    func fetchUser(id: String) async throws -> User
}

protocol UserSettingsRepositoryProtocol {
    func fetchSettings() async throws -> UserSettings
    func saveSettings(_ settings: UserSettings) async throws
}
