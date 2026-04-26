import SwiftUI

// MARK: - Stitch Design System: "Kinetic Connection"
// Fonts: Plus Jakarta Sans (headline), Be Vietnam Pro (body), Lexend (label)
// Colors: Electric Blue (#0051DF/#2F6BFF) + Accent Lime (#AEF51D) + Deep Navy (#0F172A)
// Elevation: Tonal Layering (no drop shadows), Ghost Borders
// Corner Radius: lg(2rem) / xl(3rem) / full(9999px)

struct AppTheme {
    // ─── Primary Brand Colors ───
    static let primary = Color(hex: "#0051DF")              // Electric Blue (main brand)
    static let primaryContainer = Color(hex: "#2F6BFF")      // Electric Blue (lighter, container)
    static let primaryFixed = Color(hex: "#DBE1FF")
    static let primaryFixedDim = Color(hex: "#B5C4FF")
    static let onPrimary = Color.white
    static let onPrimaryContainer = Color(hex: "#000318")
    static let onPrimaryFixed = Color(hex: "#00174D")        // Deep Navy text
    static let onPrimaryFixedVariant = Color(hex: "#003CAC")
    
    static let secondary = Color(hex: "#476800")             // Accent Lime (dark)
    static let secondaryContainer = Color(hex: "#AEF51D")    // Accent Lime (bright)
    static let secondaryFixed = Color(hex: "#B1F722")        // Lime for stat backgrounds
    static let secondaryFixedDim = Color(hex: "#99DA00")
    static let onSecondary = Color.white
    static let onSecondaryContainer = Color(hex: "#4A6D00")
    static let onSecondaryFixed = Color(hex: "#131F00")
    static let onSecondaryFixedVariant = Color(hex: "#354E00")
    
    static let tertiary = Color(hex: "#565E74")
    static let tertiaryContainer = Color(hex: "#6F768D")
    static let tertiaryFixed = Color(hex: "#DAE2FD")
    static let tertiaryFixedDim = Color(hex: "#BEC6E0")
    static let onTertiary = Color.white
    static let onTertiaryContainer = Color.white
    static let onTertiaryFixed = Color(hex: "#131B2E")
    static let onTertiaryFixedVariant = Color(hex: "#3F465C")
    
    // Deep Navy (anchor color)
    static let deepNavy = Color(hex: "#0F172A")
    
    // ─── Surface Hierarchy (Tonal Layering) ───
    // Base → Low → Container → High → Highest
    static let background = Color(hex: "#F6FAFF")
    static let surface = Color(hex: "#F6FAFF")
    static let surfaceBright = Color(hex: "#F6FAFF")
    static let surfaceDim = Color(hex: "#D5DBE2")
    static let surfaceContainerLowest = Color(hex: "#FFFFFF")
    static let surfaceContainerLow = Color(hex: "#EEF4FB")
    static let surfaceContainer = Color(hex: "#E8EEF5")
    static let surfaceContainerHigh = Color(hex: "#E3E9F0")
    static let surfaceContainerHighest = Color(hex: "#DDE3EA")
    static let surfaceVariant = Color(hex: "#DDE3EA")
    static let surfaceTint = Color(hex: "#0051E0")
    
    // ─── Text Colors ───
    static let text = Color(hex: "#161C21")                  // on_surface
    static let textSecondary = Color(hex: "#434655")         // on_surface_variant
    static let textTertiary = Color(hex: "#737687")          // outline
    
    // ─── Utility Colors ───
    static let outline = Color(hex: "#737687")
    static let outlineVariant = Color(hex: "#C3C5D8")
    static let error = Color(hex: "#BA1A1A")
    static let errorContainer = Color(hex: "#FFDAD6")
    static let onError = Color.white
    static let onErrorContainer = Color(hex: "#93000A")
    
    // ─── Inverse ───
    static let inverseSurface = Color(hex: "#2B3136")
    static let inverseOnSurface = Color(hex: "#EBF1F8")
    static let inversePrimary = Color(hex: "#B5C4FF")
    
    // ─── Legacy Aliases ───
    static let cardBackground = surfaceContainerLow          // Stitch uses surface-container-low for cards
    
    // ─── Gradient Helpers ───
    // Kinetic Gradient: used on Hero CTA sections
    static let kineticGradient = LinearGradient(
        colors: [Color(hex: "#0051DF"), Color(hex: "#2F6BFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Primary button gradient (convex, tactile feel)
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryContainer],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Lime gradient (for Finish Run, achievements)
    static let limeGradient = LinearGradient(
        colors: [secondaryContainer, secondaryFixedDim],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // ─── Glass Effect ───
    // For floating overlays: surface_container_lowest at 70-80% opacity + blur(20px)
    static let glassBackground = Color.white.opacity(0.7)
    static let glassBlur: CGFloat = 20
    
    // ─── Typography ───
    // Stitch: headline = Plus Jakarta Sans, body = Be Vietnam Pro, label = Lexend
    // SwiftUI fallback: .rounded for headline feel, .default for body, .monospaced for metrics
    struct Fonts {
        // ─ Display (Big Numbers, PRs) ─
        // Stitch: display-lg = 3.5rem (56pt)
        static let displayLarge = Font.custom("PlusJakartaSans-ExtraBold", size: 56)
            
        // ─ Headlines (Screen titles, Section headers) ─
        // Stitch: headline-md = 1.75rem (28pt), headline-sm = 1.5rem (24pt)
        static let heading = Font.custom("PlusJakartaSans-Bold", size: 28)
        static let headingMedium = Font.custom("PlusJakartaSans-Bold", size: 22)
        static let headingSmall = Font.custom("PlusJakartaSans-Bold", size: 20)
        
        // ─ Titles (Card headers) ─
        // Stitch: title-md = 1.125rem (18pt), title-lg = 1.25rem (20pt)
        static let titleLarge = Font.custom("PlusJakartaSans-SemiBold", size: 20)
        static let titleMedium = Font.custom("PlusJakartaSans-SemiBold", size: 18)
        
        // ─ Subheadline ─
        static let subheadline = Font.custom("PlusJakartaSans-Bold", size: 16)
        
        // ─ Body (Primary feed text) ─
        // Stitch: body-lg = 1rem (16pt), Be Vietnam Pro
        static let body = Font.custom("BeVietnamPro-Regular", size: 16)
        static let bodyMedium = Font.custom("BeVietnamPro-Medium", size: 14)
        static let bodySmall = Font.custom("BeVietnamPro-Regular", size: 14)
        
        // ─ Labels (Data points, metadata) ─
        // Stitch: label-md = 0.75rem (12pt), Lexend
        static let label = Font.custom("Lexend-Medium", size: 14)
        static let labelSmall = Font.custom("Lexend-Medium", size: 12)
        static let caption = Font.custom("Lexend-Medium", size: 12)
        static let captionSmall = Font.custom("Lexend-Medium", size: 11)
        
        // ─ Functional / Metrics (Pace, KM, BPM) ─
        // Stitch: Lexend for numerical clarity
        static let bigNumber = Font.custom("Lexend-SemiBold", size: 48)
        static let metric = Font.custom("Lexend-Bold", size: 32)
        static let metricMedium = Font.custom("Lexend-Bold", size: 24)
        static let metricSmall = Font.custom("Lexend-Bold", size: 20)
        
        // ─ Fallback versions (if custom fonts not loaded) ─
        static let headingFallback = Font.system(size: 28, weight: .bold, design: .rounded)
        static let bodyFallback = Font.system(size: 16, weight: .regular, design: .default)
        static let labelFallback = Font.system(size: 14, weight: .medium, design: .default)
    }
    
    // ─── Spacing ───
    // Stitch: uses rem-based spacing. Converted to pt for iOS.
    struct Spacing {
        static let xs: CGFloat = 4       // 0.25rem
        static let sm: CGFloat = 8       // 0.5rem
        static let md: CGFloat = 12      // 0.75rem
        static let lg: CGFloat = 16      // 1rem
        static let xl: CGFloat = 20      // 1.25rem
        static let xxl: CGFloat = 24     // 1.5rem (px-6 in Stitch)
        static let xxxl: CGFloat = 32    // 2rem
        static let xxxxl: CGFloat = 40   // 2.5rem
    }
    
    // ─── Corner Radius ───
    // Stitch: DEFAULT=1rem, lg=2rem, xl=3rem, full=9999px
    struct Radius {
        static let sm: CGFloat = 8       // 0.5rem
        static let `default`: CGFloat = 16  // 1rem (DEFAULT in Stitch)
        static let md: CGFloat = 16      // 1rem
        static let lg: CGFloat = 24      // Stitch: rounded-lg used on action buttons
        static let xl: CGFloat = 32      // Stitch: rounded-xl used on cards
        static let xxl: CGFloat = 48     // 3rem
        static let full: CGFloat = 9999  // pill shape
    }
    
    // ─── Ambient Shadow (only for floating elements) ───
    // Stitch: 32px blur, 0 offset, 6% opacity of on_surface color
    struct Shadow {
        static let ambientRadius: CGFloat = 16  // half of 32px CSS blur
        static let ambientOpacity: Double = 0.06
        static let ambientY: CGFloat = 0
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
