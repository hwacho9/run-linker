import SwiftUI

extension SessionFlowStep: CaseIterable {
    static var allCases: [SessionFlowStep] {
        [.setup, .matching, .readyRoom, .liveRun, .results]
    }

    var order: Int {
        switch self {
        case .setup:
            return 0
        case .matching:
            return 1
        case .readyRoom:
            return 2
        case .liveRun:
            return 3
        case .results:
            return 4
        }
    }

    var title: String {
        switch self {
        case .setup:
            return "Match Setup"
        case .matching:
            return "Matching"
        case .readyRoom:
            return "Ready Room"
        case .liveRun:
            return "Live Run"
        case .results:
            return "Results"
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
                SessionFlowHeader(step: viewModel.currentStep) {
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
                    MatchSetupView(viewModel: viewModel)
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
    let back: () -> Void
    let close: () -> Void

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
                ForEach(SessionFlowStep.allCases, id: \.self) { item in
                    Capsule()
                        .fill(item.order <= step.order ? AppTheme.primary : AppTheme.surfaceContainerHigh)
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
