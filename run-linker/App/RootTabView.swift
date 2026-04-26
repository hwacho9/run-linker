import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.hasSeenOnboarding {
                OnboardingView()
            } else if !authVM.isAuthenticated {
                LoginView()
            } else {
                TabView {
                    HomeView()
                        .tabItem { Label("홈", systemImage: "house.fill") }
                    ActivityView()
                        .tabItem { Label("기록", systemImage: "chart.bar.fill") }
                    FriendsView()
                        .tabItem { Label("친구", systemImage: "person.2.fill") }
                    MyView()
                        .tabItem { Label("마이", systemImage: "person.crop.circle.fill") }
                }
                .tint(AppTheme.primary)
            }
        }
    }
}
