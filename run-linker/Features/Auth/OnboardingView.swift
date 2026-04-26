import SwiftUI

struct OnboardingStep {
    let title: String
    let description: String
    let icon: String
    let primaryColor: Color
    let secondaryColor: Color
}

struct OnboardingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var currentStep = 0
    
    let steps = [
        OnboardingStep(
            title: "멀리 있어도\n함께 달리는 우리",
            description: "실시간 위치 동기화로 친구의 페이스를 느끼며 전 세계 어디서든 함께 뛰는 즐거움을 경험하세요.",
            icon: "figure.run",
            primaryColor: AppTheme.primary,
            secondaryColor: Color(hex: "#0051DF")
        ),
        OnboardingStep(
            title: "랜덤 매칭으로\n새로운 자극",
            description: "프라이버시가 보호되는 랜덤 매칭으로 나와 비슷한 페이스의 러너와 새로운 달리기 경험을 즐겨보세요.",
            icon: "person.2.fill",
            primaryColor: Color(hex: "#476800"),
            secondaryColor: AppTheme.secondaryContainer
        ),
        OnboardingStep(
            title: "목표를 향한\n작은 성취",
            description: "개인화된 대시보드를 통해 나만의 성장 기록을 확인하고 즐거운 러닝 라이프를 설계하세요.",
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
                        Text("건너뛰기")
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
                                Text(currentStep < steps.count - 1 ? "다음 단계로" : "시작하기")
                                    .font(AppTheme.Fonts.subheadline)
                                    .fontWeight(.bold)
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
