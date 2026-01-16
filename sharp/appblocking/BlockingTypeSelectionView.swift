//
//  BlockingTypeSelectionView.swift
//  sharp
//
//  Duolingo-Style Blocking Type Selection with 3D Cards
//

import SwiftUI

struct BlockingTypeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: BlockingType? = nil
    @State private var showWizard = false
    @State private var appeared = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Blocking type grid
                        blockingTypesGrid

                        // Continue button
                        if selectedType != nil {
                            continueButton
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showWizard) {
                if let type = selectedType {
                    BlockingWizardCoordinator(blockingType: type)
                }
            }
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    dismiss()
                    DuoHaptics.lightTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.uwTextTertiary.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextSecondary)
                    }
                }

                Spacer()
            }

            VStack(spacing: 8) {
                Text("Choose Focus Mode")
                    .font(.duoTitle)
                    .foregroundColor(.uwTextPrimary)

                Text("Select how you want to block distractions")
                    .font(.duoBody)
                    .foregroundColor(.uwTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .offset(y: appeared ? 0 : -20)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.top, 20)
    }

    private var blockingTypesGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(Array(BlockingType.allCases.enumerated()), id: \.element) { index, type in
                BlockingTypeCard(
                    type: type,
                    isSelected: selectedType == type
                ) {
                    withAnimation(DuoAnimation.tabSwitch) {
                        selectedType = type
                    }
                    DuoHaptics.selection()
                }
                .offset(y: appeared ? 0 : 30)
                .opacity(appeared ? 1 : 0)
                .animation(DuoAnimation.staggered(index: index, delay: 0.05), value: appeared)
            }
        }
    }

    private var continueButton: some View {
        Button {
            showWizard = true
            DuoHaptics.buttonTap()
        } label: {
            HStack(spacing: 12) {
                Text("Continue")
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .heavy))
            }
        }
        .buttonStyle(DuoPrimaryButton())
        .padding(.top, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct BlockingTypeCard: View {
    let type: BlockingType
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var cardColor: Color {
        switch type {
        case .timer: return .uwWarning
        case .schedule: return .uwPurple
        case .task: return .uwSuccess
        case .location: return .uwPrimary
        case .steps: return .uwAccent
        case .sleep: return Color(hex: "8B5CF6")
        }
    }

    var shadowColor: Color {
        switch type {
        case .timer: return Color(hex: "CC7700")
        case .schedule: return Color(hex: "A862E5")
        case .task: return Color(hex: "3D9001")
        case .location: return .uwPrimaryDark
        case .steps: return .uwAccentDark
        case .sleep: return Color(hex: "6D3FD9")
        }
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 12) {
                // 3D Icon circle
                ZStack {
                    if isSelected {
                        // Shadow when selected
                        Circle()
                            .fill(shadowColor)
                            .frame(width: 48, height: 48)
                            .offset(y: 3)

                        Circle()
                            .fill(cardColor)
                            .frame(width: 48, height: 48)
                    } else {
                        Circle()
                            .fill(cardColor.opacity(0.15))
                            .frame(width: 48, height: 48)
                    }

                    Image(systemName: type.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isSelected ? .white : cardColor)
                }

                // Title
                Text(type.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.uwTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                ZStack {
                    // 3D shadow layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? shadowColor.opacity(0.5) : Color.black.opacity(0.15))
                        .offset(y: isPressed ? 2 : 4)

                    // Main card
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.uwCard)
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? cardColor : Color.clear, lineWidth: 3)
                    .offset(y: isPressed ? 2 : 0)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(DuoAnimation.buttonPress, value: isPressed)
            .animation(DuoAnimation.tabSwitch, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Wizard Coordinator
struct BlockingWizardCoordinator: View {
    let blockingType: BlockingType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch blockingType {
            case .timer:
                TimerBlockingWizard()
            case .schedule:
                ScheduleBlockingWizard()
            case .task:
                TaskBlockingWizard()
            case .location:
                LocationBlockingWizard()
            case .steps:
                StepsBlockingWizard()
            case .sleep:
                SleepBlockingWizard()
            }
        }
    }
}

#Preview {
    BlockingTypeSelectionView()
}
