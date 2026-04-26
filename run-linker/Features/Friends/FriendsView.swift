import Foundation
import SwiftUI
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var query = ""
    @Published var selectedFilter = 0
    @Published var friends: [User] = [
        User(id: "1", name: "지혜", level: 7),
        User(id: "2", name: "민호", level: 5),
        User(id: "3", name: "소연", level: 6),
        User(id: "4", name: "준수", level: 4),
        User(id: "5", name: "유진", level: 3),
        User(id: "6", name: "도윤", level: 9)
    ]
    
    let filters = ["전체", "지금 가능", "즐겨찾기", "최근 함께 달린"]
}

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // ─── Header (Stitch: icon + title + Add Friend button) ───
            HStack {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(AppTheme.primary)
                    Text("Friends")
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                Button("Add Friend") {}
                    .font(AppTheme.Fonts.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.vertical, AppTheme.Spacing.sm + 2)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .frame(height: 80)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxxl) {
                    
                    // ─── Search + Filters ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Search (Stitch: bg-surface-container, rounded-xl, icon left)
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppTheme.outline)
                            TextField("친구 이름 검색", text: $viewModel.query)
                                .font(AppTheme.Fonts.body)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(AppTheme.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
                        
                        // Filter chips (Stitch: horizontal scroll, pill shape)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(viewModel.filters.indices, id: \.self) { i in
                                    FilterChip(viewModel.filters[i], isSelected: viewModel.selectedFilter == i) {
                                        viewModel.selectedFilter = i
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                    
                    // ─── Available Now (Stitch: horizontal scroll cards) ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        HStack {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Text("지금 달릴 수 있는 친구")
                                    .font(AppTheme.Fonts.headingSmall)
                                    .fontWeight(.heavy)
                                Circle()
                                    .fill(AppTheme.secondaryFixed)
                                    .frame(width: 8, height: 8)
                            }
                            Spacer()
                            Button("전체보기") {}
                                .font(AppTheme.Fonts.bodyMedium)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                AvailableFriendCard(
                                    name: "지혜 (Ji-Hye)",
                                    avgPace: "4'45\"",
                                    todayInfo: "8.2km"
                                )
                                AvailableFriendCard(
                                    name: "민호 (Min-Ho)",
                                    avgPace: "5'12\"",
                                    todayInfo: "준비 중"
                                )
                            }
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        }
                    }
                    
                    // ─── Recent Partners (Stitch: bg-surface-container-low cards) ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("최근 함께 달린 친구")
                            .font(AppTheme.Fonts.headingSmall)
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        VStack(spacing: AppTheme.Spacing.lg) {
                            RecentPartnerRow(
                                name: "소연 (So-Yeon)",
                                detail: "어제 오후 6:30 • 5.0km",
                                syncScore: 98
                            )
                            RecentPartnerRow(
                                name: "준수 (Jun-Su)",
                                detail: "3일 전 • 12.4km",
                                syncScore: 85
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── All Friends ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("전체 친구")
                            .font(AppTheme.Fonts.headingSmall)
                            .fontWeight(.heavy)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
                        VStack(spacing: AppTheme.Spacing.md) {
                            AllFriendRow(name: "유진 (Yu-Jin)", detail: "이번 주 2회 러닝 • 4'55\" 페이스", isOnline: false, statusText: "오프라인")
                            AllFriendRow(name: "도윤 (Do-Yoon)", detail: "이번 주 5회 러닝 • 4'10\" 페이스", isOnline: true, statusText: "지금 러닝 중")
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                    }
                    
                    // ─── Invite Banner (Stitch: inverse-surface bg, Lime button) ───
                    InviteBanner()
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Available Friend Card (Stitch: min-w-280, bg-surface-container-lowest, rounded-xl, p-6)
private struct AvailableFriendCard: View {
    let name: String
    let avgPace: String
    let todayInfo: String
    
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
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.text)
                    FitnessChip("지금 가능")
                }
            }
            
            // Stats grid (Stitch: grid-cols-2, bg-surface-container-low, rounded-lg)
            HStack(spacing: AppTheme.Spacing.lg) {
                MiniStatBox(label: "Avg Pace", value: avgPace)
                MiniStatBox(label: "Today", value: todayInfo)
            }
            
            // Action buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                Button("같이 달리기") {}
                    .font(AppTheme.Fonts.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                
                Button(action: {}) {
                    Image(systemName: "person.fill")
                        .foregroundColor(AppTheme.textSecondary)
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
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.outlineVariant)
                .tracking(0.8)
            Text(value)
                .font(AppTheme.Fonts.label)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.text)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.sm))
    }
}

// MARK: - Recent Partner Row (Stitch: bg-surface-container-low, rounded-xl, p-5)
private struct RecentPartnerRow: View {
    let name: String
    let detail: String
    let syncScore: Int
    
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
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.text)
                    Text(detail)
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.outline)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("SYNC SCORE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                        .tracking(0.5)
                    Text("\(syncScore)%")
                        .font(AppTheme.Fonts.label)
                        .fontWeight(.black)
                        .foregroundColor(AppTheme.primary)
                }
                Button("다시 달리기") {}
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
private struct AllFriendRow: View {
    let name: String
    let detail: String
    let isOnline: Bool
    let statusText: String
    
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
                        .fontWeight(.bold)
                    Text(statusText)
                        .font(.system(size: 10))
                        .foregroundColor(isOnline ? AppTheme.secondary : AppTheme.outline)
                        .fontWeight(isOnline ? .bold : .regular)
                }
                Text(detail)
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.outlineVariant)
            }
            
            Spacer()
            
            if isOnline {
                Button("참가하기") {}
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            } else {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppTheme.outline)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Invite Banner (Stitch: bg-inverse-surface, Lime button, decorative)
private struct InviteBanner: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("친구를 초대하고\n같이 달려보세요")
                        .font(AppTheme.Fonts.titleMedium)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.inverseOnSurface)
                    Text("함께 달리면 동기부여가 2배!")
                        .font(AppTheme.Fonts.bodySmall)
                        .foregroundColor(AppTheme.inverseOnSurface.opacity(0.7))
                }
                
                Button(action: {}) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12))
                        Text("초대 링크 보내기")
                            .font(AppTheme.Fonts.bodyMedium)
                            .fontWeight(.bold)
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
