import SwiftUI

struct ActivityView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ScreenContainer(title: "Activity") {
            VStack {
                Picker("Activity Tab", selection: $selectedTab) {
                    Text("Session History").tag(0)
                    Text("My Stats").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    SessionHistoryView()
                } else {
                    MyStatsView()
                }
            }
        }
    }
}

// MARK: - Subviews
struct SessionHistoryView: View {
    let mockService = MockSessionService()
    @State private var history: [RunSession] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(history) { session in
                    AppCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(AppTheme.Fonts.caption)
                                Spacer()
                                if session.mode == .friend {
                                    Text("Friend Run")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundColor(AppTheme.primary)
                                } else if session.mode == .random {
                                    Text("Random Match")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundColor(AppTheme.secondary)
                                }
                            }
                            
                            HStack {
                                Text("\(session.distance, specifier: "%.1f") km")
                                    .font(AppTheme.Fonts.heading)
                                Spacer()
                                if let sync = session.syncScore {
                                    Text("Sync: \(sync)%")
                                        .font(AppTheme.Fonts.subheadline)
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .task {
            do {
                self.history = try await mockService.getSessionHistory()
            } catch { print(error) }
        }
    }
}

struct MyStatsView: View {
    let mockService = MockSessionService()
    @State private var stats: (totalDistance: Double, averagePace: Int, sessionsCount: Int)? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let stats = stats {
                    AppCard {
                        HStack {
                            StatChip(title: "Total Distance", value: String(format: "%.1f km", stats.totalDistance))
                            StatChip(title: "Avg Pace", value: "\(stats.averagePace / 60):\(String(format: "%02d", stats.averagePace % 60)) /km")
                        }
                        StatChip(title: "Total Sessions", value: "\(stats.sessionsCount)")
                    }
                    
                    AppCard {
                        Text("Weekly Progression")
                            .font(AppTheme.Fonts.subheadline)
                        // Mock Chart Placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .overlay(Text("Chart Placeholder"))
                    }
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
        .task {
            do {
                self.stats = try await mockService.getMyStats()
            } catch { print(error) }
        }
    }
}
