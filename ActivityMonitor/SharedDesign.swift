//
//  SharedDesign.swift
//  ActivityMonitor
//
//  Shared design constants and utilities for all DeviceActivityReport components
//

import SwiftUI

// MARK: - App Group for sharing data between main app and extension
enum AppGroupConfig {
    static let suiteName = "group.com.coolstudio.sharp"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // Keys for shared data
    enum Keys {
        static let dailyGoal = "dailyGoalSeconds"
        static let focusScore = "focusScore"
        static let goalStreak = "goalStreak"
    }

    // Read daily goal from shared UserDefaults (set by main app)
    static var dailyGoal: TimeInterval {
        sharedDefaults?.double(forKey: Keys.dailyGoal) ?? 14400 // Default 4 hours
    }
}

// MARK: - Color Extension
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Design System Colors (iOS 26 Glassmorphism)
enum GlassDesign {
    // Glass backgrounds - slightly more visible for iOS 26 style
    static let background = Color.white.opacity(0.10)
    static let backgroundLight = Color.white.opacity(0.14)
    static let border = Color.white.opacity(0.18)
    static let highlight = Color.white.opacity(0.30)

    // Brand colors
    static let brand = Color(hex: "A8E61D")
    static let brandDark = Color(hex: "8BC516")

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)

    // Accent colors
    static let success = Color(hex: "58CC02")
    static let blue = Color(hex: "0A84FF")
    static let orange = Color(hex: "FF9500")
    static let red = Color(hex: "FF453A")
    static let purple = Color(hex: "BF5AF2")

    // Rank colors
    static let gold = Color(hex: "FFD700")
    static let silver = Color(hex: "C0C0C0")
    static let bronze = Color(hex: "CD7F32")

    // App background
    static let appBackground = Color(hex: "0A0A0A")
}

// MARK: - Glass Card Modifier (Custom Glassmorphism)
// Beautiful custom glass effect with gradient tint and glassy borders
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    var tintColor: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .background {
                // Enhanced subtle gradient background with more depth
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                // Enhanced subtle gradient border with more variation
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Generic Glass Effect Modifier (for any shape)
// Custom glassmorphism effect that works with any shape
struct GlassEffect<S: InsettableShape>: ViewModifier {
    var shape: S
    var tintColor: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .background {
                // Enhanced subtle gradient background with more depth
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                // Enhanced subtle gradient border with more variation
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.28),
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(shape)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Conditional Glass Effect Modifier (Custom Glassmorphism)
struct ConditionalGlassEffect<S: InsettableShape>: ViewModifier {
    var isActive: Bool
    var shape: S
    var tintColor: Color? = nil

    @ViewBuilder
    func body(content: Content) -> some View {
        if isActive {
            // When active, show solid background with tint
            content
                .background {
                    shape
                        .fill((tintColor ?? GlassDesign.brand).opacity(0.3))
                }
                .overlay {
                    shape
                        .strokeBorder((tintColor ?? GlassDesign.brand).opacity(0.5), lineWidth: 1.5)
                }
                .clipShape(shape)
        } else {
            // When not active, show enhanced subtle glass effect with gradients
            content
                .background {
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    shape
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.20),
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .clipShape(shape)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Time Formatting Utilities
enum TimeFormatter {
    static func format(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    static func formatShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60

        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    static func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
    }
}
