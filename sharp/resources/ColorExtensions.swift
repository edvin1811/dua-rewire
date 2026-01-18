import SwiftUI

// MARK: - Unwire Design System
// Clean, branded, focused - two-color system for cohesive design

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
    // MARK: - Duolingo Brand Colors (Exact Values from Guidelines)
    // Feather Green: #58CC02 - Primary CTAs, success states
    // Macaw Blue: #1CB0F6 - Secondary actions, information
    // Cardinal Red: #FF4B4B - Errors, hearts, wrong answers
    // Bee Yellow: #FFC800 - Highlights, streaks, rewards
    // Fox Orange: #FF9600 - Achievements, energy
    // Eel Dark: #4B4B4B - Primary text
    // Snow White: #FFFFFF - Backgrounds

    // MARK: Primary Brand Color (Macaw Blue)
    static let uwPrimary = Color(hex: "1CB0F6")              // Macaw Blue - secondary actions
    static let uwPrimaryDark = Color(hex: "1899D6")          // Darker blue for shadows
    static let uwPrimaryLight = Color(hex: "7ED4FC")         // Lighter blue for highlights

    // MARK: Success/Action Color (Feather Green - THE Duolingo Button Color)
    static let uwSuccess = Color(hex: "58CC02")              // Feather Green - primary CTAs
    static let uwSuccessDark = Color(hex: "58A700")          // Darker green for 3D shadows
    static let uwSuccessLight = Color(hex: "89E219")         // Lighter green for highlights

    // MARK: Accent Color (Bee Yellow)
    static let uwAccent = Color(hex: "FFC800")               // Bee Yellow - streaks, rewards
    static let uwAccentDark = Color(hex: "E5A000")           // Darker gold for shadows
    static let uwAccentLight = Color(hex: "FFD84D")          // Lighter gold for highlights

    // MARK: Semantic Colors
    static let uwWarning = Color(hex: "FF9600")              // Fox Orange - achievements
    static let uwError = Color(hex: "FF4B4B")                // Cardinal Red - errors
    static let uwPurple = Color(hex: "CE82FF")               // Purple - premium/special

    // MARK: Theme-Aware Background Colors
    /// Main background - Snow White in light, dark charcoal in dark
    static var uwBackground: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "131F24")  // Dark charcoal
                : UIColor(hex: "FFFFFF")  // Snow White
        })
    }

    /// Surface - slightly elevated from background
    static var uwSurface: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "1A2B32")
                : UIColor(hex: "F7F7F7")
        })
    }

    /// Card background - white on light, dark surface on dark
    static var uwCard: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "1A2B32")
                : UIColor(hex: "FFFFFF")
        })
    }

    /// Card shadow color for 3D effects
    static var uwCardShadow: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "0D1518")
                : UIColor(hex: "E5E5E5")
        })
    }

    /// Border color - subtle gray
    static var uwBorder: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "2D4047")
                : UIColor(hex: "E5E5E5")
        })
    }

    // MARK: Theme-Aware Text Colors
    /// Primary text - Eel Dark (#4B4B4B) in light mode
    static var uwTextPrimary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "FFFFFF")
                : UIColor(hex: "4B4B4B")  // Eel Dark
        })
    }

    /// Secondary text - medium gray
    static var uwTextSecondary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "AFAFAF")
                : UIColor(hex: "777777")
        })
    }

    /// Tertiary text - light gray
    static var uwTextTertiary: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "6E6E6E")
                : UIColor(hex: "AFAFAF")
        })
    }

    // MARK: Legacy Aliases
    static let brandPrimary = uwPrimary
    static let brandPrimaryDark = uwPrimaryDark
    static let brandPrimaryLight = uwPrimaryLight
    static let accentGreen = uwSuccess
    static let accentOrange = uwWarning
    static let accentYellow = uwAccent
    static let accentRed = uwError
    static let accentPurple = uwPurple
    static let accentBlue = uwPrimary

    static var appBackground: Color { uwBackground }
    static var appSurface: Color { uwSurface }
    static var appCard: Color { uwCard }
    static var textPrimary: Color { uwTextPrimary }
    static var textSecondary: Color { uwTextSecondary }
    static var textTertiary: Color { uwTextTertiary }

    // Functional aliases
    static let successColor = uwSuccess
    static let warningColor = uwWarning
    static let errorColor = uwError
    static let activeState = uwSuccess
    static let completedState = uwSuccess
    static let blockedState = uwError

    // Progress colors
    static let progressBackground = Color.uwCardShadow
    static let progressFill = uwPrimary  // Use blue for progress (Duolingo style)

    // Streak/fire colors
    static let streakOrange = Color(hex: "FF9600")  // Fox Orange
    static let streakRed = Color(hex: "FF4B4B")     // Cardinal Red
}

// MARK: - Design Tokens (8-Point Grid System)
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let pill: CGFloat = 999
}

// MARK: - Typography Scale (iOS HIG)
enum Typography {
    // Large Title: 34pt Bold
    static let largeTitle: Font = .system(size: 34, weight: .bold)
    // Title 1: 28pt Bold
    static let title1: Font = .system(size: 28, weight: .bold)
    // Title 2: 22pt Bold
    static let title2: Font = .system(size: 22, weight: .bold)
    // Title 3: 20pt Semibold
    static let title3: Font = .system(size: 20, weight: .semibold)
    // Headline: 17pt Semibold
    static let headline: Font = .system(size: 17, weight: .semibold)
    // Body: 17pt Regular
    static let body: Font = .system(size: 17, weight: .regular)
    // Callout: 16pt Regular
    static let callout: Font = .system(size: 16, weight: .regular)
    // Subhead: 15pt Regular
    static let subhead: Font = .system(size: 15, weight: .regular)
    // Footnote: 13pt Regular
    static let footnote: Font = .system(size: 13, weight: .regular)
    // Caption: 12pt Regular
    static let caption: Font = .system(size: 12, weight: .regular)
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

// MARK: - Animation Presets (iOS HIG Guidelines)
// Micro-interactions: 0.1-0.15s
// Standard transitions: 0.25-0.35s
// Page transitions: 0.3-0.4s
// Maximum: 400ms (never exceed)
enum DuoAnimation {
    /// Micro: Button press feedback (0.15s) - fastest
    static let buttonPress = Animation.spring(response: 0.15, dampingFraction: 0.6)

    /// Micro: Toggle/checkbox (0.15s)
    static let microBounce = Animation.spring(response: 0.15, dampingFraction: 0.6)

    /// Standard: Card appearance (0.3s)
    static let cardBounce = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Standard: Tab switch (0.25s)
    static let tabSwitch = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Standard: Progress updates (0.35s)
    static let progressUpdate = Animation.spring(response: 0.35, dampingFraction: 0.8)

    /// Standard: Checkbox completion (0.2s)
    static let checkboxPop = Animation.spring(response: 0.2, dampingFraction: 0.5)

    /// Standard: Default spring (0.3s)
    static let defaultSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Page: Hero entrance (0.4s) - maximum allowed
    static let heroEntrance = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Page: Celebration/success (0.4s)
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.5)

    /// Standard: Reward pop (0.3s)
    static let rewardPop = Animation.spring(response: 0.3, dampingFraction: 0.4)

    /// Page: Content slide (0.35s)
    static let smoothSlide = Animation.spring(response: 0.35, dampingFraction: 0.85)

    /// Standard: Number changes (0.25s)
    static let numberPop = Animation.spring(response: 0.25, dampingFraction: 0.4)

    /// Ambient: Gentle float (slower, for decorative)
    static let gentleFloat = Animation.easeInOut(duration: 2.0)

    /// Quick: ease-out for most transitions (0.15s)
    static let quick = Animation.easeOut(duration: 0.15)

    /// Standard: ease-in-out (0.3s)
    static let standard = Animation.easeInOut(duration: 0.3)

    /// Pulse animation for attention
    static let pulse = Animation.easeInOut(duration: 0.8)

    /// Staggered list item animation
    static func staggered(index: Int, delay: Double = 0.05) -> Animation {
        Animation.spring(response: 0.3, dampingFraction: 0.7)
            .delay(Double(index) * delay)
    }

    /// Cascade animation for list reveals
    static func cascade(index: Int, baseDelay: Double = 0.1) -> Animation {
        Animation.spring(response: 0.4, dampingFraction: 0.7)
            .delay(Double(index) * baseDelay + 0.1)
    }
}

// MARK: - Pulsing Animation Modifier
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .stroke(color.opacity(isPulsing ? 0 : 0.6), lineWidth: 3)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 1)
            )
            .onAppear {
                withAnimation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let distance: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -distance : distance)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isFloating = true
                }
            }
    }
}

// MARK: - Shine Animation Modifier
struct ShineModifier: ViewModifier {
    @State private var isShining = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.4)
                    .offset(x: isShining ? geometry.size.width * 1.5 : -geometry.size.width * 0.5)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false).delay(1)) {
                            isShining = true
                        }
                    }
                }
                .mask(content)
            )
    }
}

extension View {
    func pulsing(color: Color = .uwPrimary, intensity: CGFloat = 1.0) -> some View {
        modifier(PulsingModifier(color: color, intensity: intensity))
    }

    func floating(distance: CGFloat = 5, duration: Double = 2.0) -> some View {
        modifier(FloatingModifier(distance: distance, duration: duration))
    }

    func shineEffect() -> some View {
        modifier(ShineModifier())
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

// MARK: - Duolingo Chiclet Button Style
/// 4-pixel bottom shadow that disappears on press, creating physical "push down" sensation
/// - Corner radius: 12-16pt (Duolingo style)
/// - Button height: 50pt (comfortable tapping, HIG recommendation)
/// - Shadow offset: 4pt (exact Duolingo specification)
struct Duo3DButtonStyle: ButtonStyle {
    let color: Color
    let shadowColor: Color
    let textColor: Color
    var cornerRadius: CGFloat = Radius.md  // 12pt standard
    var shadowOffset: CGFloat = 4          // Exact Duolingo spec
    var buttonHeight: CGFloat = 50         // HIG recommended height

    init(color: Color = .uwSuccess, shadowColor: Color? = nil, textColor: Color = .white) {
        self.color = color
        // Use proper dark variant for the shadow
        if color == .uwSuccess {
            self.shadowColor = shadowColor ?? .uwSuccessDark
        } else if color == .uwPrimary {
            self.shadowColor = shadowColor ?? .uwPrimaryDark
        } else if color == .uwAccent {
            self.shadowColor = shadowColor ?? .uwAccentDark
        } else {
            self.shadowColor = shadowColor ?? color.darker(by: 0.25)
        }
        self.textColor = textColor
    }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed

        ZStack(alignment: .top) {
            // Shadow layer - stays in place, disappears visually when pressed
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(shadowColor)
                .frame(minHeight: buttonHeight)
                .offset(y: shadowOffset)

            // Main button - moves down 4px on press to meet shadow position
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(isPressed ? color.opacity(0.9) : color)
                .frame(minHeight: buttonHeight)
                .offset(y: isPressed ? shadowOffset : 0)
                .overlay(
                    configuration.label
                        .font(.headline)  // 17pt semibold per HIG
                        .foregroundColor(textColor)
                        .offset(y: isPressed ? shadowOffset : 0)
                )
        }
        .frame(minHeight: buttonHeight + shadowOffset)
        .scaleEffect(isPressed ? 0.98 : 1.0)  // Subtle shrink per guidelines
        .animation(DuoAnimation.quick, value: isPressed)
        .onChange(of: isPressed) { _, pressed in
            if pressed { DuoHaptics.lightTap() }
        }
    }
}

// MARK: - Button Style Variants
/// PRIMARY BUTTON: Lime green - THE Duolingo button (use for main CTAs)
struct DuoPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwSuccess, shadowColor: .uwSuccessDark, textColor: .white)
            .makeBody(configuration: configuration)
    }
}

/// Success button (same as primary - lime green)
struct DuoSuccessButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwSuccess, shadowColor: .uwSuccessDark, textColor: .white)
            .makeBody(configuration: configuration)
    }
}

/// Blue button - secondary actions
struct DuoBlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwPrimary, shadowColor: .uwPrimaryDark, textColor: .white)
            .makeBody(configuration: configuration)
    }
}

/// Warning button - orange
struct DuoWarningButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwWarning, shadowColor: Color(hex: "CC7000"), textColor: .white)
            .makeBody(configuration: configuration)
    }
}

/// Danger button - red
struct DuoDangerButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwError, shadowColor: Color(hex: "CC3333"), textColor: .white)
            .makeBody(configuration: configuration)
    }
}

/// Accent button - golden yellow
struct DuoAccentButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Duo3DButtonStyle(color: .uwAccent, shadowColor: .uwAccentDark, textColor: Color(hex: "3C3C3C"))
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

// MARK: - Card Modifiers (Duolingo Design Rules)
// Rule: Only pressable elements get shadows
// Non-interactive = flat with border
// Interactive = 3D shadow
extension View {
    /// Info card - FLAT with thin gray border (non-interactive)
    /// Use for: stats, progress displays, info cards
    func duoCard(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.uwCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.uwBorder, lineWidth: 2)
            )
    }

    /// Interactive card with 4px shadow - ONLY for clickable cards
    func duoInteractiveCard(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    // 4px shadow (Duolingo spec)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: 4)

                    // Main card
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                }
            )
    }

    /// 3D card - for prominent interactive elements
    func duo3DCard(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCardShadow)
                        .offset(y: 4)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.uwCard)
                }
            )
    }

    /// Flat card - no border, no shadow
    func duoFlatCard(padding: CGFloat = Spacing.md, cornerRadius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.uwCard)
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
    var tint: Color = .uwSuccess  // Lime green by default
    var shadowOffset: CGFloat = 3

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let pressOffset: CGFloat = isPressed ? shadowOffset : 0

        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(isSelected ? .white : .uwTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        // Solid shadow for selected state
                        Capsule()
                            .fill(tint == .uwSuccess ? Color.uwSuccessDark : tint.darker(by: 0.25))
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
                    // Solid shadow - lime green shadow
                    Circle()
                        .fill(Color.uwSuccessDark)
                        .frame(width: size, height: size)
                        .offset(y: 3)

                    // Main circle - lime green checked
                    Circle()
                        .fill(Color.uwSuccess)
                        .frame(width: size, height: size)

                    // Checkmark - white on lime green
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundColor(.white)
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
                                .stroke(Color.uwBorder, lineWidth: 2)
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

// MARK: - Streak Badge Component
struct DuoStreakBadge: View {
    let count: Int
    let label: String
    var iconName: String = "flame.fill"
    var color: Color = .streakOrange  // Duolingo fire orange

    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -10

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(DuoAnimation.rewardPop.delay(0.2)) {
                        scale = 1.0
                        rotation = 0
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.uwTextSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.uwCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(color.opacity(0.4), lineWidth: 2)
                )
        )
    }
}

// MARK: - XP Counter Component
struct DuoXPCounter: View {
    let xp: Int
    var showPlus: Bool = false

    @State private var displayedXP: Int = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.uwAccent)

            Text(showPlus ? "+\(displayedXP)" : "\(displayedXP)")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.uwAccent)
                .scaleEffect(scale)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.uwAccent.opacity(0.15))
        )
        .onAppear {
            animateXP()
        }
        .onChange(of: xp) { _, _ in
            animateXP()
        }
    }

    private func animateXP() {
        let steps = 20
        let increment = (xp - displayedXP) / steps
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                displayedXP += increment
                if i == steps - 1 {
                    displayedXP = xp
                    withAnimation(DuoAnimation.numberPop) {
                        scale = 1.15
                    }
                    withAnimation(DuoAnimation.numberPop.delay(0.1)) {
                        scale = 1.0
                    }
                }
            }
        }
    }
}

// MARK: - Quest Progress Card
struct DuoQuestCard: View {
    let title: String
    let progress: Double
    let current: Int
    let total: Int
    let icon: String
    var iconColor: Color = .uwAccent

    @State private var animatedProgress: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.uwTextPrimary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.uwCardShadow)
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [iconColor, iconColor.lighter(by: 0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * animatedProgress, height: 12)

                        Text("\(current) / \(total)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(animatedProgress > 0.3 ? .white : .uwTextSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 12)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(iconColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.uwCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.uwCardShadow.opacity(0.3), lineWidth: 2)
                )
        )
        .onAppear {
            withAnimation(DuoAnimation.progressUpdate.delay(0.3)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: - Daily Goal Ring
struct DuoGoalRing: View {
    let progress: Double
    let goal: String
    var color: Color = .uwPrimary
    var size: CGFloat = 100

    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = -90

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: size * 0.12)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color.darker(by: 0.1), color, color.lighter(by: 0.1)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
                )
                .rotationEffect(.degrees(rotation))

            // Center content
            VStack(spacing: 2) {
                Text("\(Int(animatedProgress * 100))%")
                    .font(.system(size: size * 0.28, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)

                Text(goal)
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(.uwTextSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(DuoAnimation.progressUpdate.delay(0.2)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: - Celebration Confetti View
struct DuoConfettiView: View {
    @State private var confetti: [ConfettiPiece] = []
    let colors: [Color] = [.uwPrimary, .uwAccent, .uwSuccess, .uwPurple, .accentBlue]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confetti) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateConfetti(in size: CGSize) {
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                color: colors.randomElement() ?? .uwPrimary,
                x: CGFloat.random(in: 0...size.width),
                startY: -20,
                endY: size.height + 20,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
            confetti.append(piece)
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var y: CGFloat = -20
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * 1.5)
            .rotationEffect(.degrees(piece.rotation))
            .position(x: piece.x, y: y)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeIn(duration: 1.5).delay(piece.delay)) {
                    y = piece.endY
                    opacity = 0
                }
            }
    }
}

// MARK: - Hero Header Component
struct DuoHeroHeader: View {
    let title: String
    let subtitle: String
    var color: Color = .accentBlue
    var iconName: String? = nil

    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [color, color.darker(by: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width * 0.7, y: -30)
                    .blur(radius: 1)

                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: -20, y: geometry.size.height * 0.6)
                    .blur(radius: 1)
            }

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .offset(x: isVisible ? 0 : -30)
                        .opacity(isVisible ? 1 : 0)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(x: isVisible ? 0 : -30)
                        .opacity(isVisible ? 1 : 0)
                }

                Spacer()

                if let icon = iconName {
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                        .scaleEffect(isVisible ? 1 : 0.5)
                        .opacity(isVisible ? 1 : 0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .onAppear {
            withAnimation(DuoAnimation.heroEntrance) {
                isVisible = true
            }
        }
    }
}

// MARK: - Animated Number Display
struct DuoAnimatedNumber: View {
    let value: Int
    let suffix: String
    var color: Color = .uwAccent
    var size: CGFloat = 32

    @State private var displayValue: Int = 0

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 2) {
            Text("\(displayValue)")
                .font(.system(size: size, weight: .heavy))
                .foregroundColor(color)
                .contentTransition(.numericText())

            Text(suffix)
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(color.opacity(0.8))
        }
        .onAppear {
            animateValue()
        }
        .onChange(of: value) { _, _ in
            animateValue()
        }
    }

    private func animateValue() {
        withAnimation(.easeOut(duration: 0.8)) {
            displayValue = value
        }
    }
}

// MARK: - Session Type Badge
struct DuoSessionTypeBadge: View {
    let type: String
    let icon: String
    var color: Color = .uwPrimary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))

            Text(type)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
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
