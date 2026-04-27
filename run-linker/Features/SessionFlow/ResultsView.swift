import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    
    private var formattedTime: String {
        let minutes = Int(viewModel.elapsedTime) / 60
        let seconds = Int(viewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var formattedPace: String {
        guard viewModel.currentPace > 0 else { return "--'--\"" }
        let minutes = viewModel.currentPace / 60
        let seconds = viewModel.currentPace % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    var body: some View {
        ScreenContainer(title: "러닝 결과") {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    
                    // Main Summary
                    AppCard {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            if viewModel.selectedMode != .solo {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    PartnerAvatar(name: "You", isActive: false)
                                    Image(systemName: "link")
                                        .foregroundColor(AppTheme.outlineVariant)
                                    PartnerAvatar(name: viewModel.matchedPartner?.name ?? "Partner", isActive: false)
                                }
                                .padding(.bottom, AppTheme.Spacing.sm)
                                
                                VStack(spacing: AppTheme.Spacing.xs) {
                                    Text("Sync Score")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundColor(AppTheme.textTertiary)
                                    Text("\(viewModel.syncScore)%")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(AppTheme.primary)
                                }
                                
                                DividerWithText("요약")
                            }
                            
                            HStack(spacing: AppTheme.Spacing.lg) {
                                StatMetric(title: "거리", value: String(format: "%.2f", viewModel.currentDistance), unit: "km")
                                Spacer()
                                StatMetric(title: "시간", value: formattedTime, unit: "")
                                Spacer()
                                StatMetric(title: "평균 페이스", value: formattedPace, unit: "")
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // Map Summary
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("경로")
                            .font(AppTheme.Fonts.headingSmall)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, AppTheme.Spacing.xxl)

                        if viewModel.selectedMode == .solo, !viewModel.routePoints.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                RunRouteMapView(
                                    routePoints: viewModel.routePoints,
                                    currentLocation: viewModel.routePoints.last?.coordinate,
                                    followsUser: false
                                )
                                .frame(height: 220)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                                Text("내가 지나간 길")
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.md) {
                                    RouteCard(name: "내 경로")

                                    if viewModel.selectedMode != .solo {
                                        RouteCard(name: "\(viewModel.matchedPartner?.name ?? "Partner")의 경로")
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.xxl)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .overlay(
            VStack {
                Spacer()
                PrimaryButton(title: "홈으로 돌아가기") {
                    viewModel.closeFlow()
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.bottom, AppTheme.Spacing.xxl)
                .background(
                    LinearGradient(
                        colors: [AppTheme.background.opacity(0), AppTheme.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .offset(y: 20)
                )
            }
        )
    }
}

struct RouteCard: View {
    let name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.surfaceContainerHigh)
                    .frame(width: 200, height: 140)
                
                Image(systemName: "map.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.outlineVariant)
            }
            
            Text(name)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}
