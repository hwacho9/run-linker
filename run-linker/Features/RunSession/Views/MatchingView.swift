import SwiftUI

struct MatchingView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    @State private var pulse = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxxl) {
                radar

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(viewModel.matchedPartner == nil ? "session.matching.searching_title" : "session.matching.found_title")
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)

                    Text(viewModel.matchedPartner == nil ? "session.matching.searching_description" : "session.matching.found_description")
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                if let partner = viewModel.matchedPartner {
                    recommendedMatchCard(partner)
                } else if viewModel.isSearching {
                    AppCard {
                        HStack(spacing: AppTheme.Spacing.md) {
                            ProgressView()
                                .tint(AppTheme.primary)
                            Text(viewModel.waitingRunnerSummary)
                                .font(AppTheme.Fonts.body)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                } else {
                    AppCard {
                        VStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                                .font(.system(size: 30))
                                .foregroundColor(AppTheme.textTertiary)
                            Button("profile_sync.retry") { viewModel.retryMatching() }
                                .font(AppTheme.Fonts.bodyMedium)
                                .foregroundColor(AppTheme.primary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if let error = viewModel.flowErrorMessage {
                    Text(error)
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.Spacing.lg)
                        .background(AppTheme.errorContainer)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton(title: "session.start_together", icon: "bolt.fill") {
                        viewModel.acceptMatch()
                    }
                    .disabled(viewModel.matchedPartner == nil)
                    .opacity(viewModel.matchedPartner == nil ? 0.55 : 1)

                    if viewModel.selectedMode == .random {
                        Button {
                            viewModel.findAnotherRunner()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Text("session.matching.find_another")
                                    .font(AppTheme.Fonts.subheadline)
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(AppTheme.surfaceContainerLowest)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.outlineVariant.opacity(0.7), lineWidth: 1))
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxxxl)
        }
        .onAppear {
            pulse = true
        }
    }

    private var radar: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .trim(from: 0.08, to: 0.88)
                    .stroke(AppTheme.primaryFixedDim.opacity(0.82 - Double(index) * 0.16), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: CGFloat(190 + index * 56), height: CGFloat(190 + index * 56))
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 16))
                    .scaleEffect(pulse ? 1.04 : 0.96)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true).delay(Double(index) * 0.12), value: pulse)
            }

            Circle()
                .fill(AppTheme.primary)
                .frame(width: 88, height: 88)
                .shadow(color: AppTheme.primary.opacity(0.25), radius: 14, y: 8)
                .overlay(
                    Image(systemName: "scope")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .frame(height: 250)
    }

    private func recommendedMatchCard(_ partner: User) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("session.matching.found_title")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.onSecondaryContainer)
                        .tracking(1.2)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.secondaryContainer)
                        .clipShape(Capsule())

                    Text(verbatim: partner.name)
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("session.location.blurred")
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(Color(hex: "#F3E4CC"))
                    .frame(width: 94, height: 94)
                    .rotationEffect(.degrees(3))
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(AppTheme.deepNavy)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .stroke(.white, lineWidth: 4)
                    )
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                MatchStatBox(
                    title: "session.average_pace",
                    value: partner.averagePace.map(ActivityStatsSnapshot.paceText) ?? "--'--\"",
                    unit: "/km"
                )
                MatchStatBox(title: "session.target_distance", value: viewModel.targetDistanceText, unit: nil)
            }

            Text("session.matching.quote \(Int(viewModel.targetDistance))")
                .font(AppTheme.Fonts.body)
                .foregroundColor(AppTheme.text)
                .italic()
                .lineSpacing(5)
                .padding(AppTheme.Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surfaceContainerHigh.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        }
        .padding(AppTheme.Spacing.xxl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.outlineVariant.opacity(0.18), lineWidth: 1)
        )
    }

}

private struct MatchStatBox: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.Fonts.metricMedium)
                    .foregroundColor(AppTheme.primary)
                if let unit {
                    Text(unit)
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}
