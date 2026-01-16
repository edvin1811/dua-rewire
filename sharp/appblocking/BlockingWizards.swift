import SwiftUI
import FamilyControls
import CoreLocation
import CoreData
import MapKit  

// MARK: - Base Wizard Component
struct WizardStep<Content: View>: View {
    let step: Int
    let totalSteps: Int
    let title: String
    let subtitle: String
    let content: Content
    let canContinue: Bool
    let onBack: () -> Void
    let onContinue: () -> Void
    
    init(
        step: Int,
        totalSteps: Int,
        title: String,
        subtitle: String,
        canContinue: Bool = true,
        onBack: @escaping () -> Void,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.step = step
        self.totalSteps = totalSteps
        self.title = title
        self.subtitle = subtitle
        self.canContinue = canContinue
        self.onBack = onBack
        self.onContinue = onContinue
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        onBack()
                        DuoHaptics.lightTap()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.uwCard.opacity(0.8))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("Step \(step) of \(totalSteps)")
                        .font(.duoCaption)
                        .foregroundColor(.uwTextSecondary)
                }

                DuoProgressBar(progress: Double(step) / Double(totalSteps), height: 12)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.duoTitle)
                        .foregroundColor(.uwTextPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.duoBody)
                        .foregroundColor(.uwTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
            
            // Content
            ScrollView {
                content
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 120) // More space for the button
            }
            .frame(maxWidth: .infinity)
            
            // Footer with Continue button
            VStack {
                Button {
                    onContinue()
                    DuoHaptics.buttonTap()
                } label: {
                    Text(step == totalSteps ? "Create Block" : "Continue")
                }
                .buttonStyle(DuoPrimaryButton())
                .disabled(!canContinue)
                .opacity(canContinue ? 1.0 : 0.5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .background(
                LinearGradient(colors: [
                    Color.uwBackground.opacity(0),
                    Color.uwBackground,
                    Color.uwBackground
                ], startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.bottom)
            )
        }
        .background(ModernBackground().edgesIgnoringSafeArea(.all))
        .animation(DuoAnimation.defaultSpring, value: step)
    }
}

// MARK: - Timer Blocking Wizard
struct TimerBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var duration = 60 // minutes
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    
    let durations = [1, 15, 30, 45, 60, 90, 120, 180, 240]
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_NameAndDuration
                } else if currentStep == 2 {
                    step2_SelectApps
                } else if currentStep == 3 {
                    step3_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
    }
    
    private var step1_NameAndDuration: some View {
        WizardStep(
            step: 1,
            totalSteps: 3,
            title: "Focus Session",
            subtitle: "Give your session a name and set duration",
            canContinue: !sessionName.isEmpty,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 32) {
                DuoTextField(
                    text: $sessionName,
                    placeholder: "e.g., Deep Work",
                    icon: "pencil"
                )
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Duration")
                        .font(.duoSubheadline)
                        .foregroundColor(.uwTextPrimary)

                    DuolingoTimePicker(
                        selectedMinutes: $duration,
                        options: durations
                    )
                }
            }
        }
    }
    
    private var step2_SelectApps: some View {
        WizardStep(
            step: 2,
            totalSteps: 3,
            title: "Select Apps",
            subtitle: "Choose which apps to block during this session",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 1 },
            onContinue: { currentStep = 3 }
        ) {
            VStack(spacing: 24) {
                Button {
                    showActivityPicker = true
                    DuoHaptics.lightTap()
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.uwPrimary)
                        
                        Text("Choose Apps & Categories")
                            .font(.duoBodyBold)
                            .foregroundColor(.uwTextPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextSecondary)
                    }
                    .padding(20)
                }
                .buttonStyle(DuoCardButtonStyle())

                if !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected")
                            .font(.duoSubheadline)
                            .foregroundColor(.uwTextPrimary)

                        HStack(spacing: 12) {
                            if !activitySelection.applicationTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "app.fill")
                                    Text("\(activitySelection.applicationTokens.count) apps")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }

                            if !activitySelection.categoryTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                    Text("\(activitySelection.categoryTokens.count) categories")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var step3_Review: some View {
        WizardStep(
            step: 3,
            totalSteps: 3,
            title: "Review & Create",
            subtitle: "Check your settings before creating the block",
            onBack: { currentStep = 2 },
            onContinue: createTimerBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "timer", title: "Session Name", value: sessionName)
                ReviewRow(icon: "clock", title: "Duration", value: "\(duration) minutes")
                ReviewRow(icon: "apps.iphone", title: "Apps", value: "\(activitySelection.applicationTokens.count) apps, \(activitySelection.categoryTokens.count) categories")
            }
        }
    }
    
    private func createTimerBlock() {
        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "timer")
        
        BlockingSessionManager.shared.startTimerSession(
            duration: TimeInterval(duration * 60),
            sessionName: sessionName,
            familyControlsManager: appStateManager.familyControlsManager
        )
        
        dismiss()
    }
}

// MARK: - Schedule Blocking Wizard
struct ScheduleBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var scheduleType: ScheduleBlockingSession.ScheduleType = .daily
    @State private var startHour = 9
    @State private var startMinute = 0
    @State private var endHour = 17
    @State private var endMinute = 0
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_NameAndSchedule
                } else if currentStep == 2 {
                    step2_SelectApps
                } else if currentStep == 3 {
                    step3_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
    }
    
    private var step1_NameAndSchedule: some View {
        WizardStep(
            step: 1,
            totalSteps: 3,
            title: "Schedule Block",
            subtitle: "Set up your blocking schedule",
            canContinue: !sessionName.isEmpty,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 24) {
                DuoTextField(
                    text: $sessionName,
                    placeholder: "e.g., Work Hours",
                    icon: "pencil"
                )
                
                // Schedule type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schedule Type")
                        .font(.duoSubheadline)
                        .foregroundColor(.uwTextPrimary)
                    
                    ForEach([ScheduleBlockingSession.ScheduleType.daily, .weekdays, .weekends, .custom], id: \.self) { type in
                        ScheduleTypeButton(type: type, isSelected: scheduleType == type) {
                            scheduleType = type
                        }
                    }
                }
                .duoCard(padding: 20)
                
                // Time pickers
                HStack(spacing: 16) {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Start Time")
                            .font(.duoSubheadline)
                            .foregroundColor(.uwTextPrimary)
                        HStack {
                            Picker("Hour", selection: $startHour) {
                                ForEach(0..<24) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $startMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        .frame(height: 120)
                    }
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text("End Time")
                            .font(.duoSubheadline)
                            .foregroundColor(.uwTextPrimary)
                        HStack {
                            Picker("Hour", selection: $endHour) {
                                ForEach(0..<24) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $endMinute) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                    Text(String(format: "%02d", minute)).tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        .frame(height: 120)
                    }
                }
                .duoCard(padding: 20)
            }
        }
    }
    
    private var step2_SelectApps: some View {
        WizardStep(
            step: 2,
            totalSteps: 3,
            title: "Select Apps",
            subtitle: "Choose apps to block during this schedule",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 1 },
            onContinue: { currentStep = 3 }
        ) {
            VStack(spacing: 24) {
                Button {
                    showActivityPicker = true
                    DuoHaptics.lightTap()
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.uwPrimary)
                        
                        Text("Choose Apps & Categories")
                            .font(.duoBodyBold)
                            .foregroundColor(.uwTextPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextSecondary)
                    }
                    .padding(20)
                }
                .buttonStyle(DuoCardButtonStyle())

                if !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected")
                            .font(.duoSubheadline)
                            .foregroundColor(.uwTextPrimary)

                        HStack(spacing: 12) {
                            if !activitySelection.applicationTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "app.fill")
                                    Text("\(activitySelection.applicationTokens.count) apps")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }

                            if !activitySelection.categoryTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                    Text("\(activitySelection.categoryTokens.count) categories")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var step3_Review: some View {
        WizardStep(
            step: 3,
            totalSteps: 3,
            title: "Review & Create",
            subtitle: "Check your schedule settings",
            onBack: { currentStep = 2 },
            onContinue: createScheduleBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "calendar", title: "Name", value: sessionName)
                ReviewRow(icon: "clock", title: "Time", value: String(format: "%02d:%02d - %02d:%02d", startHour, startMinute, endHour, endMinute))
                ReviewRow(icon: "repeat", title: "Schedule", value: scheduleType.rawValue)
            }
        }
    }
    
    private func createScheduleBlock() {
        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "schedule")
        BlockingSessionManager.shared.startScheduleSession(
            name: sessionName,
            scheduleType: scheduleType,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            selectedDays: Array(selectedDays),
            familyControlsManager: appStateManager.familyControlsManager
        )
        
        
        
        dismiss()
    }
}

// MARK: - Task Blocking Wizard
struct TaskBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var selectedTasks: Set<NSManagedObjectID> = []
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskEntity.taskCreatedAt, ascending: false)],
        predicate: NSPredicate(format: "taskIsCompleted == NO")
    ) private var pendingTasks: FetchedResults<TaskEntity>
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_SelectTasks
                } else if currentStep == 2 {
                    step2_SelectApps
                } else if currentStep == 3 {
                    step3_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
    }
    
    private var step1_SelectTasks: some View {
        WizardStep(
            step: 1,
            totalSteps: 3,
            title: "Select Tasks",
            subtitle: "Choose tasks that must be completed",
            canContinue: !selectedTasks.isEmpty,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 16) {
                if pendingTasks.isEmpty {
                    Text("No pending tasks. Create tasks first.")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(40)
                } else {
                    ForEach(pendingTasks, id: \.objectID) { task in
                        TaskSelectionRow(
                            task: task,
                            isSelected: selectedTasks.contains(task.objectID)
                        ) {
                            if selectedTasks.contains(task.objectID) {
                                selectedTasks.remove(task.objectID)
                            } else {
                                selectedTasks.insert(task.objectID)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var step2_SelectApps: some View {
        WizardStep(
            step: 2,
            totalSteps: 3,
            title: "Select Apps",
            subtitle: "Apps to block until tasks complete",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 1 },
            onContinue: { currentStep = 3 }
        ) {
            VStack {
                Button {
                    showActivityPicker = true
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                        Text("Choose Apps & Categories")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(20)
                    .background(Color.appCard)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var step3_Review: some View {
        WizardStep(
            step: 3,
            totalSteps: 3,
            title: "Review & Create",
            subtitle: "Confirm your task-based block",
            onBack: { currentStep = 2 },
            onContinue: createTaskBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "checklist", title: "Tasks", value: "\(selectedTasks.count) tasks")
                ReviewRow(icon: "apps.iphone", title: "Apps", value: "\(activitySelection.applicationTokens.count) apps")
            }
        }
    }
    
    private func createTaskBlock() {
        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "task")
        let tasks = pendingTasks.filter { selectedTasks.contains($0.objectID) }
        
        BlockingSessionManager.shared.startTaskSession(
            tasks: Array(tasks),
            familyControlsManager: appStateManager.familyControlsManager,
            context: viewContext
        )
        
        
        dismiss()
    }
}

// MARK: - Location Wizard (Simplified)
struct LocationBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var triggerType: LocationBlockingSession.LocationTriggerType = .inside  // Always inside
    @State private var useCurrentLocation = true
    @State private var latitude = 37.7749
    @State private var longitude = -122.4194
    @State private var radius: Double = 200 // meters (default 200m)
    @State private var locationName = "My Location"
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_NameOnly
                } else if currentStep == 2 {
                    step2_SelectLocationWithMap
                } else if currentStep == 3 {
                    step3_SelectApps
                } else if currentStep == 4 {
                    step4_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
        .onAppear {
            // Only request if not yet determined (first time)
            if !appStateManager.locationManager.isAuthorized && !appStateManager.locationManager.isDenied {
                appStateManager.locationManager.requestAuthorization()
            }
            // Start updating location if already authorized
            if appStateManager.locationManager.isAuthorized {
                appStateManager.locationManager.startUpdatingLocation()
            }

            // Update region if current location available
            if let current = appStateManager.locationManager.currentLocation {
                latitude = current.coordinate.latitude
                longitude = current.coordinate.longitude
                region = MKCoordinateRegion(
                    center: current.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
    
    private var step1_NameOnly: some View {
        WizardStep(
            step: 1,
            totalSteps: 4,
            title: "Location Block",
            subtitle: "Block apps while you're at a specific location",
            canContinue: !sessionName.isEmpty,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 24) {
                DuoTextField(
                    text: $sessionName,
                    placeholder: "e.g., At Work",
                    icon: "pencil"
                )

                // Info cards
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.uwPurple)
                        Text("Apps will be blocked while you're inside the location area.")
                            .font(.duoBody)
                            .foregroundColor(.uwTextSecondary)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.uwPurple.opacity(0.1))
                    .cornerRadius(16)

                    // Background monitoring info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.uwAccent)
                            Text("Background Monitoring")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                        }
                        Text("Works even when app is in background with 'Always Allow' permission. If you force-quit the app, blocking will resume when you reopen it.")
                            .font(.duoSmall)
                            .foregroundColor(.uwTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.uwAccent.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var step2_SelectLocationWithMap: some View {
        WizardStep(
            step: 2,
            totalSteps: 4,
            title: "Select Location",
            subtitle: "Choose location and set radius",
            canContinue: appStateManager.locationManager.isAuthorized,
            onBack: { currentStep = 1 },
            onContinue: {
                if useCurrentLocation, let current = appStateManager.locationManager.currentLocation {
                    latitude = current.coordinate.latitude
                    longitude = current.coordinate.longitude
                }
                currentStep = 3
            }
        ) {
            VStack(spacing: 20) {
                // Location authorization status UI
                if appStateManager.locationManager.isAuthorized {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.uwSuccess)
                            Text("Location Access Granted")
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.uwSuccess.opacity(0.1))
                        .cornerRadius(12)

                        // Always Authorization recommendation
                        if !appStateManager.locationManager.isAuthorizedAlways {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.uwPurple)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Enable 'Always Allow' for Best Results")
                                            .font(.duoBodyBold)
                                            .foregroundColor(.uwTextPrimary)
                                        Text("Location blocking works in the background with 'Always Allow' permission. Without it, blocking may not work when the app is closed.")
                                            .font(.duoSmall)
                                            .foregroundColor(.uwTextSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                }

                                Button {
                                    appStateManager.locationManager.requestAlwaysAuthorization()
                                } label: {
                                    Text("Request 'Always Allow'")
                                }
                                .buttonStyle(Duo3DButtonStyle(color: .uwPurple))
                            }
                            .padding(16)
                            .background(Color.uwPurple.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                } else if appStateManager.locationManager.isDenied {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.uwError)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Location Access Denied")
                                    .font(.duoBodyBold)
                                    .foregroundColor(.uwTextPrimary)
                                Text("Please enable in Settings to continue")
                                    .font(.duoCaption)
                                    .foregroundColor(.uwTextSecondary)
                            }
                            Spacer()
                        }

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open Settings")
                        }
                        .buttonStyle(DuoDangerButton())
                    }
                    .padding(16)
                    .background(Color.uwError.opacity(0.1))
                    .cornerRadius(16)
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.uwTextSecondary)
                        Text("Requesting location access...")
                            .font(.duoCaption)
                            .foregroundColor(.uwTextSecondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.uwSurface)
                    .cornerRadius(12)
                }

                // Map view with radius circle
                if appStateManager.locationManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location & Radius")
                            .font(.duoHeadline)
                            .foregroundColor(.uwTextPrimary)

                        LocationMapView(
                            coordinate: $region.center,
                            radius: $radius,
                            region: $region
                        )
                        .frame(height: 250)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.uwTextTertiary, lineWidth: 1)
                        )
                    }
                    .duoCard(padding: 20)

                    // Radius control
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Radius")
                                .font(.duoSubheadline)
                            Spacer()
                            Text("\(Int(radius))m")
                                .font(.duoSubheadline)
                                .foregroundColor(.uwTextPrimary)
                        }

                        HStack(spacing: 12) {
                            ForEach([100, 200, 500, 1000, 2000], id: \.self) { radiusValue in
                                Button {
                                    radius = Double(radiusValue)
                                } label: {
                                    Text("\(radiusValue)m")
                                }
                                .buttonStyle(DuoPillButtonStyle(isSelected: radius == Double(radiusValue), tint: .uwPurple))
                            }
                        }

                        // Battery info
                        HStack(spacing: 6) {
                            Image(systemName: "battery.100")
                                .font(.system(size: 12))
                            Text("Minimum 100m for battery efficiency. Works in Low Power Mode.")
                                .font(.duoSmall)
                                .foregroundColor(.uwTextSecondary)
                        }
                    }
                    .duoCard(padding: 20)


                    // Use current location button
                    if let current = appStateManager.locationManager.currentLocation {
                        Button {
                            latitude = current.coordinate.latitude
                            longitude = current.coordinate.longitude
                            region = MKCoordinateRegion(
                                center: current.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Use Current Location")
                            }
                        }
                        .buttonStyle(DuoSecondaryButtonStyle())
                    }
                }
            }
        }
    }
    
    private var step3_SelectApps: some View {
        WizardStep(
            step: 3,
            totalSteps: 4,
            title: "Select Apps",
            subtitle: "Apps to block at this location",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 2 },
            onContinue: { currentStep = 4 }
        ) {
            VStack(spacing: 24) {
                Button {
                    showActivityPicker = true
                    DuoHaptics.lightTap()
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.uwPrimary)
                        
                        Text("Choose Apps & Categories")
                            .font(.duoBodyBold)
                            .foregroundColor(.uwTextPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.uwTextSecondary)
                    }
                    .padding(20)
                }
                .buttonStyle(DuoCardButtonStyle())

                if !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected")
                            .font(.duoSubheadline)
                            .foregroundColor(.uwTextPrimary)

                        HStack(spacing: 12) {
                            if !activitySelection.applicationTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "app.fill")
                                    Text("\(activitySelection.applicationTokens.count) apps")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }

                            if !activitySelection.categoryTokens.isEmpty {
                                HStack(spacing: 6) {
                                    Image(systemName: "folder.fill")
                                    Text("\(activitySelection.categoryTokens.count) categories")
                                }
                                .font(.duoCaption)
                                .foregroundColor(.uwTextPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.uwSurface)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var step4_Review: some View {
        WizardStep(
            step: 4,
            totalSteps: 4,
            title: "Review & Create",
            subtitle: "Confirm your location block",
            onBack: { currentStep = 3 },
            onContinue: createLocationBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "location.fill", title: "Name", value: sessionName)
                ReviewRow(icon: "arrow.triangle.swap", title: "Trigger", value: triggerType.rawValue)
                ReviewRow(icon: "mappin.circle", title: "Location", value: locationName)
                ReviewRow(icon: "circle.dashed", title: "Radius", value: "\(Int(radius))m")
            }
        }
    }
    
    private func createLocationBlock() {
        // Use the region center as the actual coordinate
        let finalCoordinate = region.center

        let session = LocationBlockingSession(
            id: UUID(),
            name: sessionName,
            startTime: Date(),
            isActive: true,
            latitude: finalCoordinate.latitude,
            longitude: finalCoordinate.longitude,
            radius: radius,
            locationName: sessionName, // Use session name as location name
            triggerType: triggerType
        )

        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "location")

        // Start the blocking session first (sets up observers)
        BlockingSessionManager.shared.startLocationSession(
            session: session,
            familyControlsManager: appStateManager.familyControlsManager,
            locationManager: appStateManager.locationManager
        )

        // Start monitoring the region (will check if already inside and trigger blocking)
        appStateManager.locationManager.startMonitoring(
            coordinate: session.coordinate,
            radius: radius,
            identifier: session.id.uuidString
        )

        dismiss()
    }
}

struct LocationTriggerButton: View {
    let type: LocationBlockingSession.LocationTriggerType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color(red: 0.7, green: 0.4, blue: 0.9) : .textSecondary)
                Text(type.rawValue)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(16)
            .background(Color.appCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(red: 0.7, green: 0.4, blue: 0.9) : Color.uwTextTertiary, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Steps Wizard (Simplified)
struct StepsBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var targetSteps = 10000
    @State private var resetDaily = true
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    
    let stepOptions = [3, 5715, 7500, 10000, 12500, 15000, 20000]
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_NameAndGoal
                } else if currentStep == 2 {
                    step2_SelectApps
                } else if currentStep == 3 {
                    step3_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
        .onAppear {
            Task {
                // First check current status by trying to fetch steps
                await appStateManager.stepsManager.checkAuthorization()

                // If not authorized, request authorization (will show popup if not determined)
                if !appStateManager.stepsManager.isAuthorized {
                    try? await appStateManager.stepsManager.requestAuthorization()
                }
            }
        }
    }
    
    private var step1_NameAndGoal: some View {
        WizardStep(
            step: 1,
            totalSteps: 3,
            title: "Steps Goal Block",
            subtitle: "Set your daily step target",
            canContinue: !sessionName.isEmpty && appStateManager.stepsManager.isAuthorized,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Block Name")
                        .font(.system(size: 16, weight: .semibold))
                    TextField("e.g., Daily Steps", text: $sessionName)
                        .padding(16)
                        .background(Color.appCard)
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Step Goal")
                        .font(.system(size: 16, weight: .semibold))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(stepOptions, id: \.self) { steps in
                            StepGoalButton(steps: steps, isSelected: targetSteps == steps) {
                                targetSteps = steps
                            }
                        }
                    }
                }

                Toggle("Reset Daily", isOn: $resetDaily)
                    .padding(16)
                    .background(Color.appCard)
                    .cornerRadius(12)

                // Authorization status UI
                if appStateManager.stepsManager.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("HealthKit Connected")
                            .font(.caption)
                        Spacer()
                        Text("\(appStateManager.stepsManager.todaySteps) steps today")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(12)
                    .background(Color.accentGreen.opacity(0.1))
                    .cornerRadius(8)
                } else if appStateManager.stepsManager.authorizationDenied {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HealthKit Access Denied")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Please enable in Settings to continue")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Open Settings")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.accentOrange)
                            .cornerRadius(10)
                        }
                    }
                    .padding(12)
                    .background(Color.accentOrange.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Requesting HealthKit access...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.appCard)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var step2_SelectApps: some View {
        WizardStep(
            step: 2,
            totalSteps: 3,
            title: "Select Apps",
            subtitle: "Apps to unlock after reaching goal",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 1 },
            onContinue: { currentStep = 3 }
        ) {
            VStack {
                Button {
                    showActivityPicker = true
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                        Text("Choose Apps & Categories")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(20)
                    .background(Color.appCard)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var step3_Review: some View {
        WizardStep(
            step: 3,
            totalSteps: 3,
            title: "Review & Create",
            subtitle: "Confirm your steps goal block",
            onBack: { currentStep = 2 },
            onContinue: createStepsBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "figure.walk", title: "Name", value: sessionName)
                ReviewRow(icon: "target", title: "Goal", value: "\(targetSteps) steps")
                ReviewRow(icon: "arrow.clockwise", title: "Reset", value: resetDaily ? "Daily" : "Manual")
            }
        }
    }
    
    private func createStepsBlock() {
        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "steps")
        BlockingSessionManager.shared.startStepsSession(
            name: sessionName,
            targetSteps: targetSteps,
            resetDaily: resetDaily,
            familyControlsManager: appStateManager.familyControlsManager,
            stepsManager: appStateManager.stepsManager
        )
        
        
        
        dismiss()
    }
}

struct StepGoalButton: View {
    let steps: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(steps / 1000)K")
                    .font(.system(size: 20, weight: .bold))
                Text("steps")
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .uwTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    // Solid 3D shadow
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.uwPrimaryDark : Color.uwCardShadow)
                        .offset(y: 3)

                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.uwPrimary : Color.uwCard)
                }
            )
        }
    }
}

// MARK: - Sleep Wizard (Simplified)
struct SleepBlockingWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var currentStep = 1
    @State private var sessionName = ""
    @State private var bedtimeHour = 22
    @State private var bedtimeMinute = 0
    @State private var wakeupHour = 7
    @State private var wakeupMinute = 0
    @State private var selectedDays: Set<Int> = Set([1, 2, 3, 4, 5, 6, 7]) // All days
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false
    
    let days = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if currentStep == 1 {
                    step1_SleepSchedule
                } else if currentStep == 2 {
                    step2_SelectApps
                } else if currentStep == 3 {
                    step3_Review
                }
            }
            .navigationBarHidden(true)
        }
        .familyActivityPicker(isPresented: $showActivityPicker, selection: $activitySelection)
    }
    
    private var step1_SleepSchedule: some View {
        WizardStep(
            step: 1,
            totalSteps: 3,
            title: "Sleep Schedule",
            subtitle: "Set your bedtime and wake time",
            canContinue: !sessionName.isEmpty,
            onBack: { dismiss() },
            onContinue: { currentStep = 2 }
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule Name")
                        .font(.system(size: 16, weight: .semibold))
                    TextField("e.g., Sleep Mode", text: $sessionName)
                        .padding(16)
                        .background(Color.appCard)
                        .cornerRadius(12)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bedtime")
                            .font(.system(size: 14, weight: .semibold))
                        HStack {
                            Picker("Hour", selection: $bedtimeHour) {
                                ForEach(0..<24) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $bedtimeMinute) {
                                ForEach(0..<60, id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Wake Time")
                            .font(.system(size: 14, weight: .semibold))
                        HStack {
                            Picker("Hour", selection: $wakeupHour) {
                                ForEach(0..<24) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            
                            Text(":")
                            
                            Picker("Minute", selection: $wakeupMinute) {
                                ForEach(0..<60, id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                        }
                    }
                }
                .frame(height: 150)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Days")
                        .font(.system(size: 16, weight: .semibold))
                    
                    HStack(spacing: 8) {
                        ForEach(days, id: \.0) { day in
                            DayButton(
                                day: day.1,
                                isSelected: selectedDays.contains(day.0)
                            ) {
                                if selectedDays.contains(day.0) {
                                    selectedDays.remove(day.0)
                                } else {
                                    selectedDays.insert(day.0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var step2_SelectApps: some View {
        WizardStep(
            step: 2,
            totalSteps: 3,
            title: "Select Apps",
            subtitle: "Apps to block during sleep hours",
            canContinue: !activitySelection.applicationTokens.isEmpty || !activitySelection.categoryTokens.isEmpty,
            onBack: { currentStep = 1 },
            onContinue: { currentStep = 3 }
        ) {
            VStack {
                Button {
                    showActivityPicker = true
                } label: {
                    HStack {
                        Image(systemName: "apps.iphone")
                        Text("Choose Apps & Categories")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding(20)
                    .background(Color.appCard)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var step3_Review: some View {
        WizardStep(
            step: 3,
            totalSteps: 3,
            title: "Review & Create",
            subtitle: "Confirm your sleep schedule",
            onBack: { currentStep = 2 },
            onContinue: createSleepBlock
        ) {
            VStack(spacing: 16) {
                ReviewRow(icon: "moon.stars.fill", title: "Name", value: sessionName)
                ReviewRow(icon: "bed.double.fill", title: "Bedtime", value: String(format: "%02d:%02d", bedtimeHour, bedtimeMinute))
                ReviewRow(icon: "sunrise.fill", title: "Wake Time", value: String(format: "%02d:%02d", wakeupHour, wakeupMinute))
                ReviewRow(icon: "calendar", title: "Active Days", value: "\(selectedDays.count) days")
            }
        }
    }
    
    private func createSleepBlock() {
        BlockingSessionManager.shared.setSessionSelection(activitySelection, for: "sleep")
        BlockingSessionManager.shared.startSleepSession(
            name: sessionName,
            bedtimeHour: bedtimeHour,
            bedtimeMinute: bedtimeMinute,
            wakeupHour: wakeupHour,
            wakeupMinute: wakeupMinute,
            enabledDays: Array(selectedDays),
            familyControlsManager: appStateManager.familyControlsManager
        )
        
        
        
        dismiss()
    }
}

struct DayButton: View {
    let day: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(day)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : .uwTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    ZStack {
                        // Solid 3D shadow
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.uwPrimaryDark : Color.uwCardShadow)
                            .offset(y: 3)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color.uwPrimary : Color.uwCard)
                    }
                )
        }
    }
}

// MARK: - Helper Components
struct DurationButton: View {
    let duration: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.system(size: 20, weight: .bold))
                Text("min")
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .uwTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    // Solid 3D shadow
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.uwPrimaryDark : Color.uwCardShadow)
                        .offset(y: 3)

                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.uwPrimary : Color.uwCard)
                }
            )
        }
    }
}

struct ScheduleTypeButton: View {
    let type: ScheduleBlockingSession.ScheduleType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            DuoHaptics.lightTap()
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .uwPrimary : .uwTextSecondary)
                Text(type.rawValue)
                    .font(.duoBody)
                    .foregroundColor(.uwTextPrimary)
                Spacer()
            }
            .padding(16)
            .background(Color.uwSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.uwPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(DuoAnimation.buttonPress, value: isSelected)
    }
}

struct ReviewRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.uwPrimary)
                .frame(width: 24)

            Text(title)
                .font(.duoBody)
                .foregroundColor(.uwTextSecondary)

            Spacer()

            Text(value)
                .font(.duoBodyBold)
                .foregroundColor(.uwTextPrimary)
        }
        .padding(20)
        .background(Color.uwSurface)
        .cornerRadius(16)
    }
}

struct TaskSelectionRow: View {
    let task: TaskEntity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            DuoHaptics.lightTap()
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .uwPrimary : .uwTextSecondary)
                Text(task.taskTitle ?? "Untitled")
                    .font(.duoBody)
                    .foregroundColor(.uwTextPrimary)
                Spacer()
            }
            .padding(16)
            .background(Color.uwSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.uwPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .animation(DuoAnimation.buttonPress, value: isSelected)
    }
}

// MARK: - Location Map View
struct LocationMapView: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var radius: Double
    @Binding var region: MKCoordinateRegion

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [MapLocation(coordinate: coordinate)]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                ZStack {
                    // Radius circle
                    Circle()
                        .fill(Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.2))
                        .frame(width: radiusToPoints(radius, region: region),
                               height: radiusToPoints(radius, region: region))

                    Circle()
                        .stroke(Color(red: 0.7, green: 0.4, blue: 0.9), lineWidth: 2)
                        .frame(width: radiusToPoints(radius, region: region),
                               height: radiusToPoints(radius, region: region))

                    // Center pin
                    Circle()
                        .fill(Color(red: 0.7, green: 0.4, blue: 0.9))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
            }
        }
    }

    // Convert radius in meters to points on screen (approximation)
    private func radiusToPoints(_ radiusInMeters: Double, region: MKCoordinateRegion) -> CGFloat {
        let metersPerDegree = 111000.0 // Approximate meters per degree of latitude
        let degreesForRadius = radiusInMeters / metersPerDegree
        let screenWidth = UIScreen.main.bounds.width - 48 // Accounting for padding
        let pointsPerDegree = screenWidth / region.span.latitudeDelta
        return CGFloat(degreesForRadius * pointsPerDegree) * 2
    }
}

struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
