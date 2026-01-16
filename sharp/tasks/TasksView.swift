import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appStateManager: AppStateManager

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TaskEntity.taskIsCompleted, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.taskCreatedAt, ascending: false)
        ],
        animation: .default)
    private var tasks: FetchedResults<TaskEntity>

    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var showUnlockAnimation = false
    @State private var selectedDate = Date()
    @State private var newTaskScheduledDate = Date()
    @State private var newTaskIsRecurring = false
    @State private var newTaskRecurrencePattern: AddTaskView.RecurrencePattern = .daily
    @State private var newTaskSelectedDays: Set<Int> = []

    // MARK: - Computed Properties
    var activeBlockingTasks: [TaskEntity] {
        guard let session = appStateManager.activeTaskSession else { return [] }
        return tasks.filter { task in
            guard let taskId = task.taskId else { return false }
            return session.taskIds.contains(taskId)
        }
    }

    var regularTasks: [TaskEntity] {
        guard let session = appStateManager.activeTaskSession else { return tasksForSelectedDate }
        return tasksForSelectedDate.filter { task in
            guard let taskId = task.taskId else { return true }
            return !session.taskIds.contains(taskId)
        }
    }

    var tasksForSelectedDate: [TaskEntity] {
        let calendar = Calendar.current
        let selectedWeekday = calendar.component(.weekday, from: selectedDate)

        return tasks.filter { task in
            if let scheduledDate = task.value(forKey: "taskScheduledDate") as? Date {
                if let pattern = task.value(forKey: "taskRecurrencePattern") as? String,
                   let daysString = task.value(forKey: "taskRecurrenceDays") as? String {
                    let recurringDays = daysString.split(separator: ",").compactMap { Int($0) }
                    return recurringDays.contains(selectedWeekday)
                } else {
                    return calendar.isDate(scheduledDate, inSameDayAs: selectedDate)
                }
            }
            guard let taskDate = task.taskCreatedAt else { return false }
            return calendar.isDate(taskDate, inSameDayAs: selectedDate)
        }
    }

    var completedTasks: [TaskEntity] { regularTasks.filter { $0.taskIsCompleted } }
    var pendingTasks: [TaskEntity] { regularTasks.filter { !$0.taskIsCompleted } }
    var completedBlockingTasks: [TaskEntity] { activeBlockingTasks.filter { $0.taskIsCompleted } }
    var pendingBlockingTasks: [TaskEntity] { activeBlockingTasks.filter { !$0.taskIsCompleted } }
    var allBlockingTasksCompleted: Bool { !activeBlockingTasks.isEmpty && activeBlockingTasks.allSatisfy { $0.taskIsCompleted } }

    var completionPercentage: Double {
        let totalTasks = tasksForSelectedDate.count
        guard totalTasks > 0 else { return 0 }
        let completed = tasksForSelectedDate.filter { $0.taskIsCompleted }.count
        return Double(completed) / Double(totalTasks) * 100
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            ModernBackground()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with progress and week selector
                    VStack(spacing: 0) {
                        progressSection
                        headerSection
                    }
                    .duoCard(padding: 0, cornerRadius: 20)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Unlock celebration
                    if showUnlockAnimation {
                        UnlockCelebrationView()
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Task sections
                    VStack(spacing: 16) {
                        if !activeBlockingTasks.isEmpty {
                            blockingTasksSection
                        }

                        if !pendingTasks.isEmpty {
                            taskSection(tasks: pendingTasks)
                        }

                        if !completedTasks.isEmpty {
                            completedTasksSection
                        }

                        if tasksForSelectedDate.isEmpty {
                            emptyStateSection
                        }
                    }
                    .padding(.horizontal, 20)

                    Color.clear.frame(height: 100)
                }
            }

            // Floating Add Button
            floatingAddButton
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(
                newTaskTitle: $newTaskTitle,
                selectedTaskDate: selectedDate,
                isTaskRecurring: newTaskIsRecurring,
                taskRecurrencePattern: newTaskRecurrencePattern,
                selectedDays: newTaskSelectedDays
            ) { scheduledDate, isRecurring, pattern, days in
                newTaskScheduledDate = scheduledDate
                newTaskIsRecurring = isRecurring
                newTaskRecurrencePattern = pattern
                newTaskSelectedDays = days
                addTask()
            }
        }
        .onReceive(appStateManager.$activeTaskSession) { session in
            if let session = session {
                checkForAutoUnlock(session: session)
            }
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(Int(completionPercentage))%")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)

                Spacer()

                let totalTasks = tasksForSelectedDate.count
                let completedCount = tasksForSelectedDate.filter { $0.taskIsCompleted }.count
                Text("\(completedCount)/\(totalTasks) tasks")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.uwTextSecondary)
            }

            // Progress bar with golden yellow accent
            DuoProgressBar(
                progress: completionPercentage / 100,
                height: 12,
                backgroundColor: Color.uwTextTertiary.opacity(0.3),
                fillColor: completionPercentage >= 100 ? .uwSuccess : .uwAccent
            )
        }
        .padding(20)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Text(getSelectedDayNumber())
                    .font(.system(size: 56, weight: .heavy))
                    .foregroundColor(.uwTextPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(getSelectedDayName())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.uwTextPrimary)

                    Text(getSelectedMonthYear())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.uwTextSecondary)
                }
                .padding(.top, 8)

                Spacer()

                // Today button
                Button {
                    withAnimation(DuoAnimation.tabSwitch) {
                        selectedDate = Date()
                    }
                    DuoHaptics.lightTap()
                } label: {
                    Text("Today")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.uwPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.uwPrimary.opacity(0.15))
                        )
                }
                .padding(.top, 10)
            }

            weekDaySelector
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Week Day Selector
    private var weekDaySelector: some View {
        HStack(spacing: 4) {
            ForEach(getWeekDays(), id: \.date) { day in
                Button {
                    withAnimation(DuoAnimation.tabSwitch) {
                        selectedDate = day.date
                    }
                    DuoHaptics.selection()
                } label: {
                    VStack(spacing: 6) {
                        Text(day.dayLetter)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isSelectedDate(day.date) ? .white : .uwTextSecondary)

                        Text("\(day.dayNumber)")
                            .font(.system(size: 16, weight: isSelectedDate(day.date) ? .heavy : .medium))
                            .foregroundColor(isSelectedDate(day.date) ? .white : .uwTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if isSelectedDate(day.date) {
                                // 3D pill effect
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.uwPrimaryDark)
                                    .offset(y: 3)

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.uwPrimary)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Task Section
    @ViewBuilder
    private func taskSection(tasks: [TaskEntity]) -> some View {
        VStack(spacing: 12) {
            ForEach(tasks, id: \.objectID) { task in
                DuoTaskRow(task: task, isBlocking: false, onToggle: {
                    toggleTask(task)
                }, onDelete: {
                    deleteTask(task)
                })
            }
        }
    }

    // MARK: - Completed Tasks Section
    private var completedTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.uwTextSecondary)
                .padding(.leading, 4)

            ForEach(completedTasks, id: \.objectID) { task in
                DuoTaskRow(task: task, isBlocking: false, onToggle: {
                    toggleTask(task)
                }, onDelete: {
                    deleteTask(task)
                })
                .opacity(0.6)
            }
        }
    }

    // MARK: - Blocking Tasks Section
    private var blockingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.uwWarning)

                    Text("Focus Session")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.uwTextPrimary)
                }

                Spacer()

                if allBlockingTasksCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.uwSuccess)
                        Text("Ready!")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.uwSuccess)
                    }
                } else {
                    Text("\(completedBlockingTasks.count)/\(activeBlockingTasks.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.uwWarning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.uwWarning.opacity(0.2))
                        )
                }
            }

            VStack(spacing: 12) {
                ForEach(activeBlockingTasks, id: \.objectID) { task in
                    DuoTaskRow(
                        task: task,
                        isBlocking: true,
                        onToggle: {
                            toggleTask(task)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                checkForAutoUnlock()
                            }
                        },
                        onDelete: { }
                    )
                }

                if allBlockingTasksCompleted {
                    Button {
                        manualUnlock()
                    } label: {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("Unlock Apps")
                                .font(.system(size: 17, weight: .heavy))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(DuoSuccessButton())
                }

                Button {
                    BlockingSessionManager.shared.endTaskSession(familyControlsManager: appStateManager.familyControlsManager)
                } label: {
                    HStack {
                        Image(systemName: "stop.circle")
                            .font(.system(size: 14))
                        Text("Force End Session")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.uwError)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.uwError.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .duoCard()
    }

    // MARK: - Empty State
    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.uwTextTertiary)

            Text("No Tasks Yet")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.uwTextPrimary)

            Text("Add your first task to start tracking your productivity!")
                .font(.system(size: 16))
                .foregroundColor(.uwTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Add Your First Task") {
                showingAddTask = true
                DuoHaptics.buttonTap()
            }
            .buttonStyle(DuoPrimaryButton())
            .padding(.horizontal, 40)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .duoCard()
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                DuoFloatingActionButton {
                    showingAddTask = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Helper Methods
    private func getSelectedDayNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: selectedDate)
    }

    private func getSelectedDayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: selectedDate)
    }

    private func getSelectedMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private func isSelectedDate(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    private struct WeekDay {
        let date: Date
        let dayLetter: String
        let dayNumber: Int
        let isToday: Bool
    }

    private func getWeekDays() -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEEE"
            let dayLetter = formatter.string(from: date)
            let dayNumber = calendar.component(.day, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)

            return WeekDay(date: date, dayLetter: String(dayLetter.prefix(1)), dayNumber: dayNumber, isToday: isToday)
        }
    }

    // MARK: - Task Management
    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        withAnimation {
            let newTask = TaskEntity(context: viewContext)
            newTask.taskId = UUID()
            newTask.taskTitle = newTaskTitle.trimmingCharacters(in: .whitespaces)
            newTask.taskIsCompleted = false
            newTask.taskCreatedAt = newTaskScheduledDate

            if newTask.entity.attributesByName["taskScheduledDate"] != nil {
                newTask.setValue(newTaskScheduledDate, forKey: "taskScheduledDate")
            }

            if newTaskIsRecurring {
                if newTask.entity.attributesByName["taskRecurrencePattern"] != nil {
                    newTask.setValue(newTaskRecurrencePattern.rawValue, forKey: "taskRecurrencePattern")
                }
                if newTask.entity.attributesByName["taskRecurrenceDays"] != nil {
                    let daysString: String
                    if newTaskRecurrencePattern == .specificDays && !newTaskSelectedDays.isEmpty {
                        daysString = newTaskSelectedDays.sorted().map { String($0) }.joined(separator: ",")
                    } else if newTaskRecurrencePattern == .daily {
                        daysString = "1,2,3,4,5,6,7"
                    } else {
                        daysString = ""
                    }
                    newTask.setValue(daysString, forKey: "taskRecurrenceDays")
                }
            }

            saveContext()
            newTaskTitle = ""
            showingAddTask = false
        }
    }

    private func toggleTask(_ task: TaskEntity) {
        withAnimation(DuoAnimation.checkboxPop) {
            task.taskIsCompleted.toggle()
            task.taskCompletedAt = task.taskIsCompleted ? Date() : nil
            saveContext()
            appStateManager.handleTaskCompletion(context: viewContext)
        }
    }

    private func deleteTask(_ task: TaskEntity) {
        withAnimation {
            viewContext.delete(task)
            saveContext()
        }
    }

    private func checkForAutoUnlock(session: TaskBlockingSession? = nil) {
        let currentSession = session ?? appStateManager.activeTaskSession
        guard let taskSession = currentSession else { return }

        let sessionTasks = tasks.filter { task in
            guard let taskId = task.taskId else { return false }
            return taskSession.taskIds.contains(taskId)
        }

        let completedCount = sessionTasks.filter { $0.taskIsCompleted }.count
        let totalCount = sessionTasks.count

        if completedCount == totalCount && totalCount > 0 {
            withAnimation {
                showUnlockAnimation = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                BlockingSessionManager.shared.endTaskSession(familyControlsManager: appStateManager.familyControlsManager)
                withAnimation {
                    showUnlockAnimation = false
                }
                DuoHaptics.success()
            }
        }
    }

    private func manualUnlock() {
        BlockingSessionManager.shared.endTaskSession(familyControlsManager: appStateManager.familyControlsManager)
        DuoHaptics.success()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// MARK: - Duolingo-Style Task Row
struct DuoTaskRow: View {
    let task: TaskEntity
    let isBlocking: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showCelebration = false
    @State private var checkboxScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                Text(task.taskTitle ?? "Untitled Task")
                    .font(.system(size: 16, weight: task.taskIsCompleted ? .medium : .bold))
                    .foregroundColor(task.taskIsCompleted ? .uwTextSecondary : .uwTextPrimary)
                    .strikethrough(task.taskIsCompleted, color: .uwTextSecondary)

                if isBlocking {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.uwWarning)
                }

                Spacer()

                // Checkbox
                Button {
                    if !task.taskIsCompleted {
                        DuoHaptics.success()
                        showCelebration = true
                        withAnimation(DuoAnimation.checkboxPop) {
                            checkboxScale = 1.3
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(DuoAnimation.checkboxPop) {
                                checkboxScale = 1.0
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showCelebration = false
                        }
                    } else {
                        DuoHaptics.lightTap()
                    }
                    onToggle()
                } label: {
                    ZStack {
                        if task.taskIsCompleted {
                            // Shadow for checked state
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.uwPrimaryDark)
                                .frame(width: 32, height: 32)
                                .offset(y: 2)
                        }

                        RoundedRectangle(cornerRadius: 8)
                            .fill(task.taskIsCompleted ? Color.uwPrimary : Color.uwCard)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(task.taskIsCompleted ? Color.clear : Color.uwTextTertiary, lineWidth: 2)
                            )

                        if task.taskIsCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(checkboxScale)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.1))
                        .offset(y: 3)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.uwCard)
                }
            )
            .scaleEffect(task.taskIsCompleted ? 0.98 : 1.0)

            if showCelebration {
                EnhancedTaskConfetti()
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Floating Action Button
struct DuoFloatingActionButton: View {
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            onTap()
            DuoHaptics.buttonTap()
        }) {
            ZStack {
                // Shadow layer
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 64, height: 64)
                    .offset(y: isPressed ? 0 : 4)

                // Main button
                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 64, height: 64)
                    .offset(y: isPressed ? 3 : 0)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .offset(y: isPressed ? 3 : 0)
                    )

                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
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

// MARK: - Unlock Celebration View
struct UnlockCelebrationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 60))
                .foregroundColor(.uwSuccess)
                .scaleEffect(scale)

            Text("All Tasks Complete!")
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.uwSuccess)

            Text("Apps are being unlocked...")
                .font(.system(size: 15))
                .foregroundColor(.uwTextSecondary)
        }
        .padding(30)
        .background(
            ZStack {
                // Solid shadow in success color for celebration
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.uwSuccess.darker(by: 0.3))
                    .offset(y: 6)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.uwCard)
            }
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(DuoAnimation.celebration) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 2).delay(1)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Binding var newTaskTitle: String
    let selectedTaskDate: Date
    let isTaskRecurring: Bool
    let taskRecurrencePattern: RecurrencePattern
    let selectedDays: Set<Int>
    let onAdd: (Date, Bool, RecurrencePattern, Set<Int>) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var localSelectedDate: Date
    @State private var localIsRecurring: Bool
    @State private var localRecurrencePattern: RecurrencePattern
    @State private var localSelectedDays: Set<Int> = []

    enum RecurrencePattern: String, CaseIterable {
        case daily = "Daily"
        case specificDays = "Specific Days"
    }

    init(newTaskTitle: Binding<String>, selectedTaskDate: Date, isTaskRecurring: Bool, taskRecurrencePattern: RecurrencePattern, selectedDays: Set<Int>, onAdd: @escaping (Date, Bool, RecurrencePattern, Set<Int>) -> Void) {
        self._newTaskTitle = newTaskTitle
        self.selectedTaskDate = selectedTaskDate
        self.isTaskRecurring = isTaskRecurring
        self.taskRecurrencePattern = taskRecurrencePattern
        self.selectedDays = selectedDays
        self.onAdd = onAdd
        self._localSelectedDate = State(initialValue: selectedTaskDate)
        self._localIsRecurring = State(initialValue: isTaskRecurring)
        self._localRecurrencePattern = State(initialValue: taskRecurrencePattern)
        self._localSelectedDays = State(initialValue: selectedDays)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.uwBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Task Title
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Task Title")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.uwTextPrimary)

                            TextField("Enter task description...", text: $newTaskTitle, axis: .vertical)
                                .font(.system(size: 16))
                                .foregroundColor(.uwTextPrimary)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.uwCard)
                                )
                                .lineLimit(3...6)
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.uwTextPrimary)

                            DatePicker("", selection: $localSelectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }

                        // Recurring
                        VStack(alignment: .leading, spacing: 16) {
                            Toggle(isOn: $localIsRecurring) {
                                Text("Recurring Task")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.uwTextPrimary)
                            }
                            .tint(.uwPrimary)

                            if localIsRecurring {
                                Picker("Recurrence", selection: $localRecurrencePattern) {
                                    ForEach(RecurrencePattern.allCases, id: \.self) { pattern in
                                        Text(pattern.rawValue).tag(pattern)
                                    }
                                }
                                .pickerStyle(.segmented)

                                if localRecurrencePattern == .specificDays {
                                    daySelectionGrid
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.uwTextSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onAdd(localSelectedDate, localIsRecurring, localRecurrencePattern, localSelectedDays)
                        DuoHaptics.buttonTap()
                    } label: {
                        Text("Add")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty ? .uwTextTertiary : .uwPrimary)
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var daySelectionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Days")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.uwTextSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(1...7, id: \.self) { day in
                    RecurringDayButton(
                        day: day,
                        isSelected: localSelectedDays.contains(day),
                        onTap: {
                            if localSelectedDays.contains(day) {
                                localSelectedDays.remove(day)
                            } else {
                                localSelectedDays.insert(day)
                            }
                            DuoHaptics.selection()
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Recurring Day Button
struct RecurringDayButton: View {
    let day: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var dayLetter: String {
        switch day {
        case 1: return "S"
        case 2: return "M"
        case 3: return "T"
        case 4: return "W"
        case 5: return "T"
        case 6: return "F"
        case 7: return "S"
        default: return ""
        }
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.uwPrimaryDark)
                        .frame(width: 44, height: 44)
                        .offset(y: 2)
                }

                Circle()
                    .fill(isSelected ? Color.uwPrimary : Color.uwCard)
                    .frame(width: 44, height: 44)

                Text(dayLetter)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .uwTextPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task Confetti
struct EnhancedTaskConfetti: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<25) { index in
                ConfettiPiece(index: index, animate: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let animate: Bool

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1.0

    private let colors: [Color] = [
        .uwSuccess, .uwAccent, .uwPurple,
        .uwPrimary, .uwWarning, .uwError
    ]

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colors[index % colors.count])
            .frame(width: 8, height: 12)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                let angle = Double(index) * (360.0 / 25.0)
                let initialRadius: CGFloat = 20
                let fallDistance: CGFloat = CGFloat.random(in: 80...150)
                let horizontalDrift: CGFloat = CGFloat.random(in: -40...40)
                let rotations: Double = Double.random(in: 2...6)
                let delay = Double(index) * 0.02

                withAnimation(.easeOut(duration: 2.0).delay(delay)) {
                    yOffset = fallDistance
                    xOffset = cos(angle * .pi / 180) * initialRadius + horizontalDrift
                    rotation = rotations * 360
                    opacity = 0
                }
            }
    }
}

// MARK: - Legacy Compatibility
struct ModernTaskRow: View {
    let task: TaskEntity
    let isBlocking: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        DuoTaskRow(task: task, isBlocking: isBlocking, onToggle: onToggle, onDelete: onDelete)
    }
}

struct TaskRow: View {
    let task: TaskEntity
    let isBlocking: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        DuoTaskRow(task: task, isBlocking: isBlocking, onToggle: onToggle, onDelete: onDelete)
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppStateManager())
}
