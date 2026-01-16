import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample tasks for preview
        for i in 0..<5 {
            let newTask = TaskEntity(context: viewContext)
            newTask.taskId = UUID()
            newTask.taskTitle = "Sample Task \(i + 1)"
            newTask.taskIsCompleted = i % 2 == 0
            newTask.taskCreatedAt = Date().addingTimeInterval(-Double(i * 3600))
            if newTask.taskIsCompleted {
                newTask.taskCompletedAt = newTask.taskCreatedAt?.addingTimeInterval(1800)
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ScreenTimeApp")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
