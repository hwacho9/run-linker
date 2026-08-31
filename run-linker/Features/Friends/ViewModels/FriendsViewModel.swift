import Combine
import Foundation
import SwiftUI

struct RecentRunPartner: Identifiable {
    let user: User
    let session: RunSession
    var id: String { session.id + user.id }
}

struct RunInvitationItem: Identifiable {
    let request: MatchRequest
    let sender: User
    var id: String { request.id }
}

@MainActor
final class FriendsViewModel: ObservableObject {
    private let socialRepository: SocialRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol

    @Published var query = ""
    @Published var selectedFilter = 0
    @Published private(set) var friends: [User] = []
    @Published private(set) var incomingRequests: [FriendRequestItem] = []
    @Published private(set) var runInvitations: [RunInvitationItem] = []
    @Published private(set) var searchResults: [User] = []
    @Published private(set) var recentPartners: [RecentRunPartner] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSearching = false
    @Published var errorMessage: String?
    @Published private(set) var requestedUserIds: Set<String> = []

    let filters: [LocalizedStringKey] = [
        "friends.filter.all",
        "friends.filter.available",
        "friends.filter.favorite",
        "friends.filter.recent"
    ]

    init(
        socialRepository: SocialRepositoryProtocol? = nil,
        sessionRepository: SessionRepositoryProtocol? = nil
    ) {
        self.socialRepository = socialRepository ?? FirebaseSocialRepository()
        self.sessionRepository = sessionRepository ?? FirebaseSessionRepository()
    }

    var availableFriends: [User] { friends.filter(\.isAvailable) }

    var visibleFriends: [User] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var values: [User]
        switch selectedFilter {
        case 1:
            values = friends.filter(\.isAvailable)
        case 2:
            values = friends.filter(\.isFavorite)
        case 3:
            let recentIds = Set(recentPartners.map(\.user.id))
            values = friends.filter { recentIds.contains($0.id) }
        default:
            values = friends
        }
        guard !normalizedQuery.isEmpty else { return values }
        return values.filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let loadedFriends = socialRepository.fetchFriends()
            async let requests = socialRepository.fetchIncomingFriendRequests()
            async let matchRequests = sessionRepository.fetchIncomingMatchRequests()
            async let sessions = sessionRepository.fetchSessionHistory()
            let (friends, incoming, invitations, history) = try await (loadedFriends, requests, matchRequests, sessions)
            self.friends = friends
            self.incomingRequests = incoming
            self.runInvitations = await makeRunInvitations(from: invitations)
            self.recentPartners = makeRecentPartners(from: history)
        } catch {
            errorMessage = error.localizedDescription
            RunLinkerLogger.error("Failed to load social data.", error: error)
        }
    }

    func searchRunners() async {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            let friendIds = Set(friends.map(\.id))
            searchResults = try await socialRepository.searchRunners(query: normalized)
                .filter { !friendIds.contains($0.id) }
        } catch {
            searchResults = []
            errorMessage = error.localizedDescription
        }
    }

    func sendFriendRequest(to user: User) async {
        do {
            try await socialRepository.sendFriendRequest(to: user.id)
            requestedUserIds.insert(user.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respond(to request: FriendRequestItem, accept: Bool) async {
        do {
            try await socialRepository.respondToFriendRequest(id: request.id, accept: accept)
            incomingRequests.removeAll { $0.id == request.id }
            if accept { await load() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(_ friend: User) async {
        guard let friendshipId = friend.friendshipId else { return }
        do {
            try await socialRepository.setFavorite(
                friendshipId: friendshipId,
                isFavorite: !friend.isFavorite
            )
            if let index = friends.firstIndex(where: { $0.id == friend.id }) {
                friends[index].isFavorite.toggle()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptRunInvitation(_ invitation: RunInvitationItem) async -> MatchRequest? {
        do {
            let reciprocal = try await sessionRepository.requestMatch(
                mode: .friend,
                targetDistance: invitation.request.targetDistance,
                targetPace: invitation.request.targetPace,
                invitedUserId: invitation.request.userId,
                privacyEnabled: invitation.request.privacyEnabled
            )
            runInvitations.removeAll { $0.id == invitation.id }
            return reciprocal
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func makeRecentPartners(from history: [RunSession]) -> [RecentRunPartner] {
        var seen = Set<String>()
        var result: [RecentRunPartner] = []
        for session in history where session.mode != .solo {
            for user in session.participants.dropFirst() where seen.insert(user.id).inserted {
                result.append(RecentRunPartner(user: user, session: session))
            }
        }
        return Array(result.prefix(10))
    }

    private func makeRunInvitations(from requests: [MatchRequest]) async -> [RunInvitationItem] {
        var result: [RunInvitationItem] = []
        for request in requests {
            do {
                let sender = try await socialRepository.fetchUser(id: request.userId)
                result.append(RunInvitationItem(request: request, sender: sender))
            } catch {
                RunLinkerLogger.error("Failed to load a run invitation sender.", error: error)
            }
        }
        return result
    }
}
