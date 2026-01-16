//
//  iOS26TabBar.swift
//  sharp
//
//  Duolingo-style tab bar with 3D buttons and bouncy animations
//

import SwiftUI

// MARK: - Tab Item Model
struct TabItem {
    let icon: String
    let title: String
    let index: Int
    let color: Color
}

struct iOS26TabBar: View {
    @Binding var selectedTab: Int
    @Binding var presentingTemplates: Bool
    @Namespace private var tabNamespace

    let mainTabs = [
        TabItem(icon: "house.fill", title: "Home", index: 0, color: .uwPrimary),
        TabItem(icon: "circle.slash", title: "Rules", index: 1, color: .uwPrimary),
        TabItem(icon: "checkmark.circle.fill", title: "Tasks", index: 2, color: .uwPrimary),
        TabItem(icon: "person.fill", title: "Profile", index: 3, color: .uwPrimary),
    ]

    var body: some View {
        HStack(spacing: 12) {
            // Main tabs in 3D card container
            HStack(spacing: 4) {
                ForEach(mainTabs, id: \.index) { tab in
                    DuoTabButton(
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
            .padding(8)
            .background(
                ZStack {
                    // Shadow layer
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.black.opacity(0.15))
                        .offset(y: 4)

                    // Main card
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.uwCard)
                }
            )

            // Floating Quick Action Button
            DuoQuickActionButton(
                onTap: {
                    presentingTemplates = true
                    DuoHaptics.buttonTap()
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Shadow layer (visible when not pressed)
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 56, height: 56)
                    .offset(y: isPressed ? 0 : 4)

                // Main button
                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 56, height: 56)
                    .offset(y: isPressed ? 3 : 0)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .offset(y: isPressed ? 3 : 0)
                    )

                // Plus icon
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: isPressed ? 3 : 0)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(DuoAnimation.buttonPress, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
