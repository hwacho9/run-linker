import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.hasSeenOnboarding {
                OnboardingView()
            } else if !authVM.isAuthenticated {
                Group {
                    if authVM.showSignUp {
                        SignUpView()
                    } else {
                        LoginView()
                    }
                }
                .transition(.opacity)
            } else {
                TabView {
                    HomeView()
                        .tabItem { Label("tab.home", systemImage: "house.fill") }
                    ActivityView()
                        .tabItem { Label("tab.activity", systemImage: "chart.bar.fill") }
                    FriendsView()
                        .tabItem { Label("tab.friends", systemImage: "person.2.fill") }
                    MyView()
                        .tabItem { Label("tab.my", systemImage: "person.crop.circle.fill") }
                }
                .tint(AppTheme.primary)
            }
        }
    }
}
