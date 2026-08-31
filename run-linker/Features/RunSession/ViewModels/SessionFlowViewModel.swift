import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class SessionFlowViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol
    private let socialRepository: SocialRepositoryProtocol
    let soloTracker: SoloRunTracker
    private var cancellables: Set<AnyCancellable> = []
    private var matchingTask: Task<Void, Never>?
    private var liveSyncTask: Task<Void, Never>?
    private var activeMatchRequestId: String?
    private var liveSessionId: String?
    private let initialFriend: User?
    private let initialMatchRequest: MatchRequest?
    private var didActivateInitialContext = false
    private var pendingCompletedSession: RunSession?
    private var pendingRoutePoints: [RunRoutePoint] = []

    @Published var currentStep: SessionFlowStep = .setup

    @Published var selectedMode: RunMode
    @Published var targetDistance: Double = 5.0
    @Published var targetPace: Double = 5.5
    @Published var runningDuration: Double = 30
    @Published var cheerEnabled = true
    @Published var voiceGuideEnabled = true
    @Published var soloPrivateRecord = true
    @Published var preciseLocationSharing = true
    @Published var privacyMode = true

    var onDismiss: (() -> Void)?

    @Published var isSearching = false
    @Published var matchedPartner: User?
    @Published var selectedFriendId: String?
    @Published private(set) var availableFriends: [User] = []
    @Published private(set) var isLoadingFriends = false
    @Published var flowErrorMessage: String?

    @Published var countdown: Int?

    @Published var syncScore = 0
    @Published var partnerDistance = 0.0
    @Published var currentDistance = 0.0
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentPace = 0
    @Published var routePoints: [RunRoutePoint] = []
    @Published var isLiveRunPaused = false
    @Published private(set) var isSavingResult = false
    @Published var saveErrorMessage: String?

    convenience init(
        initialMode: RunMode = .friend,
        initialFriend: User? = nil,
        initialMatchRequest: MatchRequest? = nil
    ) {
        self.init(
            initialMode: initialMatchRequest?.mode ?? initialMode,
            repository: FirebaseSessionRepository(),
            socialRepository: FirebaseSocialRepository(),
            soloTracker: SoloRunTracker(),
            initialFriend: initialFriend,
            initialMatchRequest: initialMatchRequest
        )
    }

    init(
        initialMode: RunMode,
        repository: SessionRepositoryProtocol,
        socialRepository: SocialRepositoryProtocol,
        soloTracker: SoloRunTracker,
        initialFriend: User? = nil,
        initialMatchRequest: MatchRequest? = nil
    ) {
        self.selectedMode = initialMode
        self.repository = repository
        self.socialRepository = socialRepository
        self.soloTracker = soloTracker
        self.initialFriend = initialFriend
        self.initialMatchRequest = initialMatchRequest
        if let initialFriend {
            self.availableFriends = [initialFriend]
            self.selectedFriendId = initialFriend.id
            self.matchedPartner = initialFriend
        }

        soloTracker.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var targetDistanceText: String {
        String(format: "%.1f km", targetDistance)
    }

    var targetPaceText: String {
        "\(Int(targetPace))'\(String(format: "%02d", Int((targetPace - floor(targetPace)) * 60)))\""
    }

    var runningDurationText: String {
        "\(Int(runningDuration)) min"
    }

    var waitingRunnerSummary: String {
        if let partner = matchedPartner {
            return String.localizedStringWithFormat(
                String(localized: "session.waiting_runner_summary_format"),
                partner.name,
                1
            )
        }
        return String(localized: "session.matching.searching_description")
    }

    var selectedFriend: User? {
        guard let selectedFriendId else { return nil }
        return availableFriends.first { $0.id == selectedFriendId }
    }

    var displayedDistance: Double { soloTracker.distanceKilometers }
    var formattedLiveTime: String { soloTracker.formattedTime }
    var formattedLivePace: String { soloTracker.formattedPace }

    func adjustTargetDistance(by value: Double) {
        targetDistance = min(42, max(1, targetDistance + value))
    }

    func adjustTargetPace(by value: Double) {
        targetPace = min(8, max(4, targetPace + value))
    }

    func setTargetDistance(_ value: Double) {
        targetDistance = min(42, max(1, value))
    }

    func setTargetPace(minutes: Int, seconds: Int) {
        let clampedSeconds = min(59, max(0, seconds))
        let pace = Double(minutes) + Double(clampedSeconds) / 60
        targetPace = min(8, max(4, pace))
    }

    func setTargetPace(decimalMinutes: Double) {
        targetPace = min(8, max(4, decimalMinutes))
    }

    func startMatching() {
        flowErrorMessage = nil
        isLiveRunPaused = false

        switch selectedMode {
        case .solo:
            withAnimation(.spring()) { currentStep = .readyRoom }
        case .friend:
            if let initialFriend {
                beginMatch(invitedUserId: initialFriend.id)
                return
            }
            withAnimation(.spring()) { currentStep = .friendSelection }
            Task { await loadAvailableFriends() }
        case .random:
            beginMatch(invitedUserId: nil)
        }
    }

    func activateInitialContextIfNeeded() {
        guard !didActivateInitialContext else { return }
        didActivateInitialContext = true
        guard let request = initialMatchRequest else { return }
        currentStep = .matching
        isSearching = true
        activeMatchRequestId = request.id
        matchingTask = Task { [weak self] in
            do {
                try await self?.waitForMatch(request)
            } catch is CancellationError {
                return
            } catch {
                self?.isSearching = false
                self?.flowErrorMessage = error.localizedDescription
            }
        }
    }

    func loadAvailableFriends() async {
        isLoadingFriends = true
        defer { isLoadingFriends = false }
        do {
            availableFriends = try await socialRepository.fetchFriends()
        } catch {
            availableFriends = []
            flowErrorMessage = error.localizedDescription
            RunLinkerLogger.error("Failed to load friends for a run invitation.", error: error)
        }
    }

    func acceptMatch() {
        guard matchedPartner != nil, liveSessionId != nil else { return }
        withAnimation(.spring()) { currentStep = .readyRoom }
    }

    func selectFriend(_ friend: User) {
        selectedFriendId = friend.id
        matchedPartner = friend
    }

    func continueWithSelectedFriend() {
        guard let selectedFriend else { return }
        matchedPartner = nil
        beginMatch(invitedUserId: selectedFriend.id)
    }

    func findAnotherRunner() {
        guard selectedMode == .random else { return }
        cancelActiveMatchRequest()
        beginMatch(invitedUserId: nil)
    }

    private func beginMatch(invitedUserId: String?) {
        matchingTask?.cancel()
        flowErrorMessage = nil
        matchedPartner = nil
        isSearching = true
        withAnimation(.spring()) { currentStep = .matching }

        matchingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let request = try await repository.requestMatch(
                    mode: selectedMode,
                    targetDistance: targetDistance,
                    targetPace: Int((targetPace * 60).rounded()),
                    invitedUserId: invitedUserId,
                    privacyEnabled: privacyMode
                )
                activeMatchRequestId = request.id
                try await waitForMatch(request)
            } catch is CancellationError {
                return
            } catch {
                isSearching = false
                flowErrorMessage = error.localizedDescription
                RunLinkerLogger.error("Run matching failed.", error: error)
            }
        }
    }

    private func waitForMatch(_ initialRequest: MatchRequest) async throws {
        var request = initialRequest
        while !Task.isCancelled, currentStep == .matching {
            request = try await repository.fetchMatchRequest(id: request.id)
            switch request.status {
            case .matched:
                guard let matchedUserId = request.matchedUserId,
                      let sessionId = request.sessionId else {
                    throw FirebaseSessionRepositoryError.matchRequestNotFound
                }
                matchedPartner = try await socialRepository.fetchUser(id: matchedUserId)
                liveSessionId = sessionId
                activeMatchRequestId = nil
                isSearching = false
                return
            case .cancelled, .finished:
                isSearching = false
                throw CancellationError()
            default:
                if let expiresAt = request.expiresAt, expiresAt <= Date() {
                    isSearching = false
                    flowErrorMessage = String(localized: "session.matching.timeout")
                    return
                }
            }
            try await Task.sleep(nanoseconds: 1_500_000_000)
        }
    }

    func retryMatching() {
        if selectedMode == .friend, let selectedFriend {
            beginMatch(invitedUserId: selectedFriend.id)
        } else {
            beginMatch(invitedUserId: nil)
        }
    }

    func readyToRun() {
        countdown = 3
        Task { [weak self] in
            guard let self else { return }
            for value in (1...3).reversed() {
                guard currentStep == .readyRoom else { return }
                countdown = value
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard currentStep == .readyRoom else { return }
            withAnimation(.spring()) {
                self.countdown = nil
                self.currentStep = .liveRun
            }
        }
    }

    func startLiveRunTrackingIfNeeded() {
        guard !soloTracker.isTracking else { return }
        soloTracker.start()
        isLiveRunPaused = false
        if selectedMode != .solo, liveSessionId != nil { startLiveSync() }
    }

    func pauseOrResumeLiveRun() {
        soloTracker.isPaused ? soloTracker.resume() : soloTracker.pause()
        isLiveRunPaused = soloTracker.isPaused
        publishLiveProgressIfPossible()
    }

    func sendCheer() {
        guard let sessionId = liveSessionId,
              let receiverUserId = matchedPartner?.id else { return }
        Task {
            do {
                try await repository.sendReaction(
                    sessionId: sessionId,
                    receiverUserId: receiverUserId,
                    type: .cheer
                )
            } catch {
                flowErrorMessage = error.localizedDescription
            }
        }
    }

    func stopLiveRun() {
        soloTracker.stop()
        liveSyncTask?.cancel()
        currentDistance = soloTracker.distanceKilometers
        elapsedTime = soloTracker.elapsedTime
        currentPace = soloTracker.currentPace
        routePoints = soloTracker.routePoints
        publishLiveProgressIfPossible()
        saveCompletedRun()
        withAnimation(.spring()) { currentStep = .results }
    }

    func stopLiveRunTrackingIfNeeded() {
        guard currentStep != .results else { return }
        soloTracker.stop()
        liveSyncTask?.cancel()
    }

    private func startLiveSync() {
        liveSyncTask?.cancel()
        liveSyncTask = Task { [weak self] in
            guard let self, let sessionId = liveSessionId else { return }
            while !Task.isCancelled, currentStep == .liveRun {
                do {
                    try await repository.publishLiveProgress(
                        sessionId: sessionId,
                        distance: soloTracker.distanceKilometers,
                        elapsedTime: soloTracker.elapsedTime,
                        currentPace: soloTracker.currentPace,
                        isPaused: soloTracker.isPaused
                    )
                    let snapshot = try await repository.fetchLiveSnapshot(sessionId: sessionId)
                    partnerDistance = snapshot.partnerDistance
                    if let score = snapshot.syncScore { syncScore = score }
                } catch {
                    RunLinkerLogger.error("Live run synchronization failed.", error: error)
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    private func publishLiveProgressIfPossible() {
        guard selectedMode != .solo, let sessionId = liveSessionId else { return }
        let distance = soloTracker.distanceKilometers
        let elapsed = soloTracker.elapsedTime
        let pace = soloTracker.currentPace
        let paused = soloTracker.isPaused
        Task {
            try? await repository.publishLiveProgress(
                sessionId: sessionId,
                distance: distance,
                elapsedTime: elapsed,
                currentPace: pace,
                isPaused: paused
            )
        }
    }

    private func saveCompletedRun() {
        let firebaseUser = Auth.auth().currentUser
        let currentUser = User(
            id: firebaseUser?.uid ?? "current-user",
            name: firebaseUser?.displayName?.isEmpty == false
                ? firebaseUser!.displayName!
                : String(localized: "session.you"),
            avatarUrl: firebaseUser?.photoURL?.absoluteString,
            level: 1
        )
        let endTime = Date()
        let participants = [currentUser] + (matchedPartner.map { [$0] } ?? [])
        let completedSessionId: String
        if let liveSessionId, let userId = firebaseUser?.uid {
            completedSessionId = "\(liveSessionId)_\(userId)"
        } else {
            completedSessionId = UUID().uuidString
        }
        let session = RunSession(
            id: completedSessionId,
            participants: participants,
            mode: selectedMode,
            startTime: endTime.addingTimeInterval(-elapsedTime),
            endTime: endTime,
            distance: currentDistance,
            averagePace: currentPace,
            syncScore: selectedMode == .solo || syncScore == 0 ? nil : syncScore
        )
        let route = routePoints
        pendingCompletedSession = session
        pendingRoutePoints = route
        persistCompletedRun(session, routePoints: route)
    }

    func retrySavingResult() {
        guard let pendingCompletedSession else { return }
        persistCompletedRun(pendingCompletedSession, routePoints: pendingRoutePoints)
    }

    private func persistCompletedRun(_ session: RunSession, routePoints: [RunRoutePoint]) {
        isSavingResult = true
        saveErrorMessage = nil
        Task { [weak self] in
            guard let self else { return }
            defer { isSavingResult = false }
            do {
                try await repository.saveSession(session, routePoints: routePoints)
                pendingCompletedSession = nil
                pendingRoutePoints = []
            } catch {
                saveErrorMessage = error.localizedDescription
                RunLinkerLogger.error("Failed to save the completed run.", error: error)
            }
        }
    }

    func cancelSession() {
        cancelActiveMatchRequest()
        liveSyncTask?.cancel()
        soloTracker.stop()
        withAnimation(.spring()) {
            currentStep = .setup
            isSearching = false
            matchedPartner = nil
            selectedFriendId = nil
            countdown = nil
            isLiveRunPaused = false
            flowErrorMessage = nil
        }
    }

    func closeFlow() {
        cancelSession()
        onDismiss?()
    }

    private func cancelActiveMatchRequest() {
        matchingTask?.cancel()
        guard let requestId = activeMatchRequestId else { return }
        activeMatchRequestId = nil
        Task {
            do {
                try await repository.cancelMatchRequest(id: requestId)
            } catch {
                RunLinkerLogger.error("Failed to cancel a match request.", error: error)
            }
        }
    }

    deinit {
        matchingTask?.cancel()
        liveSyncTask?.cancel()
    }
}
