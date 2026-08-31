import Foundation
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol

    @Published var recentSessions: [RunSession] = []
    @Published var totalDistance: Double = 0.0
    @Published var weeklyDistance: Double = 0.0
    @Published var averagePace: Int = 0
    @Published var recentPartners: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init(repository: SessionRepositoryProtocol? = nil) {
        self.repository = repository ?? FirebaseSessionRepository()
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchSessions = repository.fetchSessionHistory()
            async let fetchStats = repository.fetchStatistics()

            let (sessions, stats) = try await (fetchSessions, fetchStats)
            self.recentSessions = sessions
            self.totalDistance = stats.totalDistance
            self.averagePace = stats.averagePace
            self.weeklyDistance = sessions
                .filter { Calendar.current.isDate($0.startTime, equalTo: Date(), toGranularity: .weekOfYear) }
                .reduce(0) { $0 + $1.distance }
            let currentUserId = Auth.auth().currentUser?.uid
            var seen = Set<String>()
            self.recentPartners = sessions
                .flatMap(\.participants)
                .filter { $0.id != currentUserId && seen.insert($0.id).inserted }
                .prefix(10)
                .map { $0 }
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    var recentSession: RunSession? { recentSessions.first }

    var averagePaceText: String {
        averagePace > 0 ? ActivityStatsSnapshot.paceText(averagePace) : "--'--\""
    }
}
