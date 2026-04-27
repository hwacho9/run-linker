import SwiftUI

struct LiveRunView: View {
    @ObservedObject var viewModel: SessionFlowViewModel
    @State private var isPaused = false
    
    private var formattedTime: String {
        let minutes = Int(viewModel.elapsedTime) / 60
        let seconds = Int(viewModel.elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var formattedPace: String {
        let minutes = viewModel.currentPace / 60
        let seconds = viewModel.currentPace % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Live Run")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.primary)
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Text(formattedTime)
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
                PairViewProgress(myDistance: viewModel.currentDistance, partnerDistance: viewModel.currentDistance * 0.95, targetDistance: viewModel.targetDistance)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .background(AppTheme.surfaceContainerLowest)
            }
            
            // Split Maps
            GeometryReader { geo in
                VStack(spacing: 2) {
                    // Partner Map (if not solo)
                    if viewModel.selectedMode != .solo {
                        ZStack(alignment: .topLeading) {
                            MapPlaceholderBackground()
                            
                            HStack {
                                PartnerAvatar(name: viewModel.matchedPartner?.name ?? "Partner", isActive: true)
                                    .scaleEffect(0.6)
                                    .frame(width: 40, height: 40)
                                Spacer()
                                if viewModel.privacyMode {
                                    FitnessChip("흐림 처리됨", color: AppTheme.surfaceContainerHigh)
                                }
                            }
                            .padding(AppTheme.Spacing.md)
                        }
                        .frame(height: geo.size.height / 2)
                    }
                    
                    // My Map
                    ZStack(alignment: .topLeading) {
                        MapPlaceholderBackground(isMe: true)
                        
                        PartnerAvatar(name: "You", isActive: true)
                            .scaleEffect(0.6)
                            .frame(width: 40, height: 40)
                            .padding(AppTheme.Spacing.md)
                    }
                    .frame(height: viewModel.selectedMode == .solo ? geo.size.height : geo.size.height / 2)
                }
            }
            
            // Stats Panel
            VStack(spacing: AppTheme.Spacing.xl) {
                HStack {
                    StatMetric(title: "거리", value: String(format: "%.2f", viewModel.currentDistance), unit: "km")
                    Spacer()
                    StatMetric(title: "현재 페이스", value: formattedPace, unit: "/km")
                }
                
                // Controls
                HStack(spacing: AppTheme.Spacing.xl) {
                    if viewModel.selectedMode != .solo {
                        // Quick Cheer
                        Button(action: {
                            // Send cheer
                        }) {
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
                        isPaused.toggle()
                    }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 32))
                            .foregroundColor(isPaused ? .white : AppTheme.text)
                            .frame(width: 88, height: 88)
                            .background(isPaused ? AppTheme.primary : AppTheme.surfaceContainerHighest)
                            .clipShape(Circle())
                            .shadow(color: (isPaused ? AppTheme.primary : Color.black).opacity(0.15), radius: 10, y: 5)
                    }
                    
                    // Stop
                    Button(action: {
                        viewModel.finishRun()
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
    }
}

struct StatMetric: View {
    let title: String
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

struct MapPlaceholderBackground: View {
    var isMe: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(isMe ? AppTheme.surfaceContainerHigh : AppTheme.surfaceContainerHighest)
            
            // Grid lines
            GeometryReader { geo in
                Path { path in
                    let step: CGFloat = 40
                    for x in stride(from: 0, through: geo.size.width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, through: geo.size.height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(AppTheme.outlineVariant.opacity(0.3), lineWidth: 1)
            }
            
            // Map icon
            Image(systemName: isMe ? "location.fill" : "map.fill")
                .font(.system(size: 48))
                .foregroundColor((isMe ? AppTheme.primary : AppTheme.outlineVariant).opacity(isMe ? 0.2 : 0.5))
        }
        .clipped()
    }
}

