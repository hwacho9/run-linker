import SwiftUI

struct MatchSetupView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    @State private var activeInput: SetupInputField?
    @State private var inputText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                modePicker

                SetupValueCard(
                    eyebrow: "TARGET DISTANCE",
                    title: "session.target_distance",
                    icon: "point.topleft.down.to.point.bottomright.curvepath",
                    value: String(format: "%.1f", viewModel.targetDistance),
                    unit: "km",
                    valueAction: {
                        inputText = String(format: "%.1f", viewModel.targetDistance)
                        activeInput = .distance
                    },
                    minusAction: { viewModel.adjustTargetDistance(by: -0.5) },
                    plusAction: { viewModel.adjustTargetDistance(by: 0.5) }
                )

                SetupValueCard(
                    eyebrow: "TARGET PACE",
                    title: "session.target_pace",
                    icon: "gauge.with.dots.needle.bottom.50percent",
                    value: viewModel.targetPaceText,
                    unit: "/km",
                    valueAction: {
                        inputText = viewModel.targetPaceText
                        activeInput = .pace
                    },
                    minusAction: { viewModel.adjustTargetPace(by: -0.25) },
                    plusAction: { viewModel.adjustTargetPace(by: 0.25) }
                )

                durationCard
                featureSettings
                locationSharing
                waitingRunners

                PrimaryButton(title: "session.next_step", icon: "arrow.right") {
                    viewModel.startMatching()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxxxl)
        }
        .alert(activeInput?.title ?? "", isPresented: Binding(
            get: { activeInput != nil },
            set: { if !$0 { activeInput = nil } }
        )) {
            TextField(activeInput?.placeholder ?? "", text: $inputText)
                .keyboardType(.numbersAndPunctuation)
            Button("common.cancel", role: .cancel) {
                activeInput = nil
            }
            Button("common.enter") {
                applyInput()
            }
        } message: {
            Text(activeInput?.message ?? "")
        }
    }

    private func applyInput() {
        guard let activeInput else { return }

        switch activeInput {
        case .distance:
            if let value = Double(inputText.replacingOccurrences(of: ",", with: ".")) {
                viewModel.setTargetDistance(value)
            }
        case .pace:
            if let pace = parsePace(inputText) {
                viewModel.setTargetPace(decimalMinutes: pace)
            }
        }

        self.activeInput = nil
    }

    private func parsePace(_ rawValue: String) -> Double? {
        let value = rawValue
            .replacingOccurrences(of: "/km", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "분", with: ":")
            .replacingOccurrences(of: "초", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if value.contains("'") || value.contains(":") {
            let separator = value.contains("'") ? "'" : ":"
            let parts = value.split(separator: Character(separator), maxSplits: 1).map(String.init)
            guard let minutes = Int(parts.first ?? "") else { return nil }
            let seconds = Int(parts.dropFirst().first ?? "0") ?? 0
            return Double(minutes) + Double(min(59, max(0, seconds))) / 60
        }

        return Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private var modePicker: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            setupModeSegment(mode: .friend, title: "session.mode.friend")
            setupModeSegment(mode: .random, title: "session.mode.random")
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
                    Text("session.running_duration")
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
            Text("session.workout_features")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            VStack(spacing: 0) {
                SetupToggleRow(
                    icon: "megaphone.fill",
                    iconBackground: AppTheme.secondaryContainer,
                    title: "session.feature.cheer",
                    subtitle: "session.feature.cheer.subtitle",
                    isOn: $viewModel.cheerEnabled
                )

                Divider()
                    .padding(.leading, 76)

                SetupToggleRow(
                    icon: "person.wave.2.fill",
                    iconBackground: AppTheme.primaryFixed,
                    title: "session.feature.voice_guide",
                    subtitle: "session.feature.voice_guide.subtitle",
                    isOn: $viewModel.voiceGuideEnabled
                )
            }
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        }
    }

    private var locationSharing: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("session.location_sharing_level")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            HStack(spacing: AppTheme.Spacing.md) {
                LocationLevelButton(
                    icon: "mappin.circle.fill",
                    title: "session.location.precise",
                    isSelected: viewModel.preciseLocationSharing
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.preciseLocationSharing = true
                        viewModel.privacyMode = false
                    }
                }

                LocationLevelButton(
                    icon: "scope",
                    title: "session.location.approximate",
                    isSelected: !viewModel.preciseLocationSharing
                ) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.preciseLocationSharing = false
                        viewModel.privacyMode = true
                    }
                }
            }

            Text(viewModel.preciseLocationSharing ? "session.location.precise.description" : "session.location.approximate.description")
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
                Text("session.waiting_runners")
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
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    let icon: String
    let value: String
    let unit: String
    let valueAction: () -> Void
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
                Button(action: valueAction) {
                    Text(value)
                        .font(AppTheme.Fonts.bigNumber)
                        .foregroundColor(AppTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .buttonStyle(.plain)
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

private enum SetupInputField: Identifiable {
    case distance
    case pace

    var id: String {
        title
    }

    var title: String {
        switch self {
        case .distance:
            return String(localized: "session.input.target_distance.title")
        case .pace:
            return String(localized: "session.input.target_pace.title")
        }
    }

    var placeholder: String {
        switch self {
        case .distance:
            return String(localized: "session.input.distance.placeholder")
        case .pace:
            return String(localized: "session.input.pace.placeholder")
        }
    }

    var message: String {
        switch self {
        case .distance:
            return String(localized: "session.input.distance.message")
        case .pace:
            return String(localized: "session.input.pace.message")
        }
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
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
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
    let title: LocalizedStringKey
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
