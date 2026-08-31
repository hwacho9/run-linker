import Foundation
import SwiftUI

struct GymLinkerActivityCard: View {
    let activity: LinkedFitnessActivity

    private var durationText: String {
        let minutes = max(activity.durationSec / 60, 0)
        return String.localizedStringWithFormat(
            String(localized: "activity.gymlinker.duration_format"),
            minutes
        )
    }

    private var detailsText: String {
        let exercises = activity.summary.exerciseCount ?? 0
        let sets = activity.summary.setCount ?? 0
        return String.localizedStringWithFormat(
            String(localized: "activity.gymlinker.details_format"),
            exercises,
            sets
        )
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 48, height: 48)
                .background(AppTheme.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(activity.title)
                    .font(AppTheme.Fonts.titleMedium)
                    .foregroundColor(AppTheme.text)
                Text("\(activity.startedAt.formatted(date: .abbreviated, time: .omitted)) · \(detailsText)")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()

            Text(durationText)
                .font(AppTheme.Fonts.labelSmall)
                .foregroundColor(AppTheme.onSecondaryContainer)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.secondaryContainer)
                .clipShape(Capsule())
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.outlineVariant.opacity(0.22), lineWidth: 1)
        )
    }
}

struct SessionHistoryCard: View {
    let session: RunSession

    private var partnerNames: String {
        let names = session.participants
            .filter { $0.name.lowercased() != "you" }
            .map(\.name)
        return names.isEmpty ? String(localized: "activity.mode.solo") : names.joined(separator: ", ")
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
                HistoryMetric(label: "session.distance", value: String(format: "%.1f km", session.distance))
                HistoryMetric(label: "session.time", value: session.durationFormatted)
                HistoryMetric(label: "session.pace", value: ActivityStatsSnapshot.paceText(session.averagePace))
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
                    Text(session.syncScore.map { String.localizedStringWithFormat(String(localized: "activity.sync_score_format"), $0) } ?? String(localized: "session.personal_record"))
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.text)
                    if session.mode != .solo {
                        Text("activity.pair_view_snapshot")
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
            return "activity.mode.solo"
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
    let label: LocalizedStringKey
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

struct EmptyActivityCard: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.primary)
            Text("activity.empty.title")
                .font(AppTheme.Fonts.titleMedium)
                .foregroundColor(AppTheme.text)
            Text("activity.empty.subtitle")
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
