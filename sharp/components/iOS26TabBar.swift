//
//  iOS26TabBar.swift
//  sharp
//
//  Clean, branded tab bar with two-color system
//

import SwiftUI

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    let id: Int
    let icon: String
    let activeIcon: String
    let title: String

    init(icon: String, activeIcon: String? = nil, title: String, index: Int) {
        self.id = index
        self.icon = icon
        self.activeIcon = activeIcon ?? "\(icon).fill"
        self.title = title
    }
}

// MARK: - Main Tab Bar
struct iOS26TabBar: View {
    @Binding var selectedTab: Int
    @Binding var presentingTemplates: Bool
    @Namespace private var tabNamespace
    @State private var showBar = false

    // New tab structure: Home, Focus, Insights, Profile
    let mainTabs = [
        TabItem(icon: "house", activeIcon: "house.fill", title: "Home", index: 0),
        TabItem(icon: "shield", activeIcon: "shield.fill", title: "Focus", index: 1),
        TabItem(icon: "chart.bar", activeIcon: "chart.bar.fill", title: "Insights", index: 2),
        TabItem(icon: "person", activeIcon: "person.fill", title: "Profile", index: 3),
    ]

    var body: some View {
        HStack(spacing: 12) {
            // Main tabs container
            HStack(spacing: 0) {
                ForEach(mainTabs) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.id,
                        namespace: tabNamespace,
                        onTap: {
                            withAnimation(DuoAnimation.tabSwitch) {
                                selectedTab = tab.id
                            }
                            DuoHaptics.selection()
                        }
                    )
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.uwCard)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.uwBorder, lineWidth: 1)
            )
            .scaleEffect(showBar ? 1 : 0.95)
            .opacity(showBar ? 1 : 0)

            // Quick Action Button
            QuickAddButton(onTap: {
                presentingTemplates = true
                DuoHaptics.buttonTap()
            })
            .scaleEffect(showBar ? 1 : 0.9)
            .opacity(showBar ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                showBar = true
            }
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Selected indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.uwPrimary.opacity(0.12))
                            .frame(width: 52, height: 32)
                            .matchedGeometryEffect(id: "tabIndicator", in: namespace)
                    }

                    Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .uwPrimary : .uwTextTertiary)
                }
                .frame(height: 32)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .uwPrimary : .uwTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) { isPressed = false }
                }
        )
    }
}

// MARK: - Quick Add Button
struct QuickAddButton: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Shadow
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 52, height: 52)
                    .offset(y: isPressed ? 0 : 3)

                // Main button
                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 52, height: 52)
                    .offset(y: isPressed ? 2 : 0)

                // Icon
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .offset(y: isPressed ? 2 : 0)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Legacy Compatibility
struct DuoTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        TabButton(tab: tab, isSelected: isSelected, namespace: namespace, onTap: onTap)
    }
}

struct DuoColorfulTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        TabButton(tab: tab, isSelected: isSelected, namespace: namespace, onTap: onTap)
    }
}

struct DuoQuickActionButton: View {
    let onTap: () -> Void

    var body: some View {
        QuickAddButton(onTap: onTap)
    }
}

// MARK: - Preview
#Preview("Tab Bar - Light") {
    ZStack {
        Color.uwBackground.ignoresSafeArea()
        VStack {
            Spacer()
            iOS26TabBar(selectedTab: .constant(0), presentingTemplates: .constant(false))
        }
    }
}

#Preview("Tab Bar - Dark") {
    ZStack {
        Color.uwBackground.ignoresSafeArea()
        VStack {
            Spacer()
            iOS26TabBar(selectedTab: .constant(2), presentingTemplates: .constant(false))
        }
    }
    .preferredColorScheme(.dark)
}
