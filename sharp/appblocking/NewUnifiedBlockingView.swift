//
//  NewUnifiedBlockingView.swift
//  sharp
//
//  Duolingo-Style Rules View with 3D Cards and Bouncy Animations
//

import SwiftUI
import CoreData
import FamilyControls

struct NewUnifiedBlockingView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var showingBlockingTypeSelection = false
    @State private var showingTemplates = false
    @State private var selectedTab: BlockingTab = .session
    @State private var cardsAppeared = false
    @State private var headerAppeared = false

    // Icon pulse states for session cards
    @State private var iconPulse: CGFloat = 1.0
    @State private var taskIconPulse: CGFloat = 1.0
    @State private var scheduleIconPulse: CGFloat = 1.0
    @State private var locationIconPulse: CGFloat = 1.0
    @State private var stepsIconPulse: CGFloat = 1.0
    @State private var sleepIconPulse: CGFloat = 1.0

    enum BlockingTab: String, CaseIterable {
        case active = "Active"
        case session = "Session"
        case limits = "Limits"
        case special = "Special"
    }

    var body: some View {
        ZStack {
            ModernBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with add button
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // 3D Tab selector
                    tabSelector
                        .padding(.horizontal, 20)

                    // Content: Active Sessions or Empty State
                    if appStateManager.hasActiveSession {
                        activeSessionsContent
                            .padding(.horizontal, 20)
                    } else {
                        emptyStateContent
                            .padding(.horizontal, 20)

                        // Templates section
                        templatesSection
                            .padding(.horizontal, 20)
                    }

                    // Bottom spacing for tab bar
                    Color.clear.frame(height: 100)
                }
            }
        }
        .sheet(isPresented: $showingBlockingTypeSelection) {
            BlockingTypeSelectionView()
                .environmentObject(appStateManager)
        }
        .sheet(isPresented: $showingTemplates) {
            TemplatesView()
                .environmentObject(appStateManager)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                headerAppeared = true
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Rules")
                .font(.duoTitle)
                .foregroundColor(.uwTextPrimary)
                .offset(y: headerAppeared ? 0 : -20)
                .opacity(headerAppeared ? 1 : 0)

            Spacer()

            // 3D Add button
            Button {
                showingBlockingTypeSelection = true
                DuoHaptics.buttonTap()
            } label: {
                ZStack {
                    // Shadow layer
                    Circle()
                        .fill(Color.uwPrimaryDark)
                        .frame(width: 48, height: 48)
                        .offset(y: 3)

                    // Main button
                    Circle()
                        .fill(Color.uwPrimary)
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(headerAppeared ? 1 : 0.5)
            .opacity(headerAppeared ? 1 : 0)
        }
    }

    // MARK: - 3D Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(BlockingTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(DuoAnimation.tabSwitch) {
                        selectedTab = tab
                    }
                    DuoHaptics.selection()
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selectedTab == tab ? .white : .uwTextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    // Shadow for selected
                                    Capsule()
                                        .fill(Color.uwPrimaryDark)
                                        .offset(y: 3)

                                    Capsule()
                                        .fill(Color.uwPrimary)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            ZStack {
                // Solid shadow
                Capsule()
                    .fill(Color.uwCardShadow)
                    .offset(y: 3)

                Capsule()
                    .fill(Color.uwCard)
            }
        )
    }

    // MARK: - Templates Section
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                ZStack {
                    // Solid shadow for icon
                    Circle()
                        .fill(Color.uwAccent.darker(by: 0.3))
                        .frame(width: 32, height: 32)
                        .offset(y: 2)

                    Circle()
                        .fill(Color.uwAccent)
                        .frame(width: 32, height: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Quick Start Templates")
                    .font(.duoSubheadline)
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                Button {
                    showingTemplates = true
                    DuoHaptics.lightTap()
                } label: {
                    Text("See All")
                        .font(.duoCaption)
                        .foregroundColor(.uwPrimary)
                }
            }

            // Category pills with 3D style
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    templateCategoryPill("All", isSelected: true)
                    templateCategoryPill("Productivity", isSelected: false)
                    templateCategoryPill("Mindfulness", isSelected: false)
                    templateCategoryPill("Health", isSelected: false)
                }
            }

            // Template cards with 3D effect
            HStack(spacing: 12) {
                templateCard(title: "Personal life", imageName: "cup.and.saucer.fill", color: .uwPrimary)
                templateCard(title: "Work Focus", imageName: "briefcase.fill", color: .uwAccent)
            }
        }
        .duoCard()
    }

    private func templateCategoryPill(_ title: String, isSelected: Bool) -> some View {
        Button {
            DuoHaptics.selection()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .white : .uwTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color.uwPrimaryDark)
                                .offset(y: 2)

                            Capsule()
                                .fill(Color.uwPrimary)
                        } else {
                            Capsule()
                                .fill(Color.uwSurface)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private func templateCard(title: String, imageName: String, color: Color) -> some View {
        Button {
            showingTemplates = true
            DuoHaptics.buttonTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Icon area with 3D effect
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(height: 80)

                    Image(systemName: imageName)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.duoCaption)
                    .foregroundColor(.uwTextPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Sessions Content
    private var activeSessionsContent: some View {
        VStack(spacing: 16) {
            // Active Timer Session
            if let timerSession = appStateManager.activeTimerSession {
                activeTimerSessionCard(timerSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 0), value: cardsAppeared)
            }

            // Active Task Session
            if let taskSession = appStateManager.activeTaskSession {
                activeTaskSessionCard(taskSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 1), value: cardsAppeared)
            }

            // Active Schedule Session
            if let scheduleSession = BlockingSessionManager.shared.activeScheduleSession {
                activeScheduleSessionCard(scheduleSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 2), value: cardsAppeared)
            }

            // Active Location Session
            if let locationSession = BlockingSessionManager.shared.activeLocationSession {
                activeLocationSessionCard(locationSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 3), value: cardsAppeared)
            }

            // Active Steps Session
            if let stepsSession = BlockingSessionManager.shared.activeStepsSession {
                activeStepsSessionCard(stepsSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 4), value: cardsAppeared)
            }

            // Active Sleep Session
            if let sleepSession = BlockingSessionManager.shared.activeSleepSession {
                activeSleepSessionCard(sleepSession)
                    .offset(x: cardsAppeared ? 0 : 50)
                    .opacity(cardsAppeared ? 1 : 0)
                    .animation(DuoAnimation.staggered(index: 5), value: cardsAppeared)
            }

            // Add another session button
            addAnotherBlockButton
                .offset(x: cardsAppeared ? 0 : 50)
                .opacity(cardsAppeared ? 1 : 0)
                .animation(DuoAnimation.staggered(index: 6), value: cardsAppeared)
        }
        .onAppear {
            cardsAppeared = true
        }
        .onDisappear {
            cardsAppeared = false
        }
    }

    private var addAnotherBlockButton: some View {
        Button {
            showingBlockingTypeSelection = true
            DuoHaptics.buttonTap()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.uwPrimary.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.uwPrimary)
                }

                Text("Add Another Block")
                    .font(.duoBodyBold)
                    .foregroundColor(.uwPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.uwPrimary)
            }
            .padding(16)
        }
        .buttonStyle(DuoCardButtonStyle())
    }

    // MARK: - Empty State Content
    private var emptyStateContent: some View {
        VStack(spacing: 24) {
            // Illustration area
            ZStack {
                Circle()
                    .fill(Color.uwPrimary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "shield.checkered")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.uwPrimary)
            }
            .padding(.top, 20)

            VStack(spacing: 12) {
                Text("No active sessions")
                    .font(.duoHeadline)
                    .foregroundColor(.uwTextPrimary)

                Text("Create your first focus session to start building better habits!")
                    .font(.duoBody)
                    .foregroundColor(.uwTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Hint pill with 3D effect
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.uwAccent)

                Text("Use templates below to get started")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    Capsule()
                        .fill(Color.uwAccentDark.opacity(0.3))
                        .offset(y: 2)

                    Capsule()
                        .fill(Color.uwAccent.opacity(0.2))
                }
            )

            // Primary action button
            Button {
                showingBlockingTypeSelection = true
                DuoHaptics.buttonTap()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Create New Block")
                }
            }
            .buttonStyle(DuoPrimaryButton())
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
        .duoCard()
    }

    // MARK: - Session Card Helper
    private func sessionCardContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .duo3DCard(padding: 20, cornerRadius: 20, shadowOffset: 5)
    }

    // MARK: - Timer Session Card
    private func activeTimerSessionCard(_ session: TimerBlockingSession) -> some View {
        sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        // Pulsing icon with color based on progress
                        ZStack {
                            Circle()
                                .fill(timerIconColor(session.progressPercentage).opacity(0.2))
                                .frame(width: 48, height: 48)

                            // Shadow for 3D effect
                            Circle()
                                .fill(timerIconColor(session.progressPercentage).opacity(0.5))
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(timerIconColor(session.progressPercentage))
                                .frame(width: 40, height: 40)

                            Image(systemName: "timer")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(iconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                iconPulse = 1.1
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Timer Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.name)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endTimerSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                    }
                }

                // Progress section
                VStack(spacing: 12) {
                    HStack {
                        Text("Time Remaining")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)

                        Spacer()

                        Text(session.formattedTimeRemaining)
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(timerIconColor(session.progressPercentage))
                            .monospacedDigit()
                    }

                    // 3D Progress bar
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.uwTextTertiary.opacity(0.3))
                            .frame(height: 16)

                        // Progress fill with 3D effect
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Shadow
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(progressColor(session.progressPercentage).opacity(0.5))
                                    .frame(width: geometry.size.width * CGFloat(session.progressPercentage), height: 16)
                                    .offset(y: 2)

                                // Main fill
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(progressColor(session.progressPercentage))
                                    .frame(width: geometry.size.width * CGFloat(session.progressPercentage), height: 14)
                            }
                        }
                        .animation(DuoAnimation.progressUpdate, value: session.progressPercentage)
                    }
                    .frame(height: 16)

                    HStack {
                        Text("Started \(session.startTime.formatted(date: .omitted, time: .shortened))")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextTertiary)

                        Spacer()

                        Text("\(Int(session.duration/60)) min")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextTertiary)
                    }
                }
            }
        }
    }

    // Helper functions for timer card
    private func timerIconColor(_ progress: Double) -> Color {
        if progress < 0.5 { return .uwSuccess }
        else if progress < 0.75 { return .uwAccent }
        else if progress < 0.9 { return .uwWarning }
        else { return .uwError }
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress < 0.5 { return .uwSuccess }
        else if progress < 0.75 { return .uwAccent }
        else { return .uwWarning }
    }

    // MARK: - Task Session Card
    private func activeTaskSessionCard(_ session: TaskBlockingSession) -> some View {
        sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.uwSuccess.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(Color.uwSuccess.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(Color.uwSuccess)
                                .frame(width: 40, height: 40)

                            Image(systemName: "checklist")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(taskIconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                taskIconPulse = 1.15
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Task Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text("\(session.taskIds.count) Tasks")
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endTaskSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Session Duration")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)

                        Spacer()

                        Text(session.formattedDuration)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.uwSuccess)
                    }

                    HStack {
                        Text("Complete all tasks to unlock")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextTertiary)

                        Spacer()

                        NavigationLink {
                            TasksView()
                        } label: {
                            HStack(spacing: 4) {
                                Text("View Tasks")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.uwSuccess)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Schedule Session Card
    private func activeScheduleSessionCard(_ session: ScheduleBlockingSession) -> some View {
        sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.uwPurple.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(Color.uwPurple.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(Color.uwPurple)
                                .frame(width: 40, height: 40)

                            Image(systemName: "calendar")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(scheduleIconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                scheduleIconPulse = 1.15
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Schedule Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.name)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endScheduleSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Schedule Time")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)

                        Spacer()

                        Text(session.formattedSchedule)
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.uwPurple)
                    }

                    // Status indicator with 3D dot
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(session.isCurrentlyInSchedule ? Color.uwPurple.opacity(0.5) : Color.uwTextTertiary.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .offset(y: 1)

                            Circle()
                                .fill(session.isCurrentlyInSchedule ? Color.uwPurple : Color.uwTextTertiary)
                                .frame(width: 10, height: 10)
                        }

                        Text(session.isCurrentlyInSchedule ? "Currently blocking" : "Waiting for schedule")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextTertiary)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Location Session Card
    private func activeLocationSessionCard(_ session: LocationBlockingSession) -> some View {
        sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.uwPrimary.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(Color.uwPrimaryDark)
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(Color.uwPrimary)
                                .frame(width: 40, height: 40)

                            Image(systemName: "location.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(locationIconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                locationIconPulse = 1.15
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Location Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.name)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endLocationSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                        appStateManager.locationManager.stopMonitoring(identifier: session.id.uuidString)
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.locationName)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)

                            Text(session.triggerType.rawValue)
                                .font(.duoSmall)
                                .foregroundColor(.uwTextTertiary)
                        }

                        Spacer()

                        Text(session.formattedRadius)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.uwPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Steps Session Card
    private func activeStepsSessionCard(_ session: StepBlockingSession) -> some View {
        sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.uwAccent.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(Color.uwAccentDark)
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(Color.uwAccent)
                                .frame(width: 40, height: 40)

                            Image(systemName: "figure.walk")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(stepsIconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                stepsIconPulse = 1.15
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Steps Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.name)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endStepsSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)

                        Spacer()

                        Text(session.formattedProgress)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.uwAccent)
                    }

                    // 3D Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.uwTextTertiary.opacity(0.3))
                            .frame(height: 14)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.uwAccentDark)
                                    .frame(width: geometry.size.width * CGFloat(session.progress), height: 14)
                                    .offset(y: 2)

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.uwAccent)
                                    .frame(width: geometry.size.width * CGFloat(session.progress), height: 12)
                            }
                        }
                        .animation(DuoAnimation.progressUpdate, value: session.progress)
                    }
                    .frame(height: 14)

                    Text("\(session.stepsRemaining) steps to go")
                        .font(.duoSmall)
                        .foregroundColor(.uwTextTertiary)
                }
            }
        }
    }

    // MARK: - Sleep Session Card
    private func activeSleepSessionCard(_ session: SleepBlockingSession) -> some View {
        let sleepPurple = Color(hex: "8B5CF6")
        let sleepPurpleDark = Color(hex: "6D3FD9")

        return sessionCardContent {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(sleepPurple.opacity(0.2))
                                .frame(width: 48, height: 48)

                            Circle()
                                .fill(sleepPurpleDark)
                                .frame(width: 40, height: 40)
                                .offset(y: 2)

                            Circle()
                                .fill(sleepPurple)
                                .frame(width: 40, height: 40)

                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(sleepIconPulse)
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                sleepIconPulse = 1.15
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sleep Session")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.name)
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }
                    }

                    Spacer()

                    sessionMenu {
                        BlockingSessionManager.shared.endSleepSession(
                            familyControlsManager: appStateManager.familyControlsManager
                        )
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bedtime")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.formattedBedtime)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(sleepPurple)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Wake")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextSecondary)
                            Text(session.formattedWakeup)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(sleepPurple)
                        }
                    }

                    // Status indicator
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(session.isCurrentlySleepTime ? sleepPurple.opacity(0.5) : Color.uwTextTertiary.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .offset(y: 1)

                            Circle()
                                .fill(session.isCurrentlySleepTime ? sleepPurple : Color.uwTextTertiary)
                                .frame(width: 10, height: 10)
                        }

                        Text(session.isCurrentlySleepTime ? "Sleep mode active" : "Waiting for bedtime")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextTertiary)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Session Menu Helper
    private func sessionMenu(endAction: @escaping () -> Void) -> some View {
        Menu {
            Button(role: .destructive) {
                endAction()
                DuoHaptics.success()
            } label: {
                Label("End Session", systemImage: "stop.circle")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.uwTextTertiary.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.uwTextSecondary)
            }
        }
    }
}

// MARK: - Feature Highlight Component (Updated for Duo style)
struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 48, height: 48)
                    .offset(y: 2)

                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.duoBodyBold)
                    .foregroundColor(.uwTextPrimary)

                Text(description)
                    .font(.duoSmall)
                    .foregroundColor(.uwTextSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .duoCard(padding: 16)
    }
}

#Preview {
    NewUnifiedBlockingView()
        .environmentObject(AppStateManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
