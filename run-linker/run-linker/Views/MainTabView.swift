import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "figure.run")
                }
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: "chart.bar.fill")
                }
            
            FriendsView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
            
            MyView()
                .tabItem {
                    Label("My", systemImage: "person.crop.circle.fill")
                }
        }
    }
}
