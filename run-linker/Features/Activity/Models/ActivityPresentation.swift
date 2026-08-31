import Foundation
import SwiftUI

enum ActivitySubTab: CaseIterable, Identifiable {
    case history
    case stats

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .history:
            return "activity.session_history"
        case .stats:
            return "activity.my_stats"
        }
    }

    var icon: String {
        switch self {
        case .history:
            return "list.bullet.rectangle"
        case .stats:
            return "chart.xyaxis.line"
        }
    }
}

enum ActivityHistoryFilter: CaseIterable, Identifiable {
    case all
    case together
    case solo
    case latest

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .all: "activity.filter.all"
        case .together: "activity.filter.together"
        case .solo: "activity.filter.solo"
        case .latest: "activity.filter.latest"
        }
    }
}

struct ActivityStatsSnapshot {
    let totalDistance: Double
    let averagePace: Int
    let sessionsCount: Int
    let totalDuration: TimeInterval
    let averageSync: Int?
    let bestPace: Int?
    let togetherCount: Int
    let soloCount: Int
    let weeklyDistances: [Double]
    let topPartner: String?

    init(
        stats: RunStatistics?,
        history: [RunSession]
    ) {
        self.totalDistance = stats?.totalDistance ?? history.reduce(0) { $0 + $1.distance }
        self.averagePace = stats?.averagePace ?? Self.averagePace(from: history)
        self.sessionsCount = stats?.sessionsCount ?? history.count
        self.totalDuration = history.reduce(0) { total, session in
            total + (session.endTime?.timeIntervalSince(session.startTime) ?? 0)
        }

        let syncScores = history.compactMap(\.syncScore)
        self.averageSync = syncScores.isEmpty ? nil : syncScores.reduce(0, +) / syncScores.count
        self.bestPace = history.map(\.averagePace).min()
        self.togetherCount = history.filter { $0.mode == .friend || $0.mode == .random }.count
        self.soloCount = history.filter { $0.mode == .solo }.count
        self.weeklyDistances = Self.weeklyDistances(from: history)

        let partners = history.flatMap { Array($0.participants.dropFirst()) }.map(\.name)
        let counts = partners.reduce(into: [:]) { counts, name in counts[name, default: 0] += 1 }
        self.topPartner = counts.max(by: { $0.value < $1.value })?.key
    }

    var totalDistanceText: String {
        String(format: "%.1f", totalDistance)
    }

    var sessionsCountText: String {
        String.localizedStringWithFormat(String(localized: "activity.sessions_count_format"), sessionsCount)
    }

    var averagePaceText: String {
        Self.paceText(averagePace)
    }

    var totalTimeText: String {
        let minutes = Int(totalDuration / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    var averageSyncText: String {
        averageSync.map { "\($0)%" } ?? "--"
    }

    var bestPaceText: String {
        bestPace.map(Self.paceText) ?? "--'--\""
    }

    var togetherShareText: String {
        let total = max(togetherCount + soloCount, 1)
        return "\(Int(round(Double(togetherCount) / Double(total) * 100)))%"
    }

    nonisolated static func paceText(_ seconds: Int) -> String {
        guard seconds > 0 else { return "--'--\"" }
        return "\(seconds / 60)'\(String(format: "%02d", seconds % 60))\""
    }

    private nonisolated static func averagePace(from history: [RunSession]) -> Int {
        guard !history.isEmpty else { return 0 }
        return history.map(\.averagePace).reduce(0, +) / history.count
    }

    private nonisolated static func weeklyDistances(from history: [RunSession]) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -6 + $0, to: today) }

        let values = days.map { day in
            history
                .filter { calendar.isDate($0.startTime, inSameDayAs: day) }
                .reduce(0) { $0 + $1.distance }
        }

        return values
    }
}
