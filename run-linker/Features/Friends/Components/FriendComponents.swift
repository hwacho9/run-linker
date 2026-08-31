import Foundation
import SwiftUI

// MARK: - Available Friend Card (Stitch: min-w-280, bg-surface-container-lowest, rounded-xl, p-6)
struct AvailableFriendCard: View {
    let name: String
    let avgPace: String
    let todayInfo: String
    var isFavorite = false
    var onRun: () -> Void = {}
    var onFavorite: () -> Void = {}
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
            // Profile + status
            HStack(spacing: AppTheme.Spacing.lg) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Text(String(name.prefix(1)))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                        )
                    Circle()
                        .fill(AppTheme.secondaryFixed)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(AppTheme.surfaceContainerLowest, lineWidth: 2))
                }
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(name)
                        .font(AppTheme.Fonts.titleMedium)
                        .foregroundColor(AppTheme.text)
                    FitnessChip("friends.status.available_now")
                }
            }
            
            // Stats grid (Stitch: grid-cols-2, bg-surface-container-low, rounded-lg)
            HStack(spacing: AppTheme.Spacing.lg) {
                MiniStatBox(label: "friends.stat.avg_pace", value: avgPace)
                MiniStatBox(label: "friends.stat.today", value: todayInfo)
            }
            
            // Action buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                Button("friends.run_together", action: onRun)
                    .font(AppTheme.Fonts.bodyMedium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? AppTheme.secondary : AppTheme.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.surfaceContainerHigh)
                        .clipShape(Circle())
                }
            }
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(width: 280)
        .background(AppTheme.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .stroke(AppTheme.outlineVariant.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Mini Stat Box
private struct MiniStatBox: View {
    let label: LocalizedStringKey
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.outlineVariant)
                .tracking(0.8)
                .textCase(.uppercase)
            Text(value)
                .font(AppTheme.Fonts.label)
                .foregroundColor(AppTheme.text)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
    }
}

// MARK: - Recent Partner Row (Stitch: bg-surface-container-low, rounded-xl, p-5)
struct RecentPartnerRow: View {
    let name: String
    let detail: String
    let syncScore: Int
    var onRunAgain: () -> Void = {}
    
    var body: some View {
        HStack {
            HStack(spacing: AppTheme.Spacing.lg) {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.text)
                    Text(detail)
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.outline)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("sync.score")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .tracking(0.5)
                    Text("\(syncScore)%")
                        .font(AppTheme.Fonts.label)
                        .foregroundColor(AppTheme.primary)
                }
                Button("friends.run_again", action: onRunAgain)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.onPrimaryFixedVariant)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, 6)
                    .background(AppTheme.primaryFixedDim)
                    .clipShape(Capsule())
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

// MARK: - All Friend Row (Stitch: flex items-center, w-12 h-12 avatar, status dot)
struct AllFriendRow: View {
    let name: String
    let detail: String
    let isOnline: Bool
    let statusText: LocalizedStringKey
    var isFavorite = false
    var onRun: () -> Void = {}
    var onFavorite: () -> Void = {}
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    )
                Circle()
                    .fill(isOnline ? AppTheme.secondaryFixed : AppTheme.outlineVariant)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(AppTheme.surface, lineWidth: 2))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(name)
                        .font(AppTheme.Fonts.body)
                    Text(statusText)
                        .font(.system(size: 10))
                        .foregroundColor(isOnline ? AppTheme.secondary : AppTheme.outline)
                }
                Text(detail)
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.outlineVariant)
            }
            
            Spacer()
            
            if isOnline {
                Button("friends.join", action: onRun)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            } else {
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? AppTheme.secondary : AppTheme.outline)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Invite Banner (Stitch: bg-inverse-surface, Lime button, decorative)
struct InviteBanner: View {
    var inviteText: String = "RunLinker"

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("friends.invite.title")
                        .font(AppTheme.Fonts.titleMedium)
                        .foregroundColor(AppTheme.inverseOnSurface)
                    Text("friends.invite.subtitle")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.inverseOnSurface.opacity(0.7))
                }
                
                ShareLink(item: inviteText) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("friends.invite.send_link")
                            .font(AppTheme.Fonts.bodyMedium)
                    }
                    .foregroundColor(AppTheme.onSecondaryFixed)
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.secondaryFixed)
                    .clipShape(Capsule())
                }
            }
            .padding(AppTheme.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "link")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.1))
                .rotationEffect(.degrees(12))
                .offset(x: 16, y: 16)
        }
        .background(AppTheme.inverseSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}
