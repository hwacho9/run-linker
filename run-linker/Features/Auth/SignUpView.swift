import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
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
                            Text("auth.signup.title")
                                .font(AppTheme.Fonts.heading)
                                .foregroundColor(AppTheme.text)
                            
                            Text("auth.signup.subtitle")
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
                    DividerWithText("auth.signup.email_divider")
                        .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Name / Email / Password Fields ───
                    VStack(spacing: AppTheme.Spacing.md) {
                        ThemedTextField(
                            placeholder: "auth.field.name",
                            text: $name,
                            autocapitalization: .words
                        )
                        
                        ThemedTextField(
                            placeholder: "auth.field.email",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .none
                        )
                        
                        ThemedTextField(
                            placeholder: "auth.field.password_min",
                            text: $password,
                            isSecure: true
                        )
                        
                        ThemedTextField(
                            placeholder: "auth.field.confirm_password",
                            text: $confirmPassword,
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
                        title: "auth.signup.button",
                        isLoading: authVM.isLoading
                    ) {
                        RunLinkerLogger.info("Sign-up button tapped.")
                        Task {
                            await authVM.signUp(
                                name: name,
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    
                    // ─── Login Link ───
                    Button {
                        authVM.errorMessage = nil
                        withAnimation(.easeInOut(duration: 0.3)) {
                            authVM.showSignUp = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("auth.signup.has_account")
                                .foregroundColor(AppTheme.textSecondary)
                            Text("auth.login.button")
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
