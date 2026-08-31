import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    @State private var showsAddFriend = false
    @State private var presentedRunFriend: User?
    @State private var acceptedMatchRequest: MatchRequest?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(AppTheme.primary)
                    Text("tab.friends")
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                Button("friends.add") { showsAddFriend = true }
                    .font(AppTheme.Fonts.bodyMedium)
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
                    searchAndFilters

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppTheme.primary)
                            .padding(AppTheme.Spacing.xxxl)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTheme.Fonts.bodySmall)
                            .foregroundColor(AppTheme.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.lg)
                            .background(AppTheme.errorContainer)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                    }

                    if !viewModel.incomingRequests.isEmpty { incomingRequestsSection }
                    if !viewModel.runInvitations.isEmpty { runInvitationsSection }
                    availableSection
                    recentPartnersSection
                    allFriendsSection

                    InviteBanner(inviteText: String(localized: "friends.invite.title"))
                        .padding(.horizontal, AppTheme.Spacing.xxl)
                        .padding(.bottom, AppTheme.Spacing.xxxxl)
                }
                .padding(.top, AppTheme.Spacing.lg)
            }
            .refreshable { await viewModel.load() }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .sheet(isPresented: $showsAddFriend) { addFriendSheet }
        .fullScreenCover(item: $presentedRunFriend) { friend in
            SessionFlowView(initialMode: .friend, initialFriend: friend)
        }
        .fullScreenCover(item: $acceptedMatchRequest) { request in
            SessionFlowView(initialMode: .friend, initialMatchRequest: request)
        }
    }

    private var searchAndFilters: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.outline)
                TextField("friends.search.placeholder", text: $viewModel.query)
                    .font(AppTheme.Fonts.body)
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(viewModel.filters.indices, id: \.self) { index in
                        FilterChip(
                            viewModel.filters[index],
                            isSelected: viewModel.selectedFilter == index
                        ) {
                            viewModel.selectedFilter = index
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    private var incomingRequestsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("friends.add")
                .font(AppTheme.Fonts.headingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.incomingRequests) { request in
                HStack(spacing: AppTheme.Spacing.md) {
                    PartnerAvatar(name: request.sender.name, imageUrl: request.sender.avatarUrl)
                    Text(request.sender.name)
                        .font(AppTheme.Fonts.body)
                    Spacer()
                    Button {
                        Task { await viewModel.respond(to: request, accept: false) }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        Task { await viewModel.respond(to: request, accept: true) }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    private var runInvitationsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("session.mode.friend")
                .font(AppTheme.Fonts.headingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.runInvitations) { invitation in
                HStack(spacing: AppTheme.Spacing.md) {
                    PartnerAvatar(name: invitation.sender.name, isActive: true, imageUrl: invitation.sender.avatarUrl)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(invitation.sender.name)
                            .font(AppTheme.Fonts.body)
                        Text(String(format: "%.1f km", invitation.request.targetDistance ?? 0))
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button("session.start_together") {
                        Task {
                            acceptedMatchRequest = await viewModel.acceptRunInvitation(invitation)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    private var availableSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("friends.section.available")
                        .font(AppTheme.Fonts.headingSmall)
                    Circle()
                        .fill(AppTheme.secondaryFixed)
                        .frame(width: 8, height: 8)
                }
                Spacer()
                if !viewModel.availableFriends.isEmpty {
                    Button("common.view_all") { viewModel.selectedFilter = 1 }
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.primary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)

            if viewModel.availableFriends.isEmpty {
                Text("common.none")
                    .font(AppTheme.Fonts.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.xxl)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.lg) {
                        ForEach(viewModel.availableFriends) { friend in
                            AvailableFriendCard(
                                name: friend.name,
                                avgPace: friend.averagePace.map(ActivityStatsSnapshot.paceText) ?? "--'--\"",
                                todayInfo: String(format: "%.1f km", friend.weeklyDistance),
                                isFavorite: friend.isFavorite,
                                onRun: { presentedRunFriend = friend },
                                onFavorite: { Task { await viewModel.toggleFavorite(friend) } }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxl)
                }
            }
        }
    }

    private var recentPartnersSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("friends.section.recent")
                .font(AppTheme.Fonts.headingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.recentPartners.isEmpty {
                Text("common.none")
                    .font(AppTheme.Fonts.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.recentPartners) { item in
                    RecentPartnerRow(
                        name: item.user.name,
                        detail: "\(item.session.startTime.formatted(date: .abbreviated, time: .shortened)) · \(String(format: "%.1f km", item.session.distance))",
                        syncScore: item.session.syncScore ?? 0,
                        onRunAgain: { presentedRunFriend = item.user }
                    )
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    private var allFriendsSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("friends.section.all")
                .font(AppTheme.Fonts.headingSmall)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.visibleFriends.isEmpty {
                Text("common.none")
                    .font(AppTheme.Fonts.bodySmall)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.visibleFriends) { friend in
                    AllFriendRow(
                        name: friend.name,
                        detail: friendDetail(friend),
                        isOnline: friend.isAvailable,
                        statusText: friend.isAvailable ? "friends.status.available_now" : "friends.status.offline",
                        isFavorite: friend.isFavorite,
                        onRun: { presentedRunFriend = friend },
                        onFavorite: { Task { await viewModel.toggleFavorite(friend) } }
                    )
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "magnifyingglass")
                    TextField("friends.search.placeholder", text: $viewModel.query)
                        .textInputAutocapitalization(.never)
                        .onSubmit { Task { await viewModel.searchRunners() } }
                    Button {
                        Task { await viewModel.searchRunners() }
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(AppTheme.primary)
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))

                if viewModel.isSearching {
                    ProgressView().tint(AppTheme.primary)
                }

                List(viewModel.searchResults) { runner in
                    HStack {
                        PartnerAvatar(name: runner.name, isActive: runner.isAvailable, imageUrl: runner.avatarUrl)
                        VStack(alignment: .leading) {
                            Text(runner.name)
                            Text(runner.averagePace.map(ActivityStatsSnapshot.paceText) ?? "--'--\"")
                                .font(AppTheme.Fonts.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            Task { await viewModel.sendFriendRequest(to: runner) }
                        } label: {
                            Image(systemName: viewModel.requestedUserIds.contains(runner.id) ? "checkmark" : "person.badge.plus")
                        }
                        .disabled(viewModel.requestedUserIds.contains(runner.id))
                    }
                }
                .listStyle(.plain)
            }
            .padding(AppTheme.Spacing.xxl)
            .navigationTitle("friends.add")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.cancel") { showsAddFriend = false }
                }
            }
        }
    }

    private func friendDetail(_ friend: User) -> String {
        let pace = friend.averagePace.map(ActivityStatsSnapshot.paceText) ?? "--'--\""
        return "\(friend.weeklyRunCount) · \(pace)"
    }
}
