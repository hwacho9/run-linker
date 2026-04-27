import SwiftUI

struct FriendSelectionView: View {
    @ObservedObject var viewModel: SessionFlowViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("session.friend_selection.title")
                            .font(AppTheme.Fonts.heading)
                            .foregroundColor(AppTheme.text)
                        Text("session.friend_selection.subtitle")
                            .font(AppTheme.Fonts.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    VStack(spacing: AppTheme.Spacing.md) {
                        ForEach(viewModel.availableFriends) { friend in
                            FriendSelectionRow(
                                friend: friend,
                                isSelected: viewModel.selectedFriendId == friend.id
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    viewModel.selectFriend(friend)
                                }
                            }
                        }
                    }

                    AppCard {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 48, height: 48)
                                .background(AppTheme.primary.opacity(0.08))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("session.friend_selection.run_summary")
                                    .font(AppTheme.Fonts.subheadline)
                                    .foregroundColor(AppTheme.text)
                                Text("session.friend_selection.run_summary_detail \(viewModel.targetDistanceText) \(viewModel.targetPaceText)")
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.bottom, 120)
            }

            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton(title: "session.friend_selection.continue", icon: "arrow.right") {
                    viewModel.continueWithSelectedFriend()
                }
                .disabled(viewModel.selectedFriend == nil)
                .opacity(viewModel.selectedFriend == nil ? 0.5 : 1)
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .background(AppTheme.background)
        }
    }
}

private struct FriendSelectionRow: View {
    let friend: User
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Circle()
                    .fill(isSelected ? AppTheme.primary : AppTheme.primary.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(friend.name.prefix(1)))
                            .font(AppTheme.Fonts.titleMedium)
                            .foregroundColor(isSelected ? .white : AppTheme.primary)
                    )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(verbatim: friend.name)
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.text)
                    Text("session.friend_selection.friend_meta \(friend.level)")
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.primary : AppTheme.outlineVariant)
            }
            .padding(AppTheme.Spacing.xl)
            .background(isSelected ? AppTheme.primary.opacity(0.08) : AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .stroke(isSelected ? AppTheme.primary.opacity(0.42) : AppTheme.outlineVariant.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
