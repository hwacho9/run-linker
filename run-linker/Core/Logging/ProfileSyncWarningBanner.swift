import SwiftUI

#if DEBUG
struct ProfileSyncWarningBanner: View {
    let message: String
    let retryAction: () -> Void
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("프로필 저장 실패")
                        .font(AppTheme.Fonts.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(message)
                        .font(AppTheme.Fonts.captionSmall)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
                
                Spacer()
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            HStack(spacing: AppTheme.Spacing.md) {
                Button("재시도", action: retryAction)
                    .font(AppTheme.Fonts.captionSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
                
                Button("무시", action: dismissAction)
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color(hex: "#1E1E2E"))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.sm)
    }
}
#endif
