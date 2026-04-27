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
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = MyViewModel()
    @State private var showsLogoutConfirmation = false
    
    private var profileName: String {
        authVM.displayName.isEmpty ? String(localized: "my.profile.default_name") : authVM.displayName
    }
    
    private var profileSubtitle: String {
        authVM.email.isEmpty ? String(localized: "my.profile.default_subtitle") : authVM.email
    }
    
    private var profileInitials: String {
        let words = profileName
            .split(separator: " ")
            .map(String.init)
        let initials = words
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
        
        return initials.isEmpty ? "R" : initials.uppercased()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── Header ───
            HStack {
                Text("tab.my")
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(AppTheme.text)
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .frame(height: 64)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    if let warning = authVM.profileSyncWarningMessage {
                        ProfileSyncWarningCard(message: warning) {
                            Task {
                                await authVM.retryProfileSync()
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── Profile Card (Stitch: avatar + name + tagline + Weekly Goal badge) ───
                    HStack(spacing: AppTheme.Spacing.lg) {
                        Circle()
                            .fill(AppTheme.primaryGradient)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(profileInitials)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(profileName)
                                .font(AppTheme.Fonts.titleLarge)
                                .foregroundColor(AppTheme.text)
                            Text(profileSubtitle)
                                .font(AppTheme.Fonts.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Weekly Goal badge
                        Text("my.weekly_goal.badge")
                            .font(AppTheme.Fonts.captionSmall)
                            .foregroundColor(AppTheme.onSecondaryContainer)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.secondaryContainer)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Weekly Goal Card ───
                    AppCard {
                        Text("my.weekly_goal.title")
                            .font(AppTheme.Fonts.subheadline)
                            .foregroundColor(AppTheme.text)
                        
                        HStack(alignment: .bottom, spacing: AppTheme.Spacing.lg) {
                            ProgressRing(progress: 0.62, lineWidth: 10, size: 72)
                                .overlay(
                                    VStack(spacing: 0) {
                                        Text("12.4")
                                            .font(AppTheme.Fonts.label)
                                            .foregroundColor(AppTheme.primary)
                                        Text("my.weekly_goal.total_unit")
                                            .font(.system(size: 8))
                                            .foregroundColor(AppTheme.textTertiary)
                                    }
                                )
                            
                            Text("my.weekly_goal.remaining")
                                .font(AppTheme.Fonts.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Stats Grid (Stitch: 2x2 grid of stat chips) ───
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.lg) {
                        StatChip(title: "my.stat.total_distance", value: "524.8km", icon: "point.topleft.down.to.point.bottomright.curvepath", variant: .neutral)
                        StatChip(title: "my.stat.run_count", value: "64회", icon: "figure.run", variant: .neutral)
                        StatChip(title: "my.stat.average_pace", value: "5'22\"", icon: "timer", variant: .accent)
                        StatChip(title: "my.stat.average_sync", value: "92%", icon: "link", variant: .accent)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Privacy & Sharing Section ───
                    SettingsSection(title: "my.section.privacy") {
                        SettingsToggleRow(
                            icon: "location.fill",
                            title: "my.setting.location_sharing",
                            subtitle: "my.setting.location_sharing.subtitle",
                            isOn: $viewModel.locationSharing
                        )
                        SettingsToggleRow(
                            icon: "shuffle",
                            title: "my.setting.random_visibility",
                            subtitle: "my.setting.random_visibility.subtitle",
                            isOn: $viewModel.randomMatchPublic
                        )
                        SettingsToggleRow(
                            icon: "doc.text.fill",
                            title: "my.setting.records_visibility",
                            subtitle: "my.setting.records_visibility.subtitle",
                            isOn: $viewModel.recordsPublic
                        )
                        SettingsToggleRow(
                            icon: "eye.slash.fill",
                            title: "my.setting.blur_points",
                            subtitle: "my.setting.blur_points.subtitle",
                            isOn: $viewModel.blurStartEnd
                        )
                    }
                    
                    // ─── Notifications Section ───
                    SettingsSection(title: "my.section.notifications") {
                        SettingsRow(icon: "bell.fill", title: "my.setting.notifications")
                        SettingsToggleRow(icon: "hands.clap.fill", title: "my.setting.cheer_notifications", isOn: $viewModel.cheerNotifications)
                        SettingsToggleRow(icon: "figure.run", title: "my.setting.run_start_notifications", isOn: $viewModel.runStartNotifications)
                        SettingsToggleRow(icon: "waveform", title: "my.setting.voice", isOn: $viewModel.voiceEnabled)
                    }
                    
                    // ─── Safety & Account ───
                    SettingsSection(title: "my.section.safety_account") {
                        #if DEBUG
                        SettingsRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "my.setting.firestore_profile_sync_test",
                            showChevron: false
                        ) {
                            Task {
                                await authVM.syncCurrentUserProfileToFirestore()
                            }
                        }
                        #endif
                        SettingsRow(icon: "nosign", title: "my.setting.blocked_users")
                        SettingsRow(icon: "exclamationmark.shield.fill", title: "my.setting.reports")
                        SettingsRow(icon: "person.crop.circle", title: "my.setting.account")
                        SettingsRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "auth.logout",
                            showChevron: false
                        ) {
                            showsLogoutConfirmation = true
                        }
                    }
                    
                    // ─── Support ───
                    SettingsSection(title: "my.section.support") {
                        SettingsRow(icon: "questionmark.circle.fill", title: "my.setting.help")
                        SettingsRow(icon: "envelope.fill", title: "my.setting.contact")
                        SettingsRow(icon: "doc.plaintext.fill", title: "my.setting.terms")
                        SettingsRow(icon: "hand.raised.fill", title: "my.setting.privacy_policy")
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .alert("auth.logout", isPresented: $showsLogoutConfirmation) {
            Button("common.cancel", role: .cancel) {}
            Button("auth.logout", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("auth.logout.confirm_message")
        }
    }
}

private struct ProfileSyncWarningCard: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppTheme.error)
                Text(message)
                    .font(AppTheme.Fonts.bodySmall)
                    .foregroundColor(AppTheme.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: retry) {
                Text("profile_sync.retry")
                    .font(AppTheme.Fonts.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.error)
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.errorContainer)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

// MARK: - Settings Section (Stitch: section with headline title, no dividers, spacing-based separation)
private struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content
    
    init(title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Fonts.headingSmall)
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
