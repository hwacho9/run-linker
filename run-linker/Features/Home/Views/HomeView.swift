import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()
    @State private var presentedRunMode: RunMode?
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── Top App Bar (Stitch: RunLinker logo + icons) ───
            TopAppBar()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    
                    // ─── Hero CTA (Stitch: kinetic-gradient + Lime button) ───
                    HeroCTACard {
                        presentedRunMode = .friend
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Quick Actions (Stitch: 2-col grid + full-width) ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            QuickActionButton(icon: "person.2.fill", title: "home.quick.friend") {
                                presentedRunMode = .friend
                            }
                            QuickActionButton(icon: "shuffle", title: "home.quick.random") {
                                presentedRunMode = .random
                            }
                        }
                        QuickActionButton(icon: "figure.run", title: "home.quick.solo") {
                            presentedRunMode = .solo
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Recent Run Report Card ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("home.section.recent_report")
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        if let session = viewModel.recentSession {
                            recentRunCard(session)
                                .padding(.horizontal, AppTheme.Spacing.xxl)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .tint(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(AppTheme.Spacing.xxxl)
                        } else {
                            AppCard {
                                Text(viewModel.errorMessage ?? String(localized: "activity.empty.title"))
                                    .font(AppTheme.Fonts.body)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        }
                    }
                    
                    // ─── Weekly Stats Bento Grid ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("home.section.weekly_stats", trailing: "common.detail") {}
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        HStack(spacing: AppTheme.Spacing.lg) {
                            StatChip(
                                title: "home.stat.total_distance",
                                value: String(format: "%.1f km", viewModel.weeklyDistance),
                                icon: "point.topleft.down.to.point.bottomright.curvepath",
                                variant: .neutral
                            )
                            StatChip(
                                title: "home.stat.average_pace",
                                value: viewModel.averagePaceText,
                                icon: "timer",
                                variant: .accent
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── Recent Running Partners ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        SectionHeader("home.section.recent_crew")
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                if viewModel.recentPartners.isEmpty {
                                    Text("common.none")
                                        .font(AppTheme.Fonts.bodySmall)
                                        .foregroundColor(AppTheme.textSecondary)
                                } else {
                                    ForEach(viewModel.recentPartners) { partner in
                                        PartnerAvatar(name: partner.name, isActive: partner.isAvailable, imageUrl: partner.avatarUrl)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        }
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
            .refreshable { await viewModel.loadData() }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.loadData()
        }
        .fullScreenCover(item: $presentedRunMode) { mode in
            SessionFlowView(initialMode: mode)
        }
    }

    private func recentRunCard(_ session: RunSession) -> some View {
        let partners = session.participants.filter { $0.id != session.participants.first?.id }
        return AppCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Fonts.labelSmall)
                        .foregroundColor(AppTheme.textTertiary)
                    Text(session.mode.title)
                        .font(AppTheme.Fonts.headingMedium)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                HStack(spacing: -12) {
                    ForEach(session.participants.prefix(3)) { participant in
                        Circle()
                            .fill(AppTheme.primary.opacity(0.16))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(participant.name.prefix(1)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.primary)
                            )
                            .overlay(Circle().stroke(AppTheme.surfaceContainerLow, lineWidth: 2))
                    }
                }
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                StatCell(label: "run.metric.distance", value: String(format: "%.2f", session.distance), unit: "km")
                StatCell(label: "run.metric.time", value: durationText(session), unit: nil)
                StatCell(label: "run.metric.pace", value: ActivityStatsSnapshot.paceText(session.averagePace), unit: nil)
            }
            .padding(.top, AppTheme.Spacing.sm)

            if !partners.isEmpty {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondary)
                    Text("home.recent.partner_label")
                        .font(AppTheme.Fonts.bodyMedium)
                    Text(partners.map(\.name).joined(separator: ", "))
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.primary)
                    Text("home.recent.completed_suffix")
                        .font(AppTheme.Fonts.bodyMedium)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
    }

    private func durationText(_ session: RunSession) -> String {
        let duration = max(0, Int(session.endTime?.timeIntervalSince(session.startTime) ?? 0))
        return String(format: "%02d:%02d", duration / 60, duration % 60)
    }
}

// MARK: - Stat Cell (used in run report card)
private struct StatCell: View {
    let label: LocalizedStringKey
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
