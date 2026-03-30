import Foundation
import SwiftUI

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
        ScreenContainer(title: "Setup Run") {
            VStack {
                Picker("Mode", selection: $viewModel.selectedMode) {
                    Text("Friend").tag(RunMode.friend)
                    Text("Random").tag(RunMode.random)
                    Text("Solo").tag(RunMode.solo)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                AppCard {
                    Text("Target Distance: \(viewModel.targetDistance, specifier: "%.1f") km")
                        .font(AppTheme.Fonts.subheadline)
                    Slider(value: $viewModel.targetDistance, in: 1...42, step: 0.5)
                }
                .padding(.horizontal)
                
                if viewModel.selectedMode == .random {
                    AppCard {
                        Toggle("Hide Exact Location", isOn: $viewModel.privacyMode)
                            .tint(AppTheme.primary)
                        Text("Your exact starting and ending locations will be hidden from random partners.")
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                PrimaryButton(title: "Find Match", action: {
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
                    Text("Live Run")
                        .font(AppTheme.Fonts.heading)
                    Text("Time: 05:22")
                        .font(AppTheme.Fonts.subheadline)
                        .foregroundColor(AppTheme.primary)
                }
                Spacer()
                Text("Sync: \(viewModel.syncScore)%")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding()
            .background(AppTheme.surface)
            
            // Pair View Placeholder
            Rectangle()
                .fill(Color.orange.opacity(0.2))
                .frame(height: 100)
                .overlay(Text("Pair View: Visual progress side-by-side"))
            
            // Split Maps
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(Text("My Info"))
                Rectangle()
                    .fill(Color.purple.opacity(0.1))
                    .overlay(Text("Partner Map (Fuzzed)"))
            }
            
            PrimaryButton(title: "Finish Run", action: {})
                .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}
