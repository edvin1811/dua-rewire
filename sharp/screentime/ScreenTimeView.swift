import SwiftUI
import FamilyControls
import DeviceActivity
import CoreData

// MARK: - iOS 26 Liquid Glass Home View (Jolt-Style)
struct ScreenTimeView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var statisticsManager = StatisticsManager.shared
    @State private var showGoalSetting = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.taskCreatedAt, ascending: false)],
        animation: .default
    ) private var tasks: FetchedResults<TaskEntity>

    var completedTasksToday: [TaskEntity] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter {
            $0.taskIsCompleted &&
            Calendar.current.isDate($0.taskCompletedAt ?? Date(), inSameDayAs: today)
        }
    }

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3
    @State private var reportRefreshID = UUID() // Force refresh DeviceActivityReport

    var body: some View {
        NavigationView {
            ZStack {
                ModernBackground()

                if appStateManager.authorizationState != .granted {
                    authorizationSection
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Header with logo and settings
                            headerSection
                                .padding(.horizontal, 20)
                                .padding(.top, 16)

                            // DeviceActivityReport: time selector + screen time card ONLY
                            homeScreenReport
                                .padding(.horizontal, 20)

                            // Focus Summary Cards at BOTTOM
                            focusSummaryCard
                                .padding(.horizontal, 20)

                            // Active Session Alert (if any)
                            if appStateManager.hasActiveSession {
                                activeSessionCard
                                    .padding(.horizontal, 20)
                            }

                            // Bottom spacing for tab bar
                            Color.clear.frame(height: 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showGoalSetting) {
            GoalSettingView(statisticsManager: statisticsManager)
        }
    }



    // MARK: - Focus Summary Card (Duolingo Style)
    @ViewBuilder
    private var focusSummaryCard: some View {
        HStack(spacing: 16) {
            // Focus Time Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.uwSuccess)

                    Text("Focus Time")
                        .font(.duoSubheadline)
                        .foregroundColor(.uwTextPrimary)
                }

                Text(formatBlockedTime())
                    .font(.duoTitle)
                    .foregroundColor(.uwTextPrimary)

                Text("apps blocked today")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .duo3DCard(padding: 20, cornerRadius: 20)

            // Tasks Done Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.uwPrimary)

                    Text("Tasks Done")
                        .font(.duoSubheadline)
                        .foregroundColor(.uwTextPrimary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(completedTasksToday.count)")
                        .font(.duoTitle)
                        .foregroundColor(.uwTextPrimary)

                    Text("/\(tasks.count)")
                        .font(.duoHeadline)
                        .foregroundColor(.uwTextSecondary)
                }

                Text("completed today")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .duo3DCard(padding: 20, cornerRadius: 20)
        }
    }

    private func formatBlockedTime() -> String {
        let blockedSeconds = appStateManager.totalBlockedTimeToday
        let hours = Int(blockedSeconds) / 3600
        let minutes = (Int(blockedSeconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }

    // MARK: - Home Screen Report (time selector + screen time card only)
    private var homeScreenReport: some View {
        DeviceActivityReport(
            DeviceActivityReport.Context(rawValue: "HomeScreen"),
            filter: getCurrentFilter()
        )
        .id(reportRefreshID) // Force refresh when ID changes
        .frame(minHeight: 280) // Reduced - no apps section anymore
        .onAppear {
            // Trigger refresh when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                reportRefreshID = UUID()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            // App logo
            ZStack {
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 48, height: 48)
                    .offset(y: 3)

                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 48, height: 48)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Unwire")
                        .font(.duoTitle)
                        .foregroundColor(.uwTextPrimary)
                    
                    Text("Pro")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.uwPurple)
                        )
                }

                Text("Focus & Productivity")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }

            Spacer()

            // Goal settings button - 3D style
            Button {
                showGoalSetting = true
                DuoHaptics.lightTap()
            } label: {
                ZStack {
                    // Solid shadow
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.uwCardShadow)
                        .frame(width: 44, height: 44)
                        .offset(y: 3)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.uwCard)
                        .frame(width: 44, height: 44)

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.uwTextPrimary)
                }
            }
        }
    }




    // MARK: - Active Session Card (Duolingo Style)
    private var activeSessionCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.uwWarning.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "lock.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.uwWarning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Focus Mode Active")
                    .font(.duoBodyBold)
                    .foregroundColor(.uwTextPrimary)

                Text(appStateManager.activeSessionDescription)
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)
            }

            Spacer()

            NavigationLink(destination: NewUnifiedBlockingView()) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.uwWarning)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.uwCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.uwWarning.opacity(0.8), lineWidth: 2)
                .scaleEffect(pulseScale)
                .opacity(pulseOpacity)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
        )
        .onAppear {
            self.pulseScale = 1.03
            self.pulseOpacity = 0
        }
    }

    // MARK: - Authorization Section (Duolingo Style)
    private var authorizationSection: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.uwPrimary.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.uwPrimary)
                }

                VStack(spacing: 12) {
                    Text("Screen Time Access")
                        .font(.duoTitle)
                        .foregroundColor(.uwTextPrimary)

                    Text("Track your app usage and stay focused. Your tasks will work without this, but insights are better with it.")
                        .font(.duoBody)
                        .foregroundColor(.uwTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    appStateManager.requestAuthorizationIfNeeded()
                    DuoHaptics.buttonTap()
                } label: {
                    HStack(spacing: 8) {
                        Text("Grant Access")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(DuoPrimaryButton())
                .padding(.top, 8)
            }
            .duo3DCard(padding: 32, cornerRadius: 24)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Helper Methods
    private var goalColor: Color {
        let progress = statisticsManager.todayGoalProgress
        if progress < 0.7 { return .accentGreen }
        else if progress < 1.0 { return .accentOrange }
        else { return .accentRed }
    }

    private var taskCompletionPercentage: Double {
        let totalTasks = tasks.count
        guard totalTasks > 0 else { return 0 }
        let completed = tasks.filter { $0.taskIsCompleted }.count
        return Double(completed) / Double(totalTasks) * 100
    }

    private func getCurrentFilter() -> DeviceActivityFilter {
        guard let todayInterval = Calendar.current.dateInterval(of: .day, for: .now) else {
            fatalError("Could not create today interval")
        }

        return DeviceActivityFilter(
            segment: .daily(during: todayInterval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    // MARK: - Mock Data Generation
    private func generateMockHourlyData() -> [HourlyUsageData] {
        let currentHour = Calendar.current.component(.hour, from: Date())

        return (0...23).map { hour in
            // Generate realistic usage pattern
            var minutes = 0

            if hour <= currentHour {
                // Higher usage during typical active hours
                if hour >= 8 && hour <= 23 {
                    minutes = Int.random(in: 5...45)
                } else if hour >= 0 && hour <= 7 {
                    minutes = Int.random(in: 0...10)
                }
            }

            return HourlyUsageData(
                hour: hour,
                totalMinutes: minutes,
                apps: [] // Empty for now
            )
        }
    }
}

#Preview {
    ScreenTimeView()
        .environmentObject(AppStateManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
