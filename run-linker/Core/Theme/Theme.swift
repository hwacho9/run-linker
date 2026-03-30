import SwiftUI

struct AppTheme {
    // Primary brand colors from Stitch reference
    static let primary = Color.blue
    static let secondary = Color.green
    
    // Layout semantic colors
    static let background = Color(UIColor.systemBackground)
    static let surface = Color(UIColor.secondarySystemBackground)
    static let cardBackground = Color(UIColor.tertiarySystemBackground)
    
    // Typography
    static let text = Color.primary
    static let textSecondary = Color.secondary
    
    struct Fonts {
        static let heading = Font.system(.title, design: .rounded).weight(.bold)
        static let subheadline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default).weight(.medium)
        static let bigNumber = Font.system(size: 48, weight: .black, design: .rounded)
    }
}
