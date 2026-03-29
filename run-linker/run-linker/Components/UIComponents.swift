import SwiftUI

struct ScreenContainer<Content: View>: View {
    var title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                    Spacer()
                }
                .padding()
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.primary)
                .cornerRadius(12)
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(AppTheme.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

struct StatChip: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)
            Text(value)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(AppTheme.text)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.background)
        .cornerRadius(8)
    }
}

struct PairViewPlaceholder: View {
    let users: [User]
    
    var body: some View {
        HStack(spacing: -10) {
            ForEach(users) { user in
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(Text(String(user.name.prefix(1))).font(.title3.bold()))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }
}
