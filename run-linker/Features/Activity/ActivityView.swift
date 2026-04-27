import Foundation
import SwiftUI
import Combine

@MainActor
class ActivityViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol

    @Published var history: [RunSession] = []
    @Published var stats: (totalDistance: Double, averagePace: Int, sessionsCount: Int)? = nil

    init(repository: SessionRepositoryProtocol? = nil) {
        self.repository = repository ?? MockSessionService()
    }

    func loadActivityData() async {
        do {
            async let fetchHistory = repository.getSessionHistory()
            async let fetchStats = repository.getMyStats()

            let (h, s) = try await (fetchHistory, fetchStats)
            self.history = h
            self.stats = s
        } catch {
            print(error)
        }
    }
}

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @State private var selectedTab: ActivitySubTab = .history

    private var visibleStats: ActivityStatsSnapshot {
        ActivityStatsSnapshot(stats: viewModel.stats, history: viewModel.history)
    }

    var body: some View {
        VStack(spacing: 0) {
            ActivityHeader()

            ActivitySubTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.bottom, AppTheme.Spacing.lg)

            ScrollView(showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .history:
                        buildSessionHistory()
                    case .stats:
                        buildMyStats()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.bottom, AppTheme.Spacing.xxxxl)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.loadActivityData()
        }
    }

    @ViewBuilder
    private func buildSessionHistory() -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("activity.session_history")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                    Text("최근 러닝을 빠르게 확인하고 다시 이어 달릴 수 있어요.")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    FilterChip("전체", isSelected: true, action: {})
                    FilterChip("함께 달리기", isSelected: false, action: {})
                    FilterChip("혼자 달리기", isSelected: false, action: {})
                    FilterChip("최신순", isSelected: false, action: {})
                }
            }
            .padding(.bottom, AppTheme.Spacing.sm)

            if viewModel.history.isEmpty {
                EmptyActivityCard()
            } else {
                ForEach(viewModel.history) { session in
                    SessionHistoryCard(session: session)
                }
            }
        }
    }

    @ViewBuilder
    private func buildMyStats() -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            StatsHeroCard(snapshot: visibleStats)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.lg) {
                StatChip(
                    title: "activity.stat.total_sessions",
                    value: "\(visibleStats.sessionsCount)회",
                    icon: "figure.run",
                    variant: .neutral
                )
                StatChip(
                    title: "activity.stat.avg_pace",
                    value: visibleStats.averagePaceText,
                    icon: "timer",
                    variant: .accent
                )
                StatChip(
                    title: "총 시간",
                    value: visibleStats.totalTimeText,
                    icon: "clock.fill",
                    variant: .neutral
                )
                StatChip(
                    title: "평균 싱크",
                    value: visibleStats.averageSyncText,
                    icon: "link",
                    variant: .neutral
                )
            }

            WeeklyProgressCard(values: visibleStats.weeklyDistances)

            ComparisonCard(snapshot: visibleStats)
        }
    }
}

private enum ActivitySubTab: CaseIterable, Identifiable {
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

private struct ActivityStatsSnapshot {
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
        stats: (totalDistance: Double, averagePace: Int, sessionsCount: Int)?,
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
        
        let partners = history.flatMap { $0.participants }.filter { $0.name.lowercased() != "you" }.map { $0.name }
        let counts = partners.reduce(into: [:]) { counts, name in counts[name, default: 0] += 1 }
        self.topPartner = counts.max(by: { $0.value < $1.value })?.key
    }

    var totalDistanceText: String {
        String(format: "%.1f", totalDistance)
    }

    var averagePaceText: String {
        Self.paceText(averagePace)
    }

    var totalTimeText: String {
        guard totalDuration > 0 else { return "18h 20m" }
        let minutes = Int(totalDuration / 60)
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    var averageSyncText: String {
        averageSync.map { "\($0)%" } ?? "92%"
    }

    var bestPaceText: String {
        bestPace.map(Self.paceText) ?? "5'04\""
    }

    var togetherShareText: String {
        let total = max(togetherCount + soloCount, 1)
        return "\(Int(round(Double(togetherCount) / Double(total) * 100)))%"
    }

    nonisolated static func paceText(_ seconds: Int) -> String {
        "\(seconds / 60)'\(String(format: "%02d", seconds % 60))\""
    }

    private nonisolated static func averagePace(from history: [RunSession]) -> Int {
        guard !history.isEmpty else { return 335 }
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

        return values.contains(where: { $0 > 0 }) ? values : [3.2, 0, 4.8, 5.2, 0, 6.4, 2.6]
    }
}

private struct ActivityHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("tab.activity")
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(AppTheme.text)
                Text("Records")
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.primary)
                    .tracking(1.4)
                    .textCase(.uppercase)
            }
            Spacer()
            IconButton(icon: "calendar", action: {})
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}

private struct ActivitySubTabBar: View {
    @Binding var selectedTab: ActivitySubTab

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(ActivitySubTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14, weight: .bold))
                        Text(tab.title)
                            .font(AppTheme.Fonts.labelSmall)
                    }
                    .foregroundColor(selectedTab == tab ? .white : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(selectedTab == tab ? AppTheme.primary : AppTheme.surfaceContainerLow)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppTheme.outlineVariant.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct StatsHeroCard: View {
    let snapshot: ActivityStatsSnapshot

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("activity.my_stats")
                            .font(AppTheme.Fonts.captionSmall)
                            .foregroundColor(.white.opacity(0.76))
                            .tracking(1.8)
                            .textCase(.uppercase)
                        Text("나의 러닝 성장")
                            .font(AppTheme.Fonts.headingMedium)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.onSecondaryContainer)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.secondaryContainer)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                        Text(snapshot.totalDistanceText)
                            .font(AppTheme.Fonts.bigNumber)
                            .foregroundColor(.white)
                        Text("km")
                            .font(AppTheme.Fonts.metricSmall)
                            .foregroundColor(.white.opacity(0.72))
                    }
                    Text("지금까지 연결한 총 누적 거리")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(.white.opacity(0.78))
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    HeroBadge(title: "Best", value: snapshot.bestPaceText)
                    HeroBadge(title: "Together", value: snapshot.togetherShareText)
                }
            }
            .padding(AppTheme.Spacing.xxl)

            Image(systemName: "figure.run")
                .font(.system(size: 116, weight: .bold))
                .foregroundColor(.white.opacity(0.12))
                .rotationEffect(.degrees(10))
                .offset(x: 18, y: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.kineticGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

private struct HeroBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(.white.opacity(0.66))
                .tracking(0.8)
                .textCase(.uppercase)
            Text(value)
                .font(AppTheme.Fonts.label)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(.white.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}



private struct WeeklyProgressCard: View {
    let values: [Double]
    private let labels = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("activity.weekly_progression")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                    Text("이번 주 거리 흐름")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Text(String(format: "%.1f km", values.reduce(0, +)))
                    .font(AppTheme.Fonts.label)
                    .foregroundColor(AppTheme.primary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.primary.opacity(0.08))
                    .clipShape(Capsule())
            }

            HStack(alignment: .bottom, spacing: AppTheme.Spacing.md) {
                ForEach(values.indices, id: \.self) { index in
                    WeeklyBar(
                        value: values[index],
                        maxValue: max(values.max() ?? 1, 1),
                        label: labels[index % labels.count],
                        isHighlighted: index == values.indices.last
                    )
                }
            }
            .frame(height: 168)
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

private struct WeeklyBar: View {
    let value: Double
    let maxValue: Double
    let label: String
    let isHighlighted: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            GeometryReader { proxy in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: AppTheme.Radius.full)
                        .fill(isHighlighted ? AppTheme.primaryGradient : LinearGradient(colors: [AppTheme.surfaceContainerHighest], startPoint: .top, endPoint: .bottom))
                        .frame(height: max(12, proxy.size.height * CGFloat(value / maxValue)))
                }
            }
            .frame(maxWidth: .infinity)

            Text(label)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(isHighlighted ? AppTheme.primary : AppTheme.textTertiary)
        }
    }
}

private struct ComparisonCard: View {
    let snapshot: ActivityStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            Text("함께 달린 비율")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            HStack(spacing: AppTheme.Spacing.lg) {
                ComparisonMeter(
                    title: "Together",
                    value: snapshot.togetherCount,
                    total: max(snapshot.togetherCount + snapshot.soloCount, 1),
                    color: AppTheme.primary
                )
                ComparisonMeter(
                    title: "Solo",
                    value: snapshot.soloCount,
                    total: max(snapshot.togetherCount + snapshot.soloCount, 1),
                    color: AppTheme.secondaryFixedDim
                )
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primary.opacity(0.08))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("가장 많이 함께 달린 친구")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textTertiary)
                    Text(snapshot.topPartner ?? "없음")
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.text)
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

private struct ComparisonMeter: View {
    let title: String
    let value: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text(title)
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(0.9)
                    .textCase(.uppercase)
                Spacer()
                Text("\(value)")
                    .font(AppTheme.Fonts.label)
                    .foregroundColor(AppTheme.text)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surfaceContainerHighest)
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(value) / CGFloat(max(total, 1)))
                }
            }
            .frame(height: 8)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
    }
}

private struct SessionHistoryCard: View {
    let session: RunSession

    private var partnerNames: String {
        let names = session.participants
            .filter { $0.name.lowercased() != "you" }
            .map(\.name)
        return names.isEmpty ? "Solo Run" : names.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textTertiary)
                    Text(partnerNames)
                        .font(AppTheme.Fonts.titleMedium)
                        .foregroundColor(AppTheme.text)
                }

                Spacer()

                ModeBadge(mode: session.mode)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                HistoryMetric(label: "거리", value: String(format: "%.1f km", session.distance))
                HistoryMetric(label: "시간", value: session.durationFormatted)
                HistoryMetric(label: "페이스", value: ActivityStatsSnapshot.paceText(session.averagePace))
            }

            HStack(spacing: AppTheme.Spacing.md) {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.surfaceContainerHighest)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "map.fill")
                            .foregroundColor(AppTheme.textTertiary.opacity(0.5))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.syncScore.map { "Sync Score \($0)%" } ?? "개인 기록")
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.text)
                    if session.mode != .solo {
                        Text("Pair View snapshot")
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.outlineVariant)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.outlineVariant.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct ModeBadge: View {
    let mode: RunMode

    private var title: LocalizedStringKey {
        switch mode {
        case .friend:
            return "activity.mode.friend"
        case .random:
            return "activity.mode.random"
        case .solo:
            return "Solo Run"
        }
    }

    private var color: Color {
        switch mode {
        case .friend:
            return AppTheme.primary
        case .random:
            return AppTheme.secondaryFixedDim
        case .solo:
            return AppTheme.tertiary
        }
    }

    var body: some View {
        Text(title)
            .font(AppTheme.Fonts.captionSmall)
            .foregroundColor(mode == .random ? AppTheme.onSecondaryFixed : .white)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color)
            .clipShape(Capsule())
    }
}

private struct HistoryMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(AppTheme.textTertiary)
            Text(value)
                .font(AppTheme.Fonts.label)
                .foregroundColor(AppTheme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyActivityCard: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.primary)
            Text("아직 기록이 없어요")
                .font(AppTheme.Fonts.titleMedium)
                .foregroundColor(AppTheme.text)
            Text("첫 러닝을 시작하면 세션 히스토리와 내 통계가 자동으로 채워집니다.")
                .font(AppTheme.Fonts.bodySmall)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}
