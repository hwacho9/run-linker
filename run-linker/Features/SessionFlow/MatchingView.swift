import SwiftUI

struct MatchingView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    @State private var pulse = false

    private var currentPartner: User {
        viewModel.matchedPartner ?? viewModel.selectedCandidate
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xxxl) {
                radar

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(viewModel.matchedPartner == nil ? "최적의 러너를 찾는 중..." : "추천 러너를 찾았습니다")
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.center)

                    Text("당신의 페이스와 목표에 딱 맞는 파트너를 검색하고 있습니다.")
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                recommendedMatchCard

                VStack(spacing: AppTheme.Spacing.md) {
                    PrimaryButton(title: "함께 시작하기", icon: "bolt.fill") {
                        viewModel.acceptMatch()
                    }
                    .disabled(viewModel.matchedPartner == nil)
                    .opacity(viewModel.matchedPartner == nil ? 0.55 : 1)

                    Button {
                        viewModel.findAnotherRunner()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Text("다른 러너 찾기")
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

    private var recommendedMatchCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("RECOMMENDED MATCH")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.onSecondaryContainer)
                        .tracking(1.2)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.secondaryContainer)
                        .clipShape(Capsule())

                    Text("\(currentPartner.name) (\(romanizedName(for: currentPartner.name)))")
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(AppTheme.textSecondary)
                        Text("서울, 서초구 반포한강공원")
                            .font(AppTheme.Fonts.bodyMedium)
                            .foregroundColor(AppTheme.textSecondary)
                    }
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
                MatchStatBox(title: "평균 페이스", value: pace(for: currentPartner), unit: "/km")
                MatchStatBox(title: "목표 거리", value: viewModel.targetDistanceText, unit: nil)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("최근 활동")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.primary)
                    Text("어제 밤, 한강 7km 러닝")
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                HStack(spacing: -8) {
                    MatchingSmallAvatar(color: AppTheme.secondaryContainer)
                    MatchingSmallAvatar(color: AppTheme.primaryFixedDim)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.primaryFixed.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

            Text("“오늘은 한강을 따라 시원하게 \(Int(viewModel.targetDistance))km 뛰고 싶네요. 함께 런링크 하실 분?”")
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

    private func romanizedName(for name: String) -> String {
        switch name {
        case "지훈":
            return "Ji-Hun"
        case "민수":
            return "Min-Su"
        case "서연":
            return "Seo-Yeon"
        default:
            return "Runner"
        }
    }

    private func pace(for user: User) -> String {
        switch user.id {
        case "candidate-1":
            return "4'45\""
        case "candidate-2":
            return "5'12\""
        default:
            return "5'28\""
        }
    }
}

private struct MatchStatBox: View {
    let title: String
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

private struct MatchingSmallAvatar: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 34, height: 34)
            .overlay(Circle().stroke(AppTheme.primaryFixed, lineWidth: 2))
    }
}
