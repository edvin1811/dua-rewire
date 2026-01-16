//
//  ModernGlowBackground.swift
//  sharp
//
//  Duolingo-inspired backgrounds with gradients and subtle animations
//

import SwiftUI

// MARK: - Main App Background
struct ModernBackground: View {
    var showTopGlow: Bool = false  // Legacy parameter, now ignored

    var body: some View {
        Color.uwBackground
            .ignoresSafeArea()
    }
}

// MARK: - Animated Gradient Background (like Duolingo Super screen)
struct AnimatedGradientBackground: View {
    let colors: [Color]
    @State private var animateGradient = false

    init(colors: [Color] = [.accentBlue, .uwPurple]) {
        self.colors = colors
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Premium/Super Style Background (Deep purple gradient with stars)
struct PremiumBackground: View {
    @State private var starsOpacity: Double = 0.3

    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a1a2e"),
                    Color(hex: "16213e"),
                    Color(hex: "0f3460")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative stars/sparkles
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height * 0.7)
                        )
                        .opacity(starsOpacity)
                }
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    starsOpacity = 0.8
                }
            }
        }
    }
}

// MARK: - Hero Header Background
struct HeroHeaderBackground: View {
    let color: Color
    @State private var showDecorations = false

    init(color: Color = .accentBlue) {
        self.color = color
    }

    var body: some View {
        ZStack {
            // Main gradient
            LinearGradient(
                colors: [color, color.darker(by: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            GeometryReader { geometry in
                // Large circle top right
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: geometry.size.width - 80, y: -60)
                    .scaleEffect(showDecorations ? 1 : 0.8)
                    .opacity(showDecorations ? 1 : 0)

                // Small circle bottom left
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geometry.size.height - 30)
                    .scaleEffect(showDecorations ? 1 : 0.8)
                    .opacity(showDecorations ? 1 : 0)

                // Floating dots
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 6, height: 6)
                    .offset(x: geometry.size.width * 0.3, y: 30)
                    .floating(distance: 4, duration: 2.0)
                    .opacity(showDecorations ? 1 : 0)

                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .offset(x: geometry.size.width * 0.7, y: 50)
                    .floating(distance: 3, duration: 2.5)
                    .opacity(showDecorations ? 1 : 0)

                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 5, height: 5)
                    .offset(x: geometry.size.width * 0.5, y: geometry.size.height * 0.6)
                    .floating(distance: 5, duration: 1.8)
                    .opacity(showDecorations ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(DuoAnimation.heroEntrance) {
                showDecorations = true
            }
        }
    }
}

// MARK: - Quest Card Background (with subtle gradient)
struct QuestCardBackground: View {
    let accentColor: Color
    var isCompleted: Bool = false

    var body: some View {
        ZStack {
            // Shadow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.uwCardShadow)
                .offset(y: 4)

            // Main card with optional gradient tint
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isCompleted
                            ? [accentColor.opacity(0.1), Color.uwCard]
                            : [Color.uwCard, Color.uwCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            if !isCompleted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.uwCardShadow.opacity(0.3), lineWidth: 2)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accentColor.opacity(0.5), lineWidth: 2)
            }
        }
    }
}

// MARK: - Alternative Background with subtle accent
struct GlassGradientBackground: View {
    let accentColor: Color

    init(accentColor: Color = .uwPrimary) {
        self.accentColor = accentColor
    }

    var body: some View {
        // Clean solid background - no translucent effects per design system
        Color.uwBackground
            .ignoresSafeArea()
    }
}

// MARK: - Surface Background (for elevated content areas)
struct SurfaceBackground: View {
    var body: some View {
        Color.uwSurface
            .ignoresSafeArea()
    }
}

// MARK: - Card Background View
struct CardBackground: View {
    var cornerRadius: CGFloat = 12  // Less rounded
    var shadowOffset: CGFloat = 4

    var body: some View {
        ZStack {
            // Solid shadow - no blur, cartoony style
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.uwCardShadow)
                .offset(y: shadowOffset)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.uwCard)
        }
    }
}

// MARK: - Celebration Background (for achievements/completions)
struct CelebrationBackground: View {
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.uwPrimary.opacity(0.2),
                    Color.uwAccent.opacity(0.15),
                    Color.uwSuccess.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Confetti particles
            if showConfetti {
                DuoConfettiView()
            }
        }
        .onAppear {
            showConfetti = true
        }
    }
}

// MARK: - Preview
#Preview("Hero Header") {
    HeroHeaderBackground(color: .accentBlue)
        .frame(height: 220)
}

#Preview("Premium Background") {
    PremiumBackground()
}

#Preview("Animated Gradient") {
    AnimatedGradientBackground(colors: [.uwPurple, .accentBlue])
}
