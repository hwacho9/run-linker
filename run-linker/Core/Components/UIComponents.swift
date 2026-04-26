import SwiftUI
import AuthenticationServices

// MARK: - Screen Container
public struct ScreenContainer<Content: View>: View {
    public var title: LocalizedStringKey?
    public let content: Content

    public init(title: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(AppTheme.Fonts.heading)
                        .foregroundColor(AppTheme.text)
                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.xxl)
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.sm)
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Top App Bar (Stitch: header with logo + icon buttons)
public struct TopAppBar: View {
    public var body: some View {
        HStack {
            Text("RunLinker")
                .font(AppTheme.Fonts.heading)
                .foregroundColor(AppTheme.primary)
                .tracking(-1)
            Spacer()
            HStack(spacing: AppTheme.Spacing.xs) {
                IconButton(icon: "bell", action: {})
                IconButton(icon: "gearshape", action: {})
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(height: 64)
        .background(AppTheme.background)
    }
}

// MARK: - Icon Button (Stitch: w-10 h-10 rounded-full hover:bg-surface-container-high)
public struct IconButton: View {
    public let icon: String
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 40, height: 40)
                .background(AppTheme.surfaceContainerHigh.opacity(0.01))
                .clipShape(Circle())
        }
    }
}

// MARK: - Hero CTA Card (Stitch: kinetic-gradient bg, Lime button)
public struct HeroCTACard: View {
    public let title: LocalizedStringKey
    public let buttonTitle: LocalizedStringKey
    public let buttonIcon: String
    public let action: () -> Void
    
    public init(title: LocalizedStringKey = "home.hero.title",
                buttonTitle: LocalizedStringKey = "home.hero.button",
                buttonIcon: String = "bolt.fill",
                action: @escaping () -> Void) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.buttonIcon = buttonIcon
        self.action = action
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxl) {
                Text(title)
                    .font(AppTheme.Fonts.heading)
                    .foregroundColor(.white)
                    .lineSpacing(4)
                
                Button(action: action) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(buttonTitle)
                            .font(AppTheme.Fonts.subheadline)
                        Image(systemName: buttonIcon)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(AppTheme.onSecondaryContainer)
                    .padding(.vertical, AppTheme.Spacing.lg)
                    .padding(.horizontal, AppTheme.Spacing.xxxl)
                    .background(AppTheme.secondaryContainer)
                    .clipShape(Capsule())
                }
            }
            .padding(AppTheme.Spacing.xxxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Decorative runner icon (Stitch: directions_run 180px, opacity-20, rotated)
            Image(systemName: "figure.run")
                .font(.system(size: 120, weight: .bold))
                .foregroundColor(.white.opacity(0.15))
                .rotationEffect(.degrees(12))
                .offset(x: 16, y: 16)
        }
        .background(AppTheme.kineticGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

// MARK: - Quick Action Button (Stitch: bg-surface-container-low, rounded-lg, py-4)
public struct QuickActionButton: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primary)
                Text(title)
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.onPrimaryFixed)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(AppTheme.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.lg))
        }
    }
}

// MARK: - Primary Button (Stitch: gradient bg, rounded-full, h-56px, shadow)
public struct PrimaryButton: View {
    public let title: LocalizedStringKey
    public let icon: String?
    public let isLoading: Bool
    public let action: () -> Void
    
    public init(title: LocalizedStringKey, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(AppTheme.Fonts.subheadline)
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.primaryGradient)
            .clipShape(Capsule())
            .shadow(color: AppTheme.primary.opacity(0.2), radius: 12, y: 6)
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button (Stitch: Lime bg, rounded-full)
public struct SecondaryButton: View {
    public let title: LocalizedStringKey
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Fonts.subheadline)
                .foregroundColor(AppTheme.onSecondaryContainer)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppTheme.secondaryContainer)
                .clipShape(Capsule())
        }
    }
}

// MARK: - App Card (Stitch: bg-surface-container-low, rounded-xl, p-6, NO shadow)
public struct AppCard<Content: View>: View {
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            content
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

// MARK: - Stat Chip (Stitch: icon + label + value, h-32 (128px), rounded-xl)
// Two variants: neutral (surface-container-highest) and accent (secondary-fixed)
public struct StatChip: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let variant: StatChipVariant
    
    public enum StatChipVariant {
        case neutral   // bg: surface-container-highest
        case accent    // bg: secondary-fixed (lime)
    }
    
    public init(title: String, value: String, icon: String? = nil, variant: StatChipVariant = .neutral) {
        self.title = title
        self.value = value
        self.icon = icon
        self.variant = variant
    }
    
    private var bgColor: Color {
        variant == .accent ? AppTheme.secondaryFixed : AppTheme.surfaceContainerHighest
    }
    
    private var titleColor: Color {
        variant == .accent ? AppTheme.onSecondaryFixedVariant : AppTheme.textTertiary
    }
    
    private var valueColor: Color {
        variant == .accent ? AppTheme.onSecondaryFixed : AppTheme.onPrimaryFixed
    }
    
    private var iconColor: Color {
        variant == .accent ? AppTheme.onSecondaryFixed : AppTheme.primary
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(LocalizedStringKey(title))
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(titleColor)
                    .tracking(0.8)
                    .textCase(.uppercase)
                Text(value)
                    .font(AppTheme.Fonts.metricMedium)
                    .foregroundColor(valueColor)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 128)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}

// MARK: - Section Header (Stitch: font-headline font-bold text-xl, optional trailing button)
public struct SectionHeader: View {
    public let title: LocalizedStringKey
    public let trailing: LocalizedStringKey?
    public let action: (() -> Void)?
    
    public init(_ title: LocalizedStringKey, trailing: LocalizedStringKey? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.trailing = trailing
        self.action = action
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(AppTheme.Fonts.headingSmall)
                .foregroundColor(AppTheme.text)
            Spacer()
            if let trailing = trailing, let action = action {
                Button(action: action) {
                    Text(trailing)
                        .font(AppTheme.Fonts.bodyMedium)
                        .foregroundColor(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Settings Row
public struct SettingsRow: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let showChevron: Bool
    public let action: () -> Void
    
    public init(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, showChevron: Bool = true, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showChevron = showChevron
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Fonts.body)
                        .foregroundColor(AppTheme.text)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.outlineVariant)
                }
            }
            .padding(.vertical, AppTheme.Spacing.md)
        }
    }
}

// MARK: - Settings Toggle Row
public struct SettingsToggleRow: View {
    public let icon: String
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    @Binding public var isOn: Bool
    
    public init(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Fonts.body)
                    .foregroundColor(AppTheme.text)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Fonts.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(AppTheme.primary)
                .labelsHidden()
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

// MARK: - Google Sign-In Button
public struct GoogleSignInButton: View {
    let action: () -> Void
    
    public init(action: @escaping () -> Void) {
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("auth.google.continue")
                    .font(AppTheme.Fonts.subheadline)
                    .foregroundColor(AppTheme.text)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.surfaceContainerLowest)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.outlineVariant.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Apple Sign-In Button
public struct AppleSignInButton: View {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    public init(
        onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
        onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
    ) {
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        SignInWithAppleButton(.signIn, onRequest: onRequest, onCompletion: onCompletion)
            .signInWithAppleButtonStyle(.black)
            .frame(height: 56)
            .clipShape(Capsule())
    }
}

// MARK: - Divider with Text
public struct DividerWithText: View {
    let text: LocalizedStringKey
    
    public init(_ text: LocalizedStringKey) {
        self.text = text
    }
    
    public var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Rectangle()
                .fill(AppTheme.outlineVariant.opacity(0.3))
                .frame(height: 1)
            Text(text)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(AppTheme.textTertiary)
                .layoutPriority(1)
            Rectangle()
                .fill(AppTheme.outlineVariant.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Themed Text Field (Stitch: bg-surface-container, no border, on focus: primary bottom-bar)
public struct ThemedTextField: View {
    let placeholder: LocalizedStringKey
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    
    public var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
            }
        }
        .font(AppTheme.Fonts.body)
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
    }
}

// MARK: - Fitness Chip (Stitch: pill-shaped, secondary-container bg, label-md font)
public struct FitnessChip: View {
    let label: LocalizedStringKey
    let color: Color
    
    public init(_ label: LocalizedStringKey, color: Color? = nil) {
        self.label = label
        self.color = color ?? AppTheme.secondaryContainer
    }
    
    public var body: some View {
        Text(label)
            .font(AppTheme.Fonts.caption)
            .foregroundColor(AppTheme.onSecondaryContainer)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Filter Chip (Stitch: horizontal scrollable filter chips)
public struct FilterChip: View {
    let label: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void
    
    public init(_ label: LocalizedStringKey, isSelected: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTheme.Fonts.caption)
                .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(isSelected ? AppTheme.primary : AppTheme.surfaceContainerHigh)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Partner Avatar (Stitch: w-16 h-16, rounded-full, border-2 border-primary for active)
public struct PartnerAvatar: View {
    let name: String
    let isActive: Bool
    let imageUrl: String?
    
    public init(name: String, isActive: Bool = false, imageUrl: String? = nil) {
        self.name = name
        self.isActive = isActive
        self.imageUrl = imageUrl
    }
    
    public var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(isActive ? AppTheme.primary : Color.clear, lineWidth: 2)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    )
            }
            Text(name)
                .font(AppTheme.Fonts.captionSmall)
                .foregroundColor(AppTheme.text)
        }
        .opacity(isActive ? 1.0 : 0.8)
    }
}

// MARK: - Pair View Placeholder
struct PairViewPlaceholder: View {
    let users: [User]
    
    init(users: [User]) {
        self.users = users
    }
    
    public var body: some View {
        HStack(spacing: -12) {
            ForEach(users) { user in
                Circle()
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.primary)
                    )
                    .overlay(Circle().stroke(AppTheme.surfaceContainerLowest, lineWidth: 2))
            }
        }
    }
}

// MARK: - Progress Ring (Stitch: 12px stroke, gradient, round caps)
public struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    
    public init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 80) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.surfaceContainerHigh, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [AppTheme.primaryContainer, AppTheme.primary],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Sync Bar (Stitch: horizontal bar showing sync percentage)
public struct SyncBar: View {
    let score: Int // 0-100
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                Text("SYNC SCORE")
                    .font(AppTheme.Fonts.captionSmall)
                    .foregroundColor(AppTheme.textTertiary)
                    .tracking(0.8)
                Spacer()
                Text("\(score)%")
                    .font(AppTheme.Fonts.label)
                    .foregroundColor(score >= 80 ? AppTheme.secondary : AppTheme.primary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.surfaceContainerHigh)
                    Capsule()
                        .fill(score >= 80 ? AppTheme.limeGradient : AppTheme.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Glass Card (Stitch: rgba(255,255,255,0.7) + backdrop-blur(20px))
public struct GlassCard<Content: View>: View {
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            content
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
    }
}
