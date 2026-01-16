import SwiftUI

// MARK: - Unwire Design System (Duolingo-Inspired)
// Playful, bold, rewarding - productivity should feel alive!

// MARK: - Theme Manager
enum UnwireColorScheme: String, CaseIterable {
    case light
    case dark
    case system
}

class ThemeManager: ObservableObject {
    @AppStorage("unwireTheme") var selectedTheme: UnwireColorScheme = .system

    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Color Extensions
extension Color {
    // MARK: Primary Brand Colors (Lime Green)
    static let uwPrimary = Color(hex: "b5fc4f")              // Lime green - primary buttons
    static let uwPrimaryDark = Color(hex: "8BC93D")          // Darker lime for shadows/pressed
    static let uwPrimaryLight = Color(hex: "b5fc4f")         // Lighter lime for highlights

    // MARK: Accent Colors (Golden Yellow)
    static let uwAccent = Color(hex: "FEC80B")               // Golden yellow - progress, achievements
    static let uwAccentDark = Color(hex: "D9A800")           // Darker yellow for shadows

    // MARK: Semantic Colors (High Saturation)
    static let uwSuccess = Color(hex: "58CC02")              // Task completions, celebrations
    static let uwWarning = Color(hex: "FF9600")              // Active sessions, timers
    static let uwError = Color(hex: "FF4B4B")                // Destructive actions, blocks
    static let uwPurple = Color(hex: "CE82FF")               // Special features, premium

    // MARK: Theme-Aware Background Colors (Dark Green Style)
    // Dark mode: Deep dark green/black backgrounds
    // Light mode: Warm off-white backgrounds

    /// Main background - darkest layer
    static var uwBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "191a15")  // Deep dark green/black
                : UIColor(hex: "FAFAF7")  // Warm off-white
        })
    }

    /// Surface - slightly elevated from background
    static var uwSurface: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "23251E")  // Slightly lighter dark green
                : UIColor(hex: "FFFFFF")  // Pure white
        })
    }

    /// Card background - for elevated cards
    static var uwCard: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "2D3028")  // Lighter card surface with green tint
                : UIColor(hex: "FFFFFF")  // White cards
        })
    }

    /// Card shadow color - solid, no blur
    static var uwCardShadow: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "0F100D")  // Very dark shadow
                : UIColor(hex: "E0E0DD")  // Warm gray shadow
        })
    }

    // MARK: Theme-Aware Text Colors
    static var uwTextPrimary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "FFFFFF")  // Pure white
                : UIColor(hex: "1C1C1E")  // Near black
        })
    }

    static var uwTextSecondary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "9CA39B")  // Muted green-gray
                : UIColor(hex: "6E6E73")  // Medium gray
        })
    }

    static var uwTextTertiary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "6B7168")  // Darker muted green
                : UIColor(hex: "AEAEB2")  // Light gray
        })
    }

    // MARK: Legacy Aliases (for backwards compatibility)
    static let brandPrimary = uwPrimary
    static let brandPrimaryDark = uwPrimaryDark
    static let brandPrimaryLight = uwPrimaryLight
    static let accentGreen = uwSuccess
    static let accentOrange = uwWarning
    static let accentYellow = uwAccent
    static let accentRed = uwError
    static let accentPurple = uwPurple
    static let accentBlue = Color(hex: "1CB0F6")

    static var appBackground: Color { uwBackground }
    static var appSurface: Color { uwSurface }
    static var appCard: Color { uwCard }
    static var textPrimary: Color { uwTextPrimary }
    static var textSecondary: Color { uwTextSecondary }
    static var textTertiary: Color { uwTextTertiary }

    // Functional color aliases
    static let successColor = uwSuccess
    static let warningColor = uwWarning
    static let errorColor = uwError
    static let activeState = uwPrimary
    static let completedState = uwSuccess
    static let blockedState = uwError

    // Progress colors
    static let progressBackground = Color.white.opacity(0.2)
    static let progressFill = uwAccent
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns a darker version of this color (for solid cartoony shadows)
    func darker(by amount: Double = 0.2) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: max(Double(b) - amount, 0), opacity: Double(a))
    }

    /// Returns a lighter version of this color
    func lighter(by amount: Double = 0.2) -> Color {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: min(Double(b) + amount, 1), opacity: Double(a))
    }
}

// MARK: - Animation Presets
enum DuoAnimation {
    /// Quick button press - snappy feedback (0.2s)
    static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)

    /// Card appearance - bouncy entrance (0.3s)
    static let cardBounce = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Tab switch - smooth but lively (0.25s)
    static let tabSwitch = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Progress bar updates - smooth fill (0.4s)
    static let progressUpdate = Animation.spring(response: 0.4, dampingFraction: 0.8)

    /// Celebration/success - extra bouncy! (0.4s)
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.5)

    /// Checkbox pop - satisfying completion (0.25s)
    static let checkboxPop = Animation.spring(response: 0.25, dampingFraction: 0.5)

    /// Default spring for general use
    static let defaultSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Staggered list item animation
    static func staggered(index: Int, delay: Double = 0.05) -> Animation {
        Animation.spring(response: 0.3, dampingFraction: 0.7)
            .delay(Double(index) * delay)
    }
}

// MARK: - Haptic Feedback
enum DuoHaptics {
    static func buttonTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - The Signature Duolingo Button Style
/// 3D button with solid shadow that presses down - THE most important visual element
/// No blur shadows, no opacity tricks - just solid colors for that cartoony look
struct Duo3DButtonStyle: ButtonStyle {
    let color: Color
    let shadowColor: Color
    var cornerRadius: CGFloat = 12  // Less rounded
    var shadowOffset: CGFloat = 5
    var buttonHeight: CGFloat = 48  // Thinner button

    init(color: Color = .uwPrimary, shadowColor: Color? = nil) {
        self.color = color
        // Use a proper darker shade, not opacity
        self.shadowColor = shadowColor ?? color.darker(by: 0.25)
    }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let pressOffset: CGFloat = isPressed ? shadowOffset : 0

        ZStack(alignment: .top) {
            // Shadow layer - stays in place, solid color
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(shadowColor)
                .frame(minHeight: buttonHeight)
                .offset(y: shadowOffset)

            // Main button layer - moves down on press to meet shadow
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(color)
                .frame(minHeight: buttonHeight)
                .offset(y: pressOffset)
                .overlay(
                    configuration.label
                        .font(.custom("DINNextRoundedLTW01-Bold", size: 17))
                        .foregroundColor(.black)  // Black text on lime green
                        .offset(y: pressOffset)
                )
        }
        .frame(minHeight: buttonHeight + shadowOffset)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .onChange(of: isPressed) { _, pressed in
            if pressed { DuoHaptics.lightTap() }
        }
    }
}

// MARK: - Button Style Variants
struct DuoPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwPrimary, shadowColor: .uwPrimaryDark)
            .makeBody(configuration: configuration)
    }
}

struct DuoSuccessButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwSuccess, shadowColor: Color(hex: "3D9001"))
            .makeBody(configuration: configuration)
    }
}

struct DuoWarningButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwWarning, shadowColor: Color(hex: "CC7700"))
            .makeBody(configuration: configuration)
    }
}

struct DuoDangerButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwError, shadowColor: Color(hex: "CC3333"))
            .makeBody(configuration: configuration)
    }
}

struct DuoAccentButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwAccent, shadowColor: .uwAccentDark)
            .makeBody(configuration: configuration)
    }
}

// MARK: - Secondary Button (Outline style)
struct DuoSecondaryButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.uwTextPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.uwCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.uwTextTertiary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DuoAnimation.buttonPress, value: configuration.isPressed)
    }
}

// MARK: - Duolingo-Style Card Modifier
extension View {
    /// Info card with border - NO shadow (for non-interactive content)
    /// Use this for progress displays, stats, info cards that aren't clickable
    func duoCard(padding: CGFloat = 20, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.uwCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.uwCardShadow.opacity(0.3), lineWidth: 2)
                    )
            )
    }

    /// Interactive card with 3D shadow - ONLY for clickable cards
    func duoInteractiveCard(padding: CGFloat = 20, cornerRadius: CGFloat = 12, shadowOffset: CGFloat = 4) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    // Solid shadow layer - only on interactive elements
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: shadowOffset)

                    // Main card
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                }
            )
    }

    /// 3D card with visible shadow - for prominent buttons/interactive elements
    func duo3DCard(padding: CGFloat = 20, cornerRadius: CGFloat = 12, shadowOffset: CGFloat = 4) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    // Solid shadow layer
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: shadowOffset)

                    // Main card
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                }
            )
    }

    /// Input field with 3D shadow - for text fields, etc.
    func duoInputShadow(cornerRadius: CGFloat = 12, shadowOffset: CGFloat = 3) -> some View {
        self
            .background(
                ZStack {
                    // Solid shadow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: shadowOffset)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                }
            )
    }

    /// Legacy aliases for backwards compatibility
    func glassCard(padding: CGFloat = 20, cornerRadius: CGFloat = 16) -> some View {
        duoCard(padding: padding, cornerRadius: cornerRadius)
    }

    func glassCardMinimal(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        duoCard(padding: padding, cornerRadius: cornerRadius)
    }

    func modernCard(padding: CGFloat = 20) -> some View {
        duoCard(padding: padding)
    }
}

// MARK: - Interactive Card Button Style
struct DuoCardButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 12  // Less rounded
    var shadowOffset: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let pressOffset: CGFloat = isPressed ? shadowOffset : 0

        configuration.label
            .background(
                ZStack {
                    // Solid shadow layer - stays in place
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: shadowOffset)

                    // Main card - moves down on press
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                        .offset(y: pressOffset)
                }
            )
            .offset(y: pressOffset)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Pill Button Style (for tab bars, segmented controls)
struct DuoPillButtonStyle: ButtonStyle {
    let isSelected: Bool
    var tint: Color = .uwPrimary
    var shadowOffset: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let pressOffset: CGFloat = isPressed ? shadowOffset : 0

        configuration.label
            .font(.custom("DINNextRoundedLTW01-Bold", size: 15))
            .foregroundColor(isSelected ? .black : .uwTextPrimary)  // Black text on lime green
            .padding(.horizontal, 20)
            .padding(.vertical, 10)  // Thinner padding
            .background(
                ZStack {
                    if isSelected {
                        // Solid shadow for selected state - darker shade, no opacity
                        Capsule()
                            .fill(tint.darker(by: 0.25))
                            .offset(y: shadowOffset)

                        // Main pill - moves down on press
                        Capsule()
                            .fill(tint)
                            .offset(y: pressOffset)
                    } else {
                        // Unselected: subtle 3D effect
                        Capsule()
                            .fill(Color.uwCardShadow)
                            .offset(y: 2)

                        Capsule()
                            .fill(Color.uwCard)
                    }
                }
            )
            .offset(y: isSelected ? pressOffset : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

// MARK: - Progress Bar Component (Flat - No Shadow)
// Progress bars are NOT clickable, so they should be flat per Duolingo principle
struct DuoProgressBar: View {
    let progress: Double
    var height: CGFloat = 12
    var backgroundColor: Color = .uwCardShadow
    var fillColor: Color = .uwAccent
    var cornerRadius: CGFloat? = nil

    var body: some View {
        let radius = cornerRadius ?? height / 2

        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track background - flat, no shadow
                RoundedRectangle(cornerRadius: radius)
                    .fill(backgroundColor)

                // Fill bar - flat, no shadow since it's not interactive
                if progress > 0 {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(fillColor)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1), height: height)
                        .animation(DuoAnimation.progressUpdate, value: progress)
                }
            }
        }
        .frame(height: height) // No extra height for shadow
    }
}

// MARK: - Checkbox Component (Duolingo 3D Style)
struct DuoCheckbox: View {
    let isChecked: Bool
    let onToggle: () -> Void
    var size: CGFloat = 32

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            withAnimation(DuoAnimation.checkboxPop) {
                scale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DuoAnimation.checkboxPop) {
                    scale = 1.0
                }
            }
            DuoHaptics.success()
            onToggle()
        }) {
            ZStack {
                if isChecked {
                    // Solid shadow - darker shade of primary color
                    Circle()
                        .fill(Color.uwPrimaryDark)
                        .frame(width: size, height: size)
                        .offset(y: 3)

                    // Main circle - checked
                    Circle()
                        .fill(Color.uwPrimary)
                        .frame(width: size, height: size)

                    // Checkmark - black on lime green
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundColor(.black)
                } else {
                    // Unchecked: card shadow
                    Circle()
                        .fill(Color.uwCardShadow)
                        .frame(width: size, height: size)
                        .offset(y: 2)

                    // Main circle - unchecked
                    Circle()
                        .fill(Color.uwCard)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(Color.uwTextTertiary, lineWidth: 2)
                        )
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Typography Extensions (DIN Next Rounded)
extension Font {
    // DIN Next Rounded typography - bold, clean, modern
    static let duoTitle = Font.custom("DINNextRoundedLTW01-Bold", size: 32)
    static let duoHeadline = Font.custom("DINNextRoundedLTW01-Bold", size: 24)
    static let duoSubheadline = Font.custom("DINNextRoundedLTW01-Bold", size: 18)
    static let duoBody = Font.custom("DINNextRoundedLTW01-Medium", size: 17)
    static let duoBodyBold = Font.custom("DINNextRoundedLTW01-Bold", size: 17)
    static let duoButton = Font.custom("DINNextRoundedLTW01-Bold", size: 17)
    static let duoCaption = Font.custom("DINNextRoundedLTW01-Medium", size: 13)
    static let duoCaptionBold = Font.custom("DINNextRoundedLTW01-Bold", size: 13)
    static let duoSmall = Font.custom("DINNextRoundedLTW01-Light", size: 13)
}

// MARK: - Legacy Compatibility Types
enum ModernButtonStyle {
    case primary
    case secondary
    case success
    case warning
    case danger

    var backgroundColor: Color {
        switch self {
        case .primary: return .uwPrimary
        case .secondary: return .uwCard
        case .success: return .uwSuccess
        case .warning: return .uwWarning
        case .danger: return .uwError
        }
    }

    var foregroundColor: Color {
        switch self {
        case .secondary: return .uwTextPrimary
        default: return .white
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return .uwPrimaryDark
        case .success: return Color(hex: "3D9001")
        case .warning: return Color(hex: "CC7700")
        case .danger: return Color(hex: "CC3333")
        case .secondary: return Color.black.opacity(0.2)
        }
    }
}

// Legacy button style
struct DuolingoButton: ButtonStyle {
    let color: Color

    init(color: Color = .uwPrimary) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: color)
            .makeBody(configuration: configuration)
    }
}

// Legacy pill button
struct GlassPillButton: ButtonStyle {
    let isSelected: Bool
    let tint: Color

    init(isSelected: Bool = false, tint: Color = .uwPrimary) {
        self.isSelected = isSelected
        self.tint = tint
    }

    func makeBody(configuration: Configuration) -> some View {
        DuoPillButtonStyle(isSelected: isSelected, tint: tint)
            .makeBody(configuration: configuration)
    }
}

// Legacy card button
struct GlassCardButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        DuoCardButtonStyle()
            .makeBody(configuration: configuration)
    }
}

// MARK: - Glass Effect Compatibility (redirects to solid cards)
struct MainAppGlassEffect<S: InsettableShape>: ViewModifier {
    var shape: S
    var tintColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Solid shadow - no blur
                    shape
                        .fill(Color.uwCardShadow)
                        .offset(y: 4)

                    shape
                        .fill(Color.uwCard)
                }
            )
    }
}

// MARK: - Glass Container Compatibility
struct GlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat = 12, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        content()
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
