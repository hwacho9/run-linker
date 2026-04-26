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
                            Text("auth.login.title")
                                .font(AppTheme.Fonts.heading)
                                .foregroundColor(AppTheme.text)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("auth.login.subtitle")
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
                        
                        AppleSignInButton(
                            onRequest: authVM.configureAppleSignIn,
                            onCompletion: authVM.handleAppleSignInResult
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Divider ───
                    DividerWithText("auth.login.email_divider")
                        .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Email / Password Fields ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        ThemedTextField(
                            placeholder: "auth.field.email",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .none
                        )
                        
                        ThemedTextField(
                            placeholder: "auth.field.password",
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
                            title: "auth.login.button",
                            isLoading: authVM.isLoading
                        ) {
                            Task { await authVM.login(email: email, password: password) }
                        }
                        
                        Button("auth.login.forgot_password") {}
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Sign Up Link ───
                    Button {
                        authVM.errorMessage = nil
                        withAnimation(.easeInOut(duration: 0.3)) {
                            authVM.showSignUp = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("auth.login.no_account")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("auth.signup.button")
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
