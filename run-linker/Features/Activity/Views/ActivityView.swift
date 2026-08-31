import SwiftUI

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
            .refreshable { await viewModel.loadActivityData() }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.loadActivityData()
        }
    }

    @ViewBuilder
    private func buildSessionHistory() -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppTheme.Fonts.bodySmall)
                    .foregroundColor(AppTheme.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.lg)
                    .background(AppTheme.errorContainer)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("activity.session_history")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                    Text("activity.session_history.subtitle")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(ActivityHistoryFilter.allCases) { filter in
                        FilterChip(filter.title, isSelected: viewModel.selectedFilter == filter) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.bottom, AppTheme.Spacing.sm)

            if viewModel.filteredHistory.isEmpty {
                if viewModel.gymLinkerActivities.isEmpty {
                    EmptyActivityCard()
                }
            } else {
                ForEach(viewModel.filteredHistory) { session in
                    SessionHistoryCard(session: session)
                }
            }

            if !viewModel.gymLinkerActivities.isEmpty {
                HStack {
                    Text("activity.gymlinker.section")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    Text("GymLinker")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.top, AppTheme.Spacing.md)

                ForEach(viewModel.gymLinkerActivities) { activity in
                    GymLinkerActivityCard(activity: activity)
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
                    value: visibleStats.sessionsCountText,
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
                    title: "activity.stat.total_time",
                    value: visibleStats.totalTimeText,
                    icon: "clock.fill",
                    variant: .neutral
                )
                StatChip(
                    title: "activity.stat.average_sync",
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
