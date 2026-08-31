import Foundation
import SwiftUI

struct ActivityHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("tab.activity")
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(AppTheme.text)
                Text("activity.records")
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.primary)
                    .tracking(1.4)
                    .textCase(.uppercase)
            }
            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.lg)
    }
}

struct ActivitySubTabBar: View {
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

struct StatsHeroCard: View {
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
                        Text("activity.my_growth")
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
                    Text("activity.total_distance_caption")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(.white.opacity(0.78))
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    HeroBadge(title: "activity.best", value: snapshot.bestPaceText)
                    HeroBadge(title: "activity.together", value: snapshot.togetherShareText)
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
    let title: LocalizedStringKey
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



struct WeeklyProgressCard: View {
    let values: [Double]
    private let labels: [LocalizedStringKey] = [
        "weekday.mon",
        "weekday.tue",
        "weekday.wed",
        "weekday.thu",
        "weekday.fri",
        "weekday.sat",
        "weekday.sun"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("activity.weekly_progression")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                    Text("activity.weekly_progression.subtitle")
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
    let label: LocalizedStringKey
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

struct ComparisonCard: View {
    let snapshot: ActivityStatsSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            Text("activity.together_share")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            HStack(spacing: AppTheme.Spacing.lg) {
                ComparisonMeter(
                    title: "activity.together",
                    value: snapshot.togetherCount,
                    total: max(snapshot.togetherCount + snapshot.soloCount, 1),
                    color: AppTheme.primary
                )
                ComparisonMeter(
                    title: "activity.solo",
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
                    Text("activity.top_partner")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textTertiary)
                    Text(snapshot.topPartner ?? String(localized: "common.none"))
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
    let title: LocalizedStringKey
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
