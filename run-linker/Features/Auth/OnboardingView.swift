import SwiftUI

struct OnboardingStep {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
    let primaryColor: Color
    let secondaryColor: Color
}

struct OnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var currentStep = 0
    
    let steps = [
        OnboardingStep(
            title: "onboarding.step1.title",
            description: "onboarding.step1.description",
            icon: "figure.run",
            primaryColor: AppTheme.primary,
            secondaryColor: Color(hex: "#0051DF")
        ),
        OnboardingStep(
            title: "onboarding.step2.title",
            description: "onboarding.step2.description",
            icon: "person.2.fill",
            primaryColor: Color(hex: "#476800"),
            secondaryColor: AppTheme.secondaryContainer
        ),
        OnboardingStep(
            title: "onboarding.step3.title",
            description: "onboarding.step3.description",
            icon: "chart.line.uptrend.xyaxis",
            primaryColor: AppTheme.tertiary,
            secondaryColor: AppTheme.primary
        )
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ─── Header ───
                HStack {
                    Text("RunLinker")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(AppTheme.primary)
                    Spacer()
                    Button {
                        authVM.completeOnboarding()
                    } label: {
                        Text("onboarding.skip")
                            .font(AppTheme.Fonts.label)
                            .foregroundColor(AppTheme.textTertiary)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.surfaceContainer.opacity(0.6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.top, AppTheme.Spacing.lg)
                
                Spacer()
                
                // ─── Visual Hero ───
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    steps[currentStep].primaryColor.opacity(0.15),
                                    steps[currentStep].primaryColor.opacity(0.03),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(y: -20)
                    
                    // Hero Card
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xxl)
                        .fill(AppTheme.surfaceContainerLowest)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xxl)
                                .stroke(AppTheme.outlineVariant.opacity(0.15), lineWidth: 1)
                        )
                        .overlay(
                            VStack(spacing: AppTheme.Spacing.lg) {
                                ZStack {
                                    Circle()
                                        .fill(steps[currentStep].primaryColor.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: steps[currentStep].icon)
                                        .font(.system(size: 48, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [steps[currentStep].primaryColor, steps[currentStep].secondaryColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                Text("RunLinker")
                                    .font(AppTheme.Fonts.caption)
                                    .foregroundColor(AppTheme.textTertiary)
                                    .tracking(2)
                                    .textCase(.uppercase)
                            }
                        )
                        .padding(.horizontal, 48)
                }
                .frame(maxHeight: .infinity)
                
                // ─── Content Cluster ───
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text(steps[currentStep].title)
                            .font(.system(size: 30, weight: .heavy))
                            .foregroundColor(AppTheme.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                        
                        Text(steps[currentStep].description)
                            .font(AppTheme.Fonts.bodySmall)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineSpacing(5)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                    
                    VStack(spacing: AppTheme.Spacing.xxl) {
                        // Dot Indicators
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(steps.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentStep ? steps[index].primaryColor : AppTheme.outlineVariant.opacity(0.4))
                                    .frame(width: index == currentStep ? 32 : 8, height: 8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
                            }
                            Spacer()
                        }
                        
                        // CTA Button
                        Button(action: {
                            if currentStep < steps.count - 1 {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    currentStep += 1
                                }
                            } else {
                                authVM.completeOnboarding()
                            }
                        }) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                if currentStep < steps.count - 1 {
                                    Text("onboarding.next")
                                        .font(AppTheme.Fonts.subheadline)
                                } else {
                                    Text("onboarding.start")
                                        .font(AppTheme.Fonts.subheadline)
                                }
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [steps[currentStep].primaryColor, steps[currentStep].secondaryColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
                            .shadow(
                                color: steps[currentStep].primaryColor.opacity(0.3),
                                radius: 12, y: 6
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xxxl)
                .padding(.bottom, 44)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 && currentStep < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.35)) { currentStep += 1 }
                    } else if value.translation.width > 50 && currentStep > 0 {
                        withAnimation(.easeInOut(duration: 0.35)) { currentStep -= 1 }
                    }
                }
        )
    }
}
