import SwiftUI

struct MatchSetupView: View {
    @ObservedObject var viewModel: SessionFlowViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                modePicker

                SetupValueCard(
                    eyebrow: "TARGET DISTANCE",
                    title: "목표 거리",
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    value: String(format: "%.1f", viewModel.targetDistance),
                    unit: "km",
                    minusAction: { viewModel.adjustTargetDistance(by: -0.5) },
                    plusAction: { viewModel.adjustTargetDistance(by: 0.5) }
                )

                SetupValueCard(
                    eyebrow: "TARGET PACE",
                    title: "목표 페이스",
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    value: viewModel.targetPaceText,
                    unit: "/km",
                    minusAction: { viewModel.adjustTargetPace(by: -0.25) },
                    plusAction: { viewModel.adjustTargetPace(by: 0.25) }
                )

                durationCard
                featureSettings
                locationSharing
                waitingRunners

                PrimaryButton(title: "다음 단계로", icon: "arrow.right") {
                    viewModel.startMatching()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxxxl)
        }
    }

    private var modePicker: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            setupModeSegment(mode: .friend, title: "친구와 달리기")
            setupModeSegment(mode: .random, title: "랜덤 매칭")
        }
        .padding(AppTheme.Spacing.xs)
        .background(AppTheme.surfaceContainerHigh)
        .clipShape(Capsule())
    }

    private func setupModeSegment(mode: RunMode, title: LocalizedStringKey) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                viewModel.selectedMode = mode
            }
        } label: {
            Text(title)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(viewModel.selectedMode == mode ? AppTheme.primary : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(viewModel.selectedMode == mode ? AppTheme.surfaceContainerLowest : Color.clear)
                .clipShape(Capsule())
        }
    }

    private var durationCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("RUNNING DURATION")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(1.8)
                    Text("운동 시간")
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                Text(viewModel.runningDurationText)
                    .font(AppTheme.Fonts.metricMedium)
                    .foregroundColor(AppTheme.primary)
            }

            Slider(value: $viewModel.runningDuration, in: 10...60, step: 5)
                .tint(AppTheme.primary)

            HStack {
                Text("10m")
                Spacer()
                Text("60m")
            }
            .font(AppTheme.Fonts.caption)
            .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }

    private var featureSettings: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("운동 기능 설정")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            VStack(spacing: 0) {
                SetupToggleRow(
                    icon: "megaphone.fill",
                    iconBackground: AppTheme.secondaryContainer,
                    title: "응원 보내기",
                    subtitle: "친구와 소리로 응원을 주고받습니다",
                    isOn: $viewModel.cheerEnabled
                )

                Divider()
                    .padding(.leading, 76)

                SetupToggleRow(
                    icon: "person.wave.2.fill",
                    iconBackground: AppTheme.primaryFixed,
                    title: "음성 가이드",
                    subtitle: "KM마다 페이스 및 정보를 안내합니다",
                    isOn: $viewModel.voiceGuideEnabled
                )
            }
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        }
    }

    private var locationSharing: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("위치 공유 수준")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            HStack(spacing: AppTheme.Spacing.md) {
                LocationLevelButton(
                    icon: "mappin.circle.fill",
                    title: "정밀하게",
                    isSelected: viewModel.preciseLocationSharing
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.preciseLocationSharing = true
                        viewModel.privacyMode = false
                    }
                }

                LocationLevelButton(
                    icon: "scope",
                    title: "대략적으로",
                    isSelected: !viewModel.preciseLocationSharing
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.preciseLocationSharing = false
                        viewModel.privacyMode = true
                    }
                }
            }

            Text(viewModel.preciseLocationSharing ? "정밀하게 선택 시 10m 단위로 실시간 위치를 친구에게 공유합니다." : "대략적으로 선택 시 근처 지역 정보만 노출됩니다.")
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private var waitingRunners: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: -8) {
                WaitingRunnerAvatar(name: "민")
                WaitingRunnerAvatar(name: "서")
                Text("+1")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.surfaceContainerLowest, lineWidth: 2))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("현재 대기 중인 러너")
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.textTertiary)
                Text(viewModel.waitingRunnerSummary)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.outlineVariant.opacity(0.2), lineWidth: 1))
    }
}

private struct SetupValueCard: View {
    let eyebrow: String
    let title: String
    let icon: String
    let value: String
    let unit: String
    let minusAction: () -> Void
    let plusAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxxl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(eyebrow)
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.textSecondary)
                        .tracking(1.8)
                    Text(title)
                        .font(AppTheme.Fonts.headingSmall)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppTheme.primary)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(AppTheme.Fonts.bigNumber)
                    .foregroundColor(AppTheme.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(unit)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                RoundStepButton(systemName: "minus", background: AppTheme.surfaceContainerHigh, foreground: AppTheme.text, action: minusAction)
                RoundStepButton(systemName: "plus", background: AppTheme.primary, foreground: .white, action: plusAction)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

private struct RoundStepButton: View {
    let systemName: String
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(foreground)
                .frame(width: 52, height: 52)
                .background(background)
                .clipShape(Circle())
        }
    }
}

private struct SetupToggleRow: View {
    let icon: String
    let iconBackground: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.onSecondaryContainer)
                .frame(width: 52, height: 52)
                .background(iconBackground)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.text)
                Text(subtitle)
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(AppTheme.primary)
                .labelsHidden()
        }
        .padding(AppTheme.Spacing.xl)
    }
}

private struct LocationLevelButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                Text(title)
                    .font(AppTheme.Fonts.subheadline)
            }
            .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(isSelected ? AppTheme.primary : AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        }
    }
}

private struct WaitingRunnerAvatar: View {
    let name: String

    var body: some View {
        Circle()
            .fill(AppTheme.secondaryContainer.opacity(0.45))
            .frame(width: 42, height: 42)
            .overlay(
                Text(name)
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.primary)
            )
            .overlay(Circle().stroke(AppTheme.surfaceContainerLowest, lineWidth: 2))
    }
}
