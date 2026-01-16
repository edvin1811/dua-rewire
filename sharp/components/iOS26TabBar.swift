//
//  iOS26TabBar.swift
//  sharp
//
//  Duolingo-style tab bar with 3D buttons, colorful icons, and bouncy animations
//

import SwiftUI

// MARK: - Tab Item Model
struct TabItem {
    let icon: String
    let activeIcon: String
    let title: String
    let index: Int
    let color: Color
    let emoji: String?

    init(icon: String, activeIcon: String? = nil, title: String, index: Int, color: Color, emoji: String? = nil) {
        self.icon = icon
        self.activeIcon = activeIcon ?? icon
        self.title = title
        self.index = index
        self.color = color
        self.emoji = emoji
    }
}

struct iOS26TabBar: View {
    @Binding var selectedTab: Int
    @Binding var presentingTemplates: Bool
    @Namespace private var tabNamespace
    @State private var showBar = false

    let mainTabs = [
        TabItem(icon: "house", activeIcon: "house.fill", title: "Home", index: 0, color: .accentBlue, emoji: "🏠"),
        TabItem(icon: "shield", activeIcon: "shield.fill", title: "Focus", index: 1, color: .uwPurple, emoji: "🛡️"),
        TabItem(icon: "checkmark.circle", activeIcon: "checkmark.circle.fill", title: "Tasks", index: 2, color: .uwSuccess, emoji: "✅"),
        TabItem(icon: "person", activeIcon: "person.fill", title: "Profile", index: 3, color: .uwWarning, emoji: "👤"),
    ]

    var body: some View {
        HStack(spacing: 12) {
            // Main tabs in 3D card container
            HStack(spacing: 0) {
                ForEach(mainTabs, id: \.index) { tab in
                    DuoColorfulTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.index,
                        namespace: tabNamespace,
                        onTap: {
                            withAnimation(DuoAnimation.tabSwitch) {
                                selectedTab = tab.index
                            }
                            DuoHaptics.selection()
                        }
                    )
                }
            }
            .padding(6)
            .background(
                ZStack {
                    // Shadow layer
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.uwCardShadow)
                        .offset(y: 4)

                    // Main card
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.uwCard)
                }
            )
            .scaleEffect(showBar ? 1 : 0.9)
            .opacity(showBar ? 1 : 0)

            // Floating Quick Action Button
            DuoQuickActionButton(
                onTap: {
                    presentingTemplates = true
                    DuoHaptics.buttonTap()
                }
            )
            .scaleEffect(showBar ? 1 : 0.8)
            .opacity(showBar ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.2)) {
                showBar = true
            }
        }
    }
}

// MARK: - Colorful Tab Button (Duolingo Style)
struct DuoColorfulTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var bounceScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            // Bounce animation on tap
            withAnimation(DuoAnimation.rewardPop) {
                bounceScale = 1.2
            }
            withAnimation(DuoAnimation.rewardPop.delay(0.1)) {
                bounceScale = 1.0
            }
            onTap()
        }) {
            VStack(spacing: 4) {
                ZStack {
                    // Selected background pill
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(tab.color.opacity(0.15))
                            .frame(width: 56, height: 36)
                            .matchedGeometryEffect(id: "selectedTabBg", in: namespace)
                    }

                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? tab.color : .uwTextTertiary)
                        .scaleEffect(bounceScale)
                }
                .frame(height: 36)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? tab.color : .uwTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Original Tab Button (for backwards compatibility)
struct DuoTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        DuoColorfulTabButton(tab: tab, isSelected: isSelected, namespace: namespace, onTap: onTap)
    }
}

// MARK: - Duolingo-Style Tab Button
struct DuoTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .bold))

                if isSelected {
                    Text(tab.title)
                        .font(.system(size: 14, weight: .heavy))
                        .lineLimit(1)
                }
            }
            .foregroundColor(isSelected ? .white : .uwTextSecondary)
            .padding(.horizontal, isSelected ? 18 : 14)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    if isSelected {
                        // Shadow for selected pill
                        Capsule()
                            .fill(Color.uwPrimaryDark)
                            .offset(y: 3)
                            .matchedGeometryEffect(id: "selectedTabShadow", in: namespace)

                        // Main pill
                        Capsule()
                            .fill(Color.uwPrimary)
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                    }
                }
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Duolingo-Style Quick Action Button
struct DuoQuickActionButton: View {
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            // Rotate plus icon on tap
            withAnimation(DuoAnimation.rewardPop) {
                rotation += 90
            }
            onTap()
        }) {
            ZStack {
                // Outer pulse ring (ambient animation)
                Circle()
                    .stroke(Color.uwPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulseScale)
                    .opacity(2 - pulseScale)

                // Shadow layer (visible when not pressed)
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 56, height: 56)
                    .offset(y: isPressed ? 0 : 4)

                // Main button with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.uwPrimary.lighter(by: 0.05), Color.uwPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 56, height: 56)
                    .offset(y: isPressed ? 3 : 0)

                // Shine overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: 56, height: 56)
                    .offset(y: isPressed ? 3 : 0)

                // Plus icon with rotation
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(rotation))
                    .offset(y: isPressed ? 3 : 0)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(DuoAnimation.buttonPress, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(DuoAnimation.buttonPress) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            // Start ambient pulse animation
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
    }
}

// MARK: - Legacy Compatibility Aliases
struct iOS26GlassTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        DuoTabButton(tab: tab, isSelected: isSelected, namespace: namespace, onTap: onTap)
    }
}

struct GlassQuickActionButton: View {
    @Binding var isPresented: Bool
    let onTap: () -> Void

    var body: some View {
        DuoQuickActionButton(onTap: onTap)
    }
}

struct QuickActionButton: View {
    @Binding var isPresented: Bool
    let onTap: () -> Void

    var body: some View {
        DuoQuickActionButton(onTap: onTap)
    }
}

// MARK: - Preview
#Preview("Tab Bar") {
    ZStack {
        Color.uwBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            iOS26TabBar(
                selectedTab: .constant(0),
                presentingTemplates: .constant(false)
            )
        }
    }
}

#Preview("Tab Bar - Dark Mode") {
    ZStack {
        Color.uwBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            iOS26TabBar(
                selectedTab: .constant(2),
                presentingTemplates: .constant(false)
            )
        }
    }
    .preferredColorScheme(.dark)
}
