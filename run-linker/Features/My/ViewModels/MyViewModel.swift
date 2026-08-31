import Combine
import Foundation

@MainActor
final class MyViewModel: ObservableObject {
    private let settingsRepository: UserSettingsRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private var saveTask: Task<Void, Never>?
    private var isApplyingRemoteSettings = false

    @Published var settings = UserSettings.defaults
    @Published private(set) var statistics = RunStatistics(totalDistance: 0, averagePace: 0, sessionsCount: 0)
    @Published private(set) var weeklyDistance = 0.0
    @Published private(set) var averageSync: Int?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    init(
        settingsRepository: UserSettingsRepositoryProtocol? = nil,
        sessionRepository: SessionRepositoryProtocol? = nil
    ) {
        self.settingsRepository = settingsRepository ?? FirebaseUserSettingsRepository()
        self.sessionRepository = sessionRepository ?? FirebaseSessionRepository()
    }

    var weeklyProgress: Double {
        guard settings.weeklyDistanceGoal > 0 else { return 0 }
        return min(weeklyDistance / settings.weeklyDistanceGoal, 1)
    }

    var averagePaceText: String {
        ActivityStatsSnapshot.paceText(statistics.averagePace)
    }

    var averageSyncText: String {
        averageSync.map { "\($0)%" } ?? "--"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let loadedSettings = settingsRepository.fetchSettings()
            async let history = sessionRepository.fetchSessionHistory()
            async let stats = sessionRepository.fetchStatistics()
            let (settings, sessions, statistics) = try await (loadedSettings, history, stats)
            isApplyingRemoteSettings = true
            self.settings = settings
            isApplyingRemoteSettings = false
            self.statistics = statistics
            weeklyDistance = sessions
                .filter { Calendar.current.isDate($0.startTime, equalTo: Date(), toGranularity: .weekOfYear) }
                .reduce(0) { $0 + $1.distance }
            let syncScores = sessions.compactMap(\.syncScore)
            averageSync = syncScores.isEmpty ? nil : syncScores.reduce(0, +) / syncScores.count
        } catch {
            isApplyingRemoteSettings = false
            errorMessage = error.localizedDescription
            RunLinkerLogger.error("Failed to load account dashboard data.", error: error)
        }
    }

    func settingsDidChange() {
        guard !isApplyingRemoteSettings else { return }
        saveTask?.cancel()
        let snapshot = settings
        saveTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled, let self else { return }
                try await settingsRepository.saveSettings(snapshot)
            } catch is CancellationError {
                return
            } catch {
                self?.errorMessage = error.localizedDescription
                RunLinkerLogger.error("Failed to save user settings.", error: error)
            }
        }
    }

    deinit {
        saveTask?.cancel()
    }
}
