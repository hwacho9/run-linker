import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol
    
    @Published var recentSessions: [RunSession] = []
    @Published var totalDistance: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    init(repository: SessionRepositoryProtocol? = nil) {
        self.repository = repository ?? MockSessionService()
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchSessions = repository.getSessionHistory()
            async let fetchStats = repository.getMyStats()
            
            let (sessions, stats) = try await (fetchSessions, fetchStats)
            self.recentSessions = sessions
            self.totalDistance = stats.totalDistance
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
