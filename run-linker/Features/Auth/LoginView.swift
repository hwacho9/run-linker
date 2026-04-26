import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    
                    // ─── Brand Header ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Decorative gradient blob
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.08))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                            
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(AppTheme.primaryGradient)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("함께 달릴 준비가\n되셨나요?")
                                .font(AppTheme.Fonts.heading)
                                .foregroundColor(AppTheme.text)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("RunLinker에 다시 오신 것을 환영합니다.\n오늘의 페이스를 찾아보세요.")
                                .font(AppTheme.Fonts.bodySmall)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                    
                    // ─── Social Login Buttons ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        GoogleSignInButton {
                            Task { await authVM.signInWithGoogle() }
                        }
                        
                        AppleSignInButton {
                            authVM.signInWithApple()
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Divider ───
                    DividerWithText("또는 이메일로 로그인")
                        .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Email / Password Fields ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        ThemedTextField(
                            placeholder: "이메일",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .none
                        )
                        
                        ThemedTextField(
                            placeholder: "비밀번호",
                            text: $password,
                            isSecure: true
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Error Message ───
                    if let error = authVM.errorMessage {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppTheme.error)
                            Text(error)
                                .font(AppTheme.Fonts.caption)
                                .foregroundColor(AppTheme.error)
                        }
                        .padding(.horizontal, AppTheme.Spacing.xxxl)
                    }
                    
                    // ─── Login Button + Forgot Password ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        PrimaryButton(
                            title: "로그인",
                            isLoading: authVM.isLoading
                        ) {
                            Task { await authVM.login(email: email, password: password) }
                        }
                        
                        Button("비밀번호를 잊으셨나요?") {}
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Sign Up Link ───
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            authVM.showSignUp = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("아직 회원이 아니신가요?")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("회원가입")
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primary)
                        }
                        .font(AppTheme.Fonts.bodySmall)
                    }
                    .padding(.bottom, AppTheme.Spacing.xxxl)
                }
            }
        }
    }
}
