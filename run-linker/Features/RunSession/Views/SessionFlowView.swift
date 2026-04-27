import SwiftUI

extension SessionFlowStep: CaseIterable {
    static var allCases: [SessionFlowStep] {
        [.setup, .friendSelection, .matching, .readyRoom, .liveRun, .results]
    }

    static func visibleCases(for mode: RunMode) -> [SessionFlowStep] {
        switch mode {
        case .friend:
            return [.setup, .friendSelection, .readyRoom, .liveRun, .results]
        case .random:
            return [.setup, .matching, .readyRoom, .liveRun, .results]
        case .solo:
            return [.setup, .liveRun, .results]
        }
    }

    func order(for mode: RunMode) -> Int {
        Self.visibleCases(for: mode).firstIndex(of: self) ?? 0
    }

    var title: LocalizedStringKey {
        switch self {
        case .setup:
            return "session.step.setup"
        case .friendSelection:
            return "session.step.friend_selection"
        case .matching:
            return "session.step.matching"
        case .readyRoom:
            return "session.step.ready_room"
        case .liveRun:
            return "session.step.live_run"
        case .results:
            return "session.step.results"
        }
    }
}

extension RunMode: CaseIterable, Identifiable {
    static var allCases: [RunMode] {
        [.friend, .random, .solo]
    }

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .friend:
            return "session.mode.friend"
        case .random:
            return "session.mode.random"
        case .solo:
            return "session.mode.solo"
        }
    }

    var icon: String {
        switch self {
        case .friend:
            return "person.2.fill"
        case .random:
            return "shuffle"
        case .solo:
            return "figure.run"
        }
    }
}

struct SessionFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SessionFlowViewModel

    init(initialMode: RunMode = .friend) {
        _viewModel = StateObject(wrappedValue: SessionFlowViewModel(initialMode: initialMode))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.currentStep != .liveRun {
                SessionFlowHeader(step: viewModel.currentStep, mode: viewModel.selectedMode) {
                    if viewModel.currentStep == .setup {
                        dismiss()
                    } else {
                        viewModel.cancelSession()
                    }
                } close: {
                    viewModel.closeFlow()
                }
            }

            Group {
                switch viewModel.currentStep {
                case .setup:
                    if viewModel.selectedMode == .solo {
                        SoloRunSetupView(viewModel: viewModel)
                    } else {
                        MatchSetupView(viewModel: viewModel)
                    }
                case .friendSelection:
                    FriendSelectionView(viewModel: viewModel)
                case .matching:
                    MatchingView(viewModel: viewModel)
                case .readyRoom:
                    ReadyRoomView(viewModel: viewModel)
                case .liveRun:
                    LiveRunView(viewModel: viewModel)
                case .results:
                    ResultsView(viewModel: viewModel)
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            viewModel.onDismiss = {
                dismiss()
            }
        }
    }
}

private struct SessionFlowHeader: View {
    let step: SessionFlowStep
    let mode: RunMode
    let back: () -> Void
    let close: () -> Void

    private var visibleSteps: [SessionFlowStep] {
        SessionFlowStep.visibleCases(for: mode)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                Button(action: back) {
                    Image(systemName: step == .setup ? "xmark" : "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.text)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.surfaceContainerLow)
                        .clipShape(Circle())
                }

                VStack(spacing: 2) {
                    Text(step.title)
                        .font(AppTheme.Fonts.headingMedium)
                        .foregroundColor(AppTheme.text)
                    Text("RunLinker")
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(AppTheme.primary)
                        .tracking(1.2)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)

                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textTertiary)
                        .frame(width: 40, height: 40)
                }
                .opacity(step == .setup ? 0 : 1)
                .disabled(step == .setup)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(visibleSteps, id: \.self) { item in
                    Capsule()
                        .fill(item.order(for: mode) <= step.order(for: mode) ? AppTheme.primary : AppTheme.surfaceContainerHigh)
                        .frame(height: 5)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .padding(.top, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.md)
        .background(AppTheme.background)
    }
}
