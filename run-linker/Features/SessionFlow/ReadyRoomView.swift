import SwiftUI

struct ReadyRoomView: View {
    @ObservedObject var viewModel: SessionFlowViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        Text("러닝 준비 완료")
                            .font(AppTheme.Fonts.heading)
                            .foregroundColor(.white)

                        HStack(spacing: AppTheme.Spacing.lg) {
                            ReadyRoomRunnerAvatar(name: "You", subtitle: "Ready", color: AppTheme.secondaryContainer)
                            Image(systemName: "link")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            ReadyRoomRunnerAvatar(
                                name: viewModel.selectedMode == .solo ? "Solo" : (viewModel.matchedPartner?.name ?? "Partner"),
                                subtitle: viewModel.selectedMode == .solo ? "Personal" : "Lv.\(viewModel.matchedPartner?.level ?? 0)",
                                color: AppTheme.primaryFixedDim
                            )
                        }

                        HStack(spacing: AppTheme.Spacing.sm) {
                            ReadyRoomMetricPill(title: "거리", value: viewModel.targetDistanceText, inverse: true)
                            ReadyRoomMetricPill(title: "예상 페이스", value: viewModel.targetPaceText, inverse: true)
                        }
                    }
                    .padding(AppTheme.Spacing.xxxl)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.kineticGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                    VStack(spacing: AppTheme.Spacing.md) {
                        ReadyChecklistRow(icon: "location.fill", title: "위치 동기화", detail: viewModel.privacyMode ? "시작/종료 지점은 보호됩니다." : "정확한 위치 공유가 켜져 있습니다.", isReady: true)
                        ReadyChecklistRow(icon: "timer", title: "페이스 기준", detail: "\(viewModel.targetPaceText) 근처에서 싱크를 계산합니다.", isReady: true)
                        ReadyChecklistRow(icon: "waveform.path.ecg", title: "라이브 연결", detail: "Pair View와 Sync Score가 준비되었습니다.", isReady: true)
                    }
                    .padding(AppTheme.Spacing.xl)
                    .background(AppTheme.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                    AppCard {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("오늘의 매칭")
                                    .font(AppTheme.Fonts.subheadline)
                                    .foregroundColor(AppTheme.text)
                                Text(viewModel.selectedMode == .solo ? "개인 기록 모드로 시작합니다." : "\(viewModel.matchedPartner?.name ?? "Partner")님과 함께 \(viewModel.targetDistanceText) 러닝")
                                    .font(AppTheme.Fonts.bodySmall)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            FitnessChip(viewModel.selectedMode.title)
                        }
                    }

                    PrimaryButton(title: viewModel.countdown == nil ? "러닝 시작" : "\(viewModel.countdown ?? 0)", icon: viewModel.countdown == nil ? "bolt.fill" : nil) {
                        viewModel.readyToRun()
                    }
                    .disabled(viewModel.countdown != nil)

                    Button {
                        viewModel.cancelSession()
                    } label: {
                        Text("나가기")
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
    let title: String
    let detail: String
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
    let title: String
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
