import Foundation
import SwiftUI
import Combine

@MainActor
class MyViewModel: ObservableObject {
    @Published var locationSharing = true
    @Published var randomMatchPublic = true
    @Published var recordsPublic = true
    @Published var blurStartEnd = true
    @Published var cheerNotifications = true
    @Published var runStartNotifications = true
    @Published var voiceEnabled = true
}

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── Header ───
            HStack {
                Text("마이")
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(AppTheme.text)
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .frame(height: 64)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    
                    // ─── Profile Card (Stitch: avatar + name + tagline + Weekly Goal badge) ───
                    HStack(spacing: AppTheme.Spacing.lg) {
                        Circle()
                            .fill(AppTheme.primaryGradient)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text("JP")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Jayden Park")
                                .font(AppTheme.Fonts.titleLarge)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.text)
                            Text("함께 달리는 즐거움, RunLinker!")
                                .font(AppTheme.Fonts.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Weekly Goal badge
                        Text("Weekly Goal")
                            .font(AppTheme.Fonts.captionSmall)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.onSecondaryContainer)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.secondaryContainer)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Weekly Goal Card ───
                    AppCard {
                        Text("이번 주 목표 20km")
                            .font(AppTheme.Fonts.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.text)
                        
                        HStack(alignment: .bottom, spacing: AppTheme.Spacing.lg) {
                            ProgressRing(progress: 0.62, lineWidth: 10, size: 72)
                                .overlay(
                                    VStack(spacing: 0) {
                                        Text("12.4")
                                            .font(AppTheme.Fonts.label)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppTheme.primary)
                                        Text("km total")
                                            .font(.system(size: 8))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                )
                            
                            Text("목표까지 7.6km 남았어요!")
                                .font(AppTheme.Fonts.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Stats Grid (Stitch: 2x2 grid of stat chips) ───
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.lg) {
                        StatChip(title: "총 누적 거리", value: "524.8km", icon: "point.topleft.down.to.point.bottomright.curvepath", variant: .neutral)
                        StatChip(title: "러닝 횟수", value: "64회", icon: "figure.run", variant: .neutral)
                        StatChip(title: "평균 페이스", value: "5'22\"", icon: "timer", variant: .accent)
                        StatChip(title: "평균 싱크", value: "92%", icon: "link", variant: .accent)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Privacy & Sharing Section ───
                    SettingsSection(title: "Privacy & Sharing") {
                        SettingsToggleRow(
                            icon: "location.fill",
                            title: "위치 공유 설정",
                            subtitle: "러닝 중 친구들에게 내 위치를 노출합니다",
                            isOn: $viewModel.locationSharing
                        )
                        SettingsToggleRow(
                            icon: "shuffle",
                            title: "랜덤 매칭 공개 범위",
                            subtitle: "함께 달릴 러너를 찾는 범위를 설정합니다",
                            isOn: $viewModel.randomMatchPublic
                        )
                        SettingsToggleRow(
                            icon: "doc.text.fill",
                            title: "러닝 기록 공개 범위",
                            subtitle: "나의 운동 일지를 볼 수 있는 사람을 선택합니다",
                            isOn: $viewModel.recordsPublic
                        )
                        SettingsToggleRow(
                            icon: "eye.slash.fill",
                            title: "시작/종료 지점 흐리기",
                            subtitle: "집이나 직장 주소 노출 방지를 위해 가립니다",
                            isOn: $viewModel.blurStartEnd
                        )
                    }
                    
                    // ─── Notifications Section ───
                    SettingsSection(title: "Notifications") {
                        SettingsRow(icon: "bell.fill", title: "알림 설정")
                        SettingsToggleRow(icon: "hands.clap.fill", title: "응원 알림", isOn: $viewModel.cheerNotifications)
                        SettingsToggleRow(icon: "figure.run", title: "러닝 시작 알림", isOn: $viewModel.runStartNotifications)
                        SettingsToggleRow(icon: "waveform", title: "음성 기능 설정", isOn: $viewModel.voiceEnabled)
                    }
                    
                    // ─── Safety & Account ───
                    SettingsSection(title: "Safety & Account") {
                        SettingsRow(icon: "nosign", title: "차단한 사용자")
                        SettingsRow(icon: "exclamationmark.shield.fill", title: "신고 내역")
                        SettingsRow(icon: "person.crop.circle", title: "계정 관리")
                        SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "로그아웃", showChevron: false)
                    }
                    
                    // ─── Support ───
                    SettingsSection(title: "Support") {
                        SettingsRow(icon: "questionmark.circle.fill", title: "도움말")
                        SettingsRow(icon: "envelope.fill", title: "문의하기")
                        SettingsRow(icon: "doc.plaintext.fill", title: "서비스 이용약관")
                        SettingsRow(icon: "hand.raised.fill", title: "개인정보 처리방침")
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Settings Section (Stitch: section with headline title, no dividers, spacing-based separation)
private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Fonts.headingSmall)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.text)
                .padding(.bottom, AppTheme.Spacing.sm)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
}
