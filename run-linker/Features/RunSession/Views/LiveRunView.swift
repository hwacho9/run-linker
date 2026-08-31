import SwiftUI

struct LiveRunView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("session.live_run")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.primary)
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Text(viewModel.formattedLiveTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.text)
                }
                Spacer()
                if viewModel.selectedMode != .solo {
                    SyncBar(score: viewModel.syncScore)
                        .frame(width: 120)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.top, 60)
            .padding(.bottom, AppTheme.Spacing.md)
            .background(AppTheme.surfaceContainerLowest)
            
            // Pair View (Progress Bar)
            if viewModel.selectedMode != .solo {
                PairViewProgress(myDistance: viewModel.displayedDistance, partnerDistance: viewModel.partnerDistance, targetDistance: viewModel.targetDistance)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.surfaceContainerLowest)
            }
            
            // Split Maps
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    RunRouteMapView(
                        routePoints: viewModel.soloTracker.routePoints,
                        currentLocation: viewModel.soloTracker.currentLocation
                    )
                    .ignoresSafeArea(edges: .horizontal)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        FitnessChip("session.live.route_recording", color: AppTheme.surfaceContainerLowest)
                        if viewModel.selectedMode != .solo, viewModel.privacyMode {
                            FitnessChip("session.location.blurred", color: AppTheme.surfaceContainerHigh)
                        }
                        if let message = viewModel.soloTracker.locationErrorMessage {
                            Text(message)
                                .font(AppTheme.Fonts.caption)
                                .foregroundColor(AppTheme.error)
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.errorContainer)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                }
                .frame(height: geo.size.height)
            }
            
            // Stats Panel
            VStack(spacing: AppTheme.Spacing.xl) {
                HStack {
                    StatMetric(title: "session.distance", value: String(format: "%.2f", viewModel.displayedDistance), unit: "km")
                    Spacer()
                    StatMetric(title: "session.current_pace", value: viewModel.formattedLivePace, unit: "/km")
                }
                
                // Controls
                HStack(spacing: AppTheme.Spacing.xl) {
                    if viewModel.selectedMode != .solo {
                        // Quick Cheer
                        Button(action: viewModel.sendCheer) {
                            VStack(spacing: 8) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppTheme.onSecondaryContainer)
                                    .frame(width: 72, height: 72)
                                    .background(AppTheme.secondaryContainer)
                                    .clipShape(Circle())
                                    .shadow(color: AppTheme.secondaryContainer.opacity(0.3), radius: 8, y: 4)
                            }
                        }
                    }
                    
                    // Pause/Resume
                    Button(action: {
                        viewModel.pauseOrResumeLiveRun()
                    }) {
                        Image(systemName: viewModel.isLiveRunPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.isLiveRunPaused ? .white : AppTheme.text)
                            .frame(width: 88, height: 88)
                            .background(viewModel.isLiveRunPaused ? AppTheme.primary : AppTheme.surfaceContainerHighest)
                            .clipShape(Circle())
                            .shadow(color: (viewModel.isLiveRunPaused ? AppTheme.primary : Color.black).opacity(0.15), radius: 10, y: 5)
                    }
                    
                    // Stop
                    Button(action: {
                        viewModel.stopLiveRun()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .padding(AppTheme.Spacing.xxl)
            .background(AppTheme.surfaceContainerLowest)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
            .shadow(color: Color.black.opacity(0.05), radius: 20, y: -5)
        }
        .background(AppTheme.surfaceContainerLowest.ignoresSafeArea())
        .onAppear {
            viewModel.startLiveRunTrackingIfNeeded()
        }
        .onDisappear {
            viewModel.stopLiveRunTrackingIfNeeded()
        }
    }
}

struct StatMetric: View {
    let title: LocalizedStringKey
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(AppTheme.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.text)
                Text(unit)
                    .font(AppTheme.Fonts.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

struct PairViewProgress: View {
    let myDistance: Double
    let partnerDistance: Double
    let targetDistance: Double
    
    var body: some View {
        GeometryReader { geo in
            let myProgress = min(myDistance / targetDistance, 1.0)
            let partnerProgress = min(partnerDistance / targetDistance, 1.0)
            
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(AppTheme.surfaceContainerHigh)
                    .frame(height: 12)
                
                // Partner Marker
                Circle()
                    .fill(AppTheme.outlineVariant)
                    .frame(width: 24, height: 24)
                    .offset(x: max(0, geo.size.width * partnerProgress - 12))
                
                // My Marker
                Circle()
                    .fill(AppTheme.primary)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 2)
                    .offset(x: max(0, geo.size.width * myProgress - 12))
            }
        }
        .frame(height: 24)
        .padding(.horizontal, AppTheme.Spacing.xxl)
    }
}
