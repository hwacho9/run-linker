import SwiftUI

struct SoloRunSetupView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    @State private var activeInput: SoloInputField?
    @State private var inputText = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxl) {
                hero

                SoloValueCard(
                    eyebrow: "SOLO DISTANCE",
                    title: "session.solo.target_distance",
                    icon: "figure.run",
                    value: String(format: "%.1f", viewModel.targetDistance),
                    unit: "km",
                    valueAction: {
                        inputText = String(format: "%.1f", viewModel.targetDistance)
                        activeInput = .distance
                    },
                    minusAction: { viewModel.adjustTargetDistance(by: -0.5) },
                    plusAction: { viewModel.adjustTargetDistance(by: 0.5) }
                )

                SoloValueCard(
                    eyebrow: "SOLO PACE",
                    title: "session.target_pace",
                    icon: "timer",
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
                soloOptions

                PrimaryButton(title: "session.solo.start", icon: "play.fill") {
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

    private var hero: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                Text("SOLO RUN")
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(.white.opacity(0.72))
                    .tracking(1.4)

                Text("session.solo.hero.title")
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(.white)
                    .lineSpacing(4)

                HStack(spacing: AppTheme.Spacing.sm) {
                    SoloMetricPill(title: "session.record", value: "session.personal_record", inverse: true)
                    SoloMetricPill(title: "session.goal", value: LocalizedStringKey(viewModel.targetDistanceText), inverse: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.xxxl)

            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 116, weight: .bold))
                .foregroundColor(.white.opacity(0.16))
                .offset(x: 18, y: 22)
        }
        .background(AppTheme.kineticGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
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

            Slider(value: $viewModel.runningDuration, in: 10...90, step: 5)
                .tint(AppTheme.primary)

            HStack {
                Text("10m")
                Spacer()
                Text("90m")
            }
            .font(AppTheme.Fonts.caption)
            .foregroundColor(AppTheme.textTertiary)
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }

    private var soloOptions: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("session.solo.settings")
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)

            VStack(spacing: 0) {
                SoloToggleRow(
                    icon: "waveform",
                    iconBackground: AppTheme.primaryFixed,
                    title: "session.feature.voice_guide",
                    subtitle: "session.solo.voice_guide.subtitle",
                    isOn: $viewModel.voiceGuideEnabled
                )

                Divider()
                    .padding(.leading, 76)

                SoloToggleRow(
                    icon: "lock.shield.fill",
                    iconBackground: AppTheme.secondaryContainer,
                    title: "session.solo.private_record",
                    subtitle: "session.solo.private_record.subtitle",
                    isOn: $viewModel.soloPrivateRecord
                )
            }
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
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
}

private struct SoloValueCard: View {
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
                SoloRoundStepButton(systemName: "minus", background: AppTheme.surfaceContainerHigh, foreground: AppTheme.text, action: minusAction)
                SoloRoundStepButton(systemName: "plus", background: AppTheme.primary, foreground: .white, action: plusAction)
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

private struct SoloRoundStepButton: View {
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

private struct SoloMetricPill: View {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
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

private struct SoloToggleRow: View {
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

private enum SoloInputField: Identifiable {
    case distance
    case pace

    var id: String { title }

    var title: String {
        switch self {
        case .distance:
            return String(localized: "session.input.solo_distance.title")
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
