import Foundation
import SwiftUI
import Combine

@MainActor
class ActivityViewModel: ObservableObject {
    private let repository: SessionRepositoryProtocol
    
    @Published var history: [RunSession] = []
    @Published var stats: (totalDistance: Double, averagePace: Int, sessionsCount: Int)? = nil
    
    init(repository: SessionRepositoryProtocol? = nil) {
        self.repository = repository ?? MockSessionService()
    }
    
    func loadActivityData() async {
        do {
            async let fetchHistory = repository.getSessionHistory()
            async let fetchStats = repository.getMyStats()
            
            let (h, s) = try await (fetchHistory, fetchStats)
            self.history = h
            self.stats = s
        } catch {
            print(error)
        }
    }
}

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        ScreenContainer(title: "tab.activity") {
            VStack {
                Picker("activity.picker", selection: $selectedTab) {
                    Text("activity.session_history").tag(0)
                    Text("activity.my_stats").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    buildSessionHistory()
                } else {
                    buildMyStats()
                }
            }
        }
        .task {
            await viewModel.loadActivityData()
        }
    }
    
    @ViewBuilder
    private func buildSessionHistory() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.history) { session in
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.Fonts.caption)
                                Spacer()
                                if session.mode == .friend {
                                    Text("activity.mode.friend").font(AppTheme.Fonts.caption).foregroundColor(AppTheme.primary)
                                } else if session.mode == .random {
                                    Text("activity.mode.random").font(AppTheme.Fonts.caption).foregroundColor(AppTheme.secondary)
                                }
                            }
                            
                            HStack {
                                Text("\(session.distance, specifier: "%.1f") km")
                                    .font(AppTheme.Fonts.heading)
                                Spacer()
                                if let sync = session.syncScore {
                                    Text(String(format: String(localized: "activity.sync_format"), sync)).font(AppTheme.Fonts.subheadline).foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func buildMyStats() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let stats = viewModel.stats {
                    AppCard {
                        HStack {
                            StatChip(title: "activity.stat.total_distance", value: String(format: "%.1f km", stats.totalDistance))
                            StatChip(title: "activity.stat.avg_pace", value: "\(stats.averagePace / 60):\(String(format: "%02d", stats.averagePace % 60)) /km")
                        }
                        StatChip(title: "activity.stat.total_sessions", value: "\(stats.sessionsCount)")
                    }
                    
                    AppCard {
                        Text("activity.weekly_progression")
                            .font(AppTheme.Fonts.subheadline)
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(Text("activity.chart_placeholder"))
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
    }
}
