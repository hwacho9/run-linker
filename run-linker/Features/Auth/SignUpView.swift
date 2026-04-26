import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    
                    // ─── Brand Header ───
                    VStack(spacing: AppTheme.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.secondaryContainer.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .blur(radius: 30)
                            
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 56))
                                .foregroundStyle(AppTheme.primaryGradient)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            Text("회원가입")
                                .font(AppTheme.Fonts.heading)
                                .foregroundColor(AppTheme.text)
                            
                            Text("RunLinker에서 함께 달려보세요!\n당신의 새로운 러닝 파트너가 기다리고 있습니다.")
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
                    DividerWithText("또는 이메일로 가입")
                        .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Name / Email / Password Fields ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        ThemedTextField(
                            placeholder: "이름",
                            text: $name,
                            autocapitalization: .words
                        )
                        
                        ThemedTextField(
                            placeholder: "이메일",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .none
                        )
                        
                        ThemedTextField(
                            placeholder: "비밀번호 (6자 이상)",
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
                    
                    // ─── Sign Up Button ───
                    PrimaryButton(
                        title: "회원가입",
                        isLoading: authVM.isLoading
                    ) {
                        Task { await authVM.signUp(name: name, email: email, password: password) }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Login Link ───
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            authVM.showSignUp = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("이미 계정이 있으신가요?")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("로그인")
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
