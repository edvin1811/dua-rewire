# How to Add Recurring Tasks to CoreData

## Step 1: Update CoreData Model in Xcode

1. Open `sharp.xcodeproj` in Xcode
2. Navigate to `sharp/resources/ScreenTimeApp.xcdatamodeld`
3. Click on `TaskEntity` in the left panel
4. In the Attributes section, click the **"+"** button to add new attributes

Add these 3 new attributes:

| Attribute Name | Type | Optional | Description |
|----------------|------|----------|-------------|
| `taskScheduledDate` | Date | YES | The date when the task is scheduled for |
| `taskRecurrencePattern` | String | YES | Pattern: "daily", "weekly", or "monthly" |
| `taskRecurrenceEndDate` | Date | YES | When the recurring task should stop (optional) |

## Step 2: Update the addTask() function

Once you've added the attributes to CoreData, uncomment and complete this code in `TasksView.swift` (around line 725):

```swift
private func addTask() {
    guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }

    withAnimation {
        let newTask = TaskEntity(context: viewContext)
        newTask.taskId = UUID()
        newTask.taskTitle = newTaskTitle.trimmingCharacters(in: .whitespaces)
        newTask.taskIsCompleted = false
        newTask.taskCreatedAt = Date()

        // NOW UNCOMMENT THESE LINES:
        newTask.taskScheduledDate = selectedDate  // Use the selected date
        if isTaskRecurring {
            newTask.taskRecurrencePattern = taskRecurrencePattern.rawValue
            // Optionally set an end date for recurring tasks
            // newTask.taskRecurrenceEndDate = someDate
        }

        saveContext()
        newTaskTitle = ""
        showingAddTask = false
    }
}
```

## Step 3: Update Task Filtering Logic

Change the `tasksForSelectedDate` computed property (around line 38) to use `taskScheduledDate` instead of `taskCreatedAt`:

```swift
var tasksForSelectedDate: [TaskEntity] {
    tasks.filter { task in
        // First check if it has a scheduled date
        if let scheduledDate = task.taskScheduledDate {
            return Calendar.current.isDate(scheduledDate, inSameDayAs: selectedDate)
        }
        // Fallback to created date for old tasks
        guard let taskDate = task.taskCreatedAt else { return false }
        return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
    }
}
```

## Step 4: Add Recurring Task Generation Logic (Optional)

To automatically create recurring tasks, add this function:

```swift
private func generateRecurringTasks() {
    let recurringTasks = tasks.filter { $0.taskRecurrencePattern != nil && !$0.taskIsCompleted }

    for task in recurringTasks {
        guard let pattern = task.taskRecurrencePattern,
              let scheduledDate = task.taskScheduledDate else { continue }

        let calendar = Calendar.current
        var nextDate: Date?

        switch pattern {
        case "daily":
            nextDate = calendar.date(byAdding: .day, value: 1, to: scheduledDate)
        case "weekly":
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: scheduledDate)
        case "monthly":
            nextDate = calendar.date(byAdding: .month, value: 1, to: scheduledDate)
        default:
            break
        }

        // Check if we need to create a new instance for the next occurrence
        if let nextDate = nextDate, nextDate <= Date() {
            let newTask = TaskEntity(context: viewContext)
            newTask.taskId = UUID()
            newTask.taskTitle = task.taskTitle
            newTask.taskIsCompleted = false
            newTask.taskCreatedAt = Date()
            newTask.taskScheduledDate = nextDate
            newTask.taskRecurrencePattern = pattern
            newTask.taskRecurrenceEndDate = task.taskRecurrenceEndDate
        }
    }

    saveContext()
}
```

## Step 5: Build and Test

1. Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Build: **Product → Build** (Cmd+B)
3. Run the app and test creating recurring tasks

## Troubleshooting

If you get build errors after adding the attributes:
1. Make sure you saved the CoreData model (Cmd+S)
2. Clean the build folder
3. Delete the app from simulator/device (to reset CoreData)
4. Build and run again

The attributes will be automatically generated as properties on `TaskEntity` by Xcode.


## Ignore this below
sharp/
  └── resources/
      └── animations/          ← Create this folder
          ├── celebration.json
          ├── checkmark-success.json
          ├── loading.json
          ├── empty-tasks.json
          └── empty-blocks.json


Also i want you to remake the blocking wizards much. This going to take time because i want it to be satisfiying and animations and interactible configuration tools in them. 