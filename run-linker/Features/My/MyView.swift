import Foundation
import SwiftUI

@MainActor
class MyViewModel: ObservableObject {
    @Published var privacyEnabled = true
    @Published var notificationsEnabled = true
}

struct MyView: View {
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        ScreenContainer(title: "My Profile") {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 80, height: 80)
                            .overlay(Text("Me").font(.title.bold()).foregroundColor(.white))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Runner 104")
                                .font(AppTheme.Fonts.heading)
                            Text("Level 5 Explorer")
                                .font(AppTheme.Fonts.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // Goals
                    AppCard {
                        Text("Weekly Goals")
                            .font(AppTheme.Fonts.subheadline)
                        ProgressView("Distance: 10/20 km", value: 0.5)
                            .tint(AppTheme.primary)
                    }
                    
                    // Settings
                    VStack(spacing: 0) {
                        Toggle("Location Privacy (Random Match)", isOn: $viewModel.privacyEnabled)
                            .padding()
                            .background(AppTheme.cardBackground)
                        
                        Divider()
                        
                        Toggle("Push Notifications", isOn: $viewModel.notificationsEnabled)
                            .padding()
                            .background(AppTheme.cardBackground)
                        
                        Divider()
                        
                        Button(action: {}) {
                            HStack {
                                Text("Account Support")
                                    .foregroundColor(AppTheme.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                        }
                    }
                    .background(AppTheme.surface)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
        }
    }
}
