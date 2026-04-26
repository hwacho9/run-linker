import Foundation
import SwiftUI
import Combine

@MainActor
class SessionFlowViewModel: ObservableObject {
    @Published var selectedMode: RunMode = .friend
    @Published var targetDistance: Double = 5.0
    @Published var privacyMode = true
    
    // Live execution state
    @Published var syncScore: Int = 95
}

struct MatchSetupView: View {
    @StateObject private var viewModel = SessionFlowViewModel()
    
    var body: some View {
        ScreenContainer(title: "session.setup.title") {
            VStack {
                Picker("session.mode.picker", selection: $viewModel.selectedMode) {
                    Text("session.mode.friend").tag(RunMode.friend)
                    Text("session.mode.random").tag(RunMode.random)
                    Text("session.mode.solo").tag(RunMode.solo)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                AppCard {
                    Text(String(format: String(localized: "session.target_distance_format"), viewModel.targetDistance))
                        .font(AppTheme.Fonts.subheadline)
                    Slider(value: $viewModel.targetDistance, in: 1...42, step: 0.5)
                }
                .padding(.horizontal)
                
                if viewModel.selectedMode == .random {
                    AppCard {
                        Toggle("session.hide_exact_location", isOn: $viewModel.privacyMode)
                            .tint(AppTheme.primary)
                        Text("session.hide_exact_location.description")
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                PrimaryButton(title: "session.find_match", action: {
                    // Action transitions to Matching View
                })
                .padding()
            }
        }
    }
}

// Live Run Shell
struct LiveRunView: View {
    @StateObject private var viewModel = SessionFlowViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("session.live.title")
                        .font(AppTheme.Fonts.heading)
                    Text("session.live.time_sample")
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.primary)
                }
                Spacer()
                Text(String(format: String(localized: "activity.sync_format"), viewModel.syncScore))
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding()
            .background(AppTheme.surface)
            
            // Pair View Placeholder
            Rectangle()
                .fill(Color.orange.opacity(0.2))
                .frame(height: 100)
                .overlay(Text("session.pair_view_placeholder"))
            
            // Split Maps
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(Text("session.my_info"))
                Rectangle()
                    .fill(Color.purple.opacity(0.1))
                    .overlay(Text("session.partner_map_fuzzed"))
            }
            
            PrimaryButton(title: "session.finish_run", action: {})
                .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}
