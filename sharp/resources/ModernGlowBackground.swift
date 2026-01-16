//
//  ModernGlowBackground.swift
//  sharp
//
//  Clean solid backgrounds for Duolingo-inspired design
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
