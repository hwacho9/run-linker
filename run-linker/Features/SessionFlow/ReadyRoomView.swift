import SwiftUI

struct ReadyRoomView: View {
    @ObservedObject var viewModel: SessionFlowViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        Text("session.ready.title")
                            .font(AppTheme.Fonts.heading)
                            .foregroundColor(.white)

                        HStack(spacing: AppTheme.Spacing.lg) {
                            ReadyRoomRunnerAvatar(name: String(localized: "session.you"), subtitle: String(localized: "session.ready.status"), color: AppTheme.secondaryContainer)
                            Image(systemName: "link")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            ReadyRoomRunnerAvatar(
                                name: viewModel.selectedMode == .solo ? String(localized: "session.solo") : (viewModel.matchedPartner?.name ?? String(localized: "session.partner")),
                                subtitle: viewModel.selectedMode == .solo ? String(localized: "session.personal") : "Lv.\(viewModel.matchedPartner?.level ?? 0)",
                                color: AppTheme.primaryFixedDim
                            )
                        }

                        HStack(spacing: AppTheme.Spacing.sm) {
                            ReadyRoomMetricPill(title: "session.distance", value: viewModel.targetDistanceText, inverse: true)
                            ReadyRoomMetricPill(title: "session.estimated_pace", value: viewModel.targetPaceText, inverse: true)
                        }
                    }
                    .padding(AppTheme.Spacing.xxxl)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.kineticGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                    VStack(spacing: AppTheme.Spacing.md) {
                        ReadyChecklistRow(icon: "location.fill", title: "session.ready.location_sync", detail: viewModel.privacyMode ? "session.ready.location_sync.private_detail" : "session.ready.location_sync.precise_detail", isReady: true)
                        ReadyChecklistRow(icon: "timer", title: "session.ready.pace_standard", detail: "session.ready.pace_standard.detail \(viewModel.targetPaceText)", isReady: true)
                        ReadyChecklistRow(icon: "waveform.path.ecg", title: "session.ready.live_connection", detail: "session.ready.live_connection.detail", isReady: true)
                    }
                    .padding(AppTheme.Spacing.xl)
                    .background(AppTheme.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                    AppCard {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("session.today_match")
                                    .font(AppTheme.Fonts.subheadline)
                                    .foregroundColor(AppTheme.text)
                                if viewModel.selectedMode == .solo {
                                    Text("session.ready.solo_summary")
                                        .font(AppTheme.Fonts.bodySmall)
                                        .foregroundColor(AppTheme.textSecondary)
                                } else {
                                    Text("session.ready.match_summary \(viewModel.matchedPartner?.name ?? String(localized: "session.partner")) \(viewModel.targetDistanceText)")
                                        .font(AppTheme.Fonts.bodySmall)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                            FitnessChip(viewModel.selectedMode.title)
                        }
                    }

                    PrimaryButton(title: viewModel.countdown == nil ? "session.start_run" : LocalizedStringKey("\(viewModel.countdown ?? 0)"), icon: viewModel.countdown == nil ? "bolt.fill" : nil) {
                        viewModel.readyToRun()
                    }
                    .disabled(viewModel.countdown != nil)

                    Button {
                        viewModel.cancelSession()
                    } label: {
                        Text("session.leave")
                            .font(AppTheme.Fonts.bodyMedium)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.bottom, AppTheme.Spacing.xxl)
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.xxxxl)

                if let countdown = viewModel.countdown {
                    ZStack {
                        AppTheme.kineticGradient
                            .ignoresSafeArea()
                            .opacity(0.92)

                        Text("\(countdown)")
                            .font(.system(size: 160, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                            .transition(.asymmetric(insertion: .scale(scale: 1.5).combined(with: .opacity), removal: .scale(scale: 0.5).combined(with: .opacity)))
                            .id(countdown)
                    }
                }
            }
        }
    }
}

private struct ReadyRoomRunnerAvatar: View {
    let name: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 84, height: 84)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.onPrimaryFixed)
                )
                .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 2))

            VStack(spacing: 2) {
                Text(name)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ReadyChecklistRow: View {
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let isReady: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primary)
                .frame(width: 36, height: 36)
                .background(AppTheme.primary.opacity(0.08))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.text)
                Text(detail)
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
            Image(systemName: isReady ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isReady ? AppTheme.secondaryFixedDim : AppTheme.outline)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
    }
}

private struct ReadyRoomMetricPill: View {
    let title: LocalizedStringKey
    let value: String
    var inverse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(inverse ? .white.opacity(0.66) : AppTheme.textTertiary)
                .textCase(.uppercase)
            Text(value)
                .font(AppTheme.Fonts.label)
                .foregroundColor(inverse ? .white : AppTheme.text)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(inverse ? .white.opacity(0.13) : AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}
