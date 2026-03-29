import SwiftUI

struct HomeView: View {
    let mockService = MockSessionService()
    @State private var recentSessions: [RunSession] = []
    @State private var totalDistance: Double = 0.0
    
    var body: some View {
        ScreenContainer(title: "Home") {
            ScrollView {
                VStack(spacing: 24) {
                    // MAIN CTA
                    AppCard {
                        VStack(spacing: 16) {
                            Text("Ready for a run?")
                                .font(AppTheme.Fonts.heading)
                            
                            PrimaryButton(title: "Start Running") {
                                // Navigate to match setup or solo run
                                print("Start Run Tapped")
                            }
                            
                            HStack {
                                Button("Run with Friend") {}
                                    .font(AppTheme.Fonts.caption)
                                    .padding(.horizontal)
                                Spacer()
                                Button("Random Match") {}
                                    .font(AppTheme.Fonts.caption)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Summary View
                    AppCard {
                        Text("This Week")
                            .font(AppTheme.Fonts.subheadline)
                        
                        HStack {
                            StatChip(title: "Distance", value: String(format: "%.1f km", totalDistance))
                            StatChip(title: "Runs", value: "\(recentSessions.count)")
                        }
                    }
                    
                    // Recent Activity
                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Recent Runs")
                                .font(AppTheme.Fonts.subheadline)
                                .padding(.horizontal)
                            
                            ForEach(recentSessions) { session in
                                AppCard {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(session.mode.rawValue.capitalized + " Run")
                                                .font(.headline)
                                            Text("\(session.distance, specifier: "%.1f") km - \(session.durationFormatted)")
                                                .font(AppTheme.Fonts.caption)
                                        }
                                        Spacer()
                                        if session.mode != .solo {
                                            PairViewPlaceholder(users: session.participants)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .task {
            loadMockData()
        }
    }
    
    private func loadMockData() {
        Task {
            do {
                self.recentSessions = try await mockService.getSessionHistory()
                let stats = try await mockService.getMyStats()
                self.totalDistance = stats.totalDistance
            } catch {
                print(error)
            }
        }
    }
}
