import Foundation
import SwiftUI
import Combine

@MainActor
class SessionFlowViewModel: ObservableObject {
    @Published var currentStep: SessionFlowStep = .setup
    
    // MARK: - Setup State
    @Published var selectedMode: RunMode
    @Published var targetDistance: Double = 5.0
    @Published var targetPace: Double = 5.5
    @Published var runningDuration: Double = 30
    @Published var cheerEnabled = true
    @Published var voiceGuideEnabled = true
    @Published var preciseLocationSharing = true
    @Published var privacyMode = true
    
    var onDismiss: (() -> Void)?
    
    init(initialMode: RunMode = .friend) {
        self.selectedMode = initialMode
    }
    
    // MARK: - Matching State
    @Published var isSearching: Bool = false
    @Published var matchedPartner: User? = nil
    @Published var selectedCandidateIndex = 0

    let candidates: [User] = [
        User(id: "candidate-1", name: "지훈", level: 8),
        User(id: "candidate-2", name: "민수", level: 6),
        User(id: "candidate-3", name: "서연", level: 7)
    ]
    
    // MARK: - Ready Room State
    @Published var countdown: Int? = nil
    
    // MARK: - Live Run State
    @Published var syncScore: Int = 95
    @Published var currentDistance: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentPace: Int = 300 // 5:00/km

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
        "민수님 외 2명"
    }

    var selectedCandidate: User {
        candidates[selectedCandidateIndex % candidates.count]
    }

    func adjustTargetDistance(by value: Double) {
        targetDistance = min(42, max(1, targetDistance + value))
    }

    func adjustTargetPace(by value: Double) {
        targetPace = min(8, max(4, targetPace + value))
    }
    
    // MARK: - Mock Transition Logic
    
    func startMatching() {
        if selectedMode == .solo {
            // Solo skips matching and ready room
            withAnimation(.spring()) {
                currentStep = .liveRun
            }
            startMockRun()
            return
        }
        
        withAnimation(.spring()) {
            currentStep = .matching
            isSearching = true
        }
        
        // Mock finding a match after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard currentStep == .matching else { return }
            
            withAnimation(.spring()) {
                isSearching = false
                selectedCandidateIndex = selectedMode == .random ? 1 : 0
                matchedPartner = candidates[selectedCandidateIndex]
            }
            
        }
    }

    func acceptMatch() {
        guard matchedPartner != nil else { return }
        withAnimation(.spring()) {
            currentStep = .readyRoom
        }
    }

    func findAnotherRunner() {
        matchedPartner = nil
        isSearching = true
        selectedCandidateIndex = (selectedCandidateIndex + 1) % candidates.count

        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard currentStep == .matching else { return }

            withAnimation(.spring()) {
                isSearching = false
                matchedPartner = selectedCandidate
            }
        }
    }
    
    func readyToRun() {
        // Mock countdown
        countdown = 3
        Task {
            for i in (1...3).reversed() {
                guard currentStep == .readyRoom else { return }
                countdown = i
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard currentStep == .readyRoom else { return }
            withAnimation(.spring()) {
                countdown = nil
                currentStep = .liveRun
            }
            startMockRun()
        }
    }
    
    func finishRun() {
        withAnimation(.spring()) {
            currentStep = .results
        }
    }
    
    func cancelSession() {
        withAnimation(.spring()) {
            currentStep = .setup
            isSearching = false
            matchedPartner = nil
            countdown = nil
        }
    }
    
    func closeFlow() {
        cancelSession()
        onDismiss?()
    }
    
    private var runTimer: Timer?
    
    private func startMockRun() {
        currentDistance = 0.0
        elapsedTime = 0
        syncScore = 95
        currentPace = [280, 290, 300, 310, 320].randomElement() ?? 300
        
        runTimer?.invalidate()
        runTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.currentStep == .liveRun else {
                    self?.runTimer?.invalidate()
                    return
                }
                
                self.elapsedTime += 1
                self.currentDistance += (1000.0 / Double(self.currentPace)) / 1000.0 // rough distance based on pace
                
                if Int(self.elapsedTime) % 5 == 0 {
                    self.syncScore = max(0, min(100, self.syncScore + Int.random(in: -3...3)))
                }
            }
        }
    }
    
    deinit {
        runTimer?.invalidate()
    }
}
