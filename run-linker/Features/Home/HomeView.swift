import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── Top App Bar (Stitch: RunLinker logo + icons) ───
            TopAppBar()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    
                    // ─── Hero CTA (Stitch: kinetic-gradient + Lime button) ───
                    HeroCTACard {
                        print("Start Run Tapped")
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Quick Actions (Stitch: 2-col grid + full-width) ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            QuickActionButton(icon: "person.2.fill", title: "친구와 달리기") {}
                            QuickActionButton(icon: "shuffle", title: "랜덤 매칭") {}
                        }
                        QuickActionButton(icon: "person.fill", title: "혼자 달리기") {}
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Recent Run Report Card ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("최근 러닝 리포트")
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        AppCard {
                            // Top: date + partner avatars
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("2023. 11. 24 • 오전 7:30")
                                        .font(AppTheme.Fonts.labelSmall)
                                        .foregroundColor(AppTheme.textTertiary)
                                    Text("한강 시티 런")
                                        .font(AppTheme.Fonts.headingMedium)
                                        .foregroundColor(AppTheme.text)
                                }
                                Spacer()
                                // Stitch: overlapping profile pics
                                HStack(spacing: -12) {
                                    Circle()
                                        .fill(AppTheme.primary.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text("J").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.primary))
                                        .overlay(Circle().stroke(AppTheme.surfaceContainerLow, lineWidth: 2))
                                    Circle()
                                        .fill(AppTheme.secondaryContainer.opacity(0.4))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text("M").font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.onSecondaryContainer))
                                        .overlay(Circle().stroke(AppTheme.surfaceContainerLow, lineWidth: 2))
                                }
                            }
                            
                            // Stats grid (Stitch: grid-cols-3)
                            HStack(spacing: AppTheme.Spacing.lg) {
                                StatCell(label: "거리", value: "5.24", unit: "km")
                                StatCell(label: "시간", value: "28:12", unit: nil)
                                StatCell(label: "페이스", value: "5'22\"", unit: nil)
                            }
                            .padding(.top, AppTheme.Spacing.sm)
                            
                            // Partner completion (Stitch: border-t + handshake icon)
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondary)
                                Text("파트너 ")
                                    .font(AppTheme.Fonts.bodyMedium)
                                +
                                Text("김지수")
                                    .font(AppTheme.Fonts.bodyMedium)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.primary)
                                +
                                Text("님과 함께 완료!")
                                    .font(AppTheme.Fonts.bodyMedium)
                            }
                            .padding(.top, AppTheme.Spacing.lg)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── Weekly Stats Bento Grid ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("이번 주 통계", trailing: "상세보기") {}
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        HStack(spacing: AppTheme.Spacing.lg) {
                            StatChip(
                                title: "누적 거리",
                                value: String(format: "%.1f km", viewModel.totalDistance > 0 ? viewModel.totalDistance : 18.5),
                                icon: "point.topleft.down.to.point.bottomright.curvepath",
                                variant: .neutral
                            )
                            StatChip(
                                title: "평균 페이스",
                                value: "5'45\"",
                                icon: "timer",
                                variant: .accent
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── Recent Running Partners ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("최근 함께한 러닝 크루")
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                PartnerAvatar(name: "이민호", isActive: true)
                                PartnerAvatar(name: "최서연")
                                PartnerAvatar(name: "박준영")
                                PartnerAvatar(name: "정다은")
                                
                                // "더보기" button (Stitch: + icon in circle)
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    Circle()
                                        .fill(AppTheme.surfaceContainer)
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.primary)
                                        )
                                    Text("더보기")
                                        .font(AppTheme.Fonts.captionSmall)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppTheme.text)
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Stat Cell (used in run report card)
private struct StatCell: View {
    let label: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(AppTheme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTheme.Fonts.metricSmall)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)
                if let unit = unit {
                    Text(unit)
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
