import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var query = ""
    @Published var friends: [User] = [
        User(id: "1", name: "Alex", level: 5),
        User(id: "2", name: "Jordan", level: 3),
        User(id: "3", name: "Sam", level: 9)
    ]
}

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        ScreenContainer(title: "Friends") {
            VStack {
                TextField("Search friends...", text: $viewModel.query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Online & Available")
                            .font(AppTheme.Fonts.subheadline)
                        
                        ForEach(viewModel.friends) { friend in
                            HStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .overlay(Text(String(friend.name.prefix(1))).bold())
                                
                                VStack(alignment: .leading) {
                                    Text(friend.name)
                                        .font(AppTheme.Fonts.subheadline)
                                    Text("Lvl \(friend.level) Runner")
                                        .font(AppTheme.Fonts.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Invite")
                                        .font(AppTheme.Fonts.caption)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.surface)
                                        .cornerRadius(8)
                                        .foregroundColor(AppTheme.primary)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
