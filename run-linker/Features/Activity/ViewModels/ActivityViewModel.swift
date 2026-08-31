import Combine
import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol
    private let gymLinkerActivityService: GymLinkerActivityServiceProtocol

    @Published private(set) var history: [RunSession] = []
    @Published private(set) var stats: RunStatistics?
    @Published private(set) var gymLinkerActivities: [LinkedFitnessActivity] = []
    @Published var selectedFilter: ActivityHistoryFilter = .all
    @Published private(set) var errorMessage: String?

    init(
        repository: SessionRepositoryProtocol? = nil,
        gymLinkerActivityService: GymLinkerActivityServiceProtocol? = nil
    ) {
        self.repository = repository ?? FirebaseSessionRepository()
        self.gymLinkerActivityService = gymLinkerActivityService ?? GymLinkerActivityService()
    }

    func loadActivityData() async {
        errorMessage = nil
        do {
            async let history = repository.fetchSessionHistory()
            async let statistics = repository.fetchStatistics()

            (self.history, self.stats) = try await (history, statistics)
        } catch {
            errorMessage = error.localizedDescription
            RunLinkerLogger.error("Failed to load activity data.", error: error)
        }

        guard IntegrationFeatureFlags.isGymLinkerIntegrationEnabled else {
            gymLinkerActivities = []
            return
        }

        do {
            let since = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? .distantPast
            gymLinkerActivities = try await gymLinkerActivityService.fetchActivities(since: since, limit: 50)
        } catch {
            // Independent RunLinker accounts are expected to reach this path until they link GymLinker.
            gymLinkerActivities = []
            RunLinkerLogger.info("GymLinker activity summaries are unavailable. reason=\(error.localizedDescription)")
        }
    }

    var filteredHistory: [RunSession] {
        switch selectedFilter {
        case .all:
            history
        case .together:
            history.filter { $0.mode != .solo }
        case .solo:
            history.filter { $0.mode == .solo }
        case .latest:
            Array(history.sorted { $0.startTime > $1.startTime }.prefix(10))
        }
    }
}
