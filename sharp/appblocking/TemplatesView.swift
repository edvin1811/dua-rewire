//
//  TemplatesView.swift
//  sharp
//
//  Created by Claude Code on 2025-12-03.
//

import SwiftUI
import CoreData

// MARK: - Template Model
struct BlockingTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let blockingType: BlockingType
    let duration: TimeInterval? // For timer
    let taskCount: Int? // For tasks
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, icon, colorHex, blockingTypeRaw, duration, taskCount, isDefault
    }

    init(id: UUID = UUID(), name: String, icon: String, color: Color, blockingType: BlockingType, duration: TimeInterval? = nil, taskCount: Int? = nil, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.blockingType = blockingType
        self.duration = duration
        self.taskCount = taskCount
        self.isDefault = isDefault
    }

    // Custom encoding/decoding for Color
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex)
        let typeRaw = try container.decode(String.self, forKey: .blockingTypeRaw)
        blockingType = BlockingType(rawValue: typeRaw) ?? .timer
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        taskCount = try container.decodeIfPresent(Int.self, forKey: .taskCount)
        isDefault = try container.decode(Bool.self, forKey: .isDefault)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color.toHex(), forKey: .colorHex)
        try container.encode(blockingType.rawValue, forKey: .blockingTypeRaw)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(taskCount, forKey: .taskCount)
        try container.encode(isDefault, forKey: .isDefault)
    }

    var subtitle: String {
        switch blockingType {
        case .timer:
            if let duration = duration {
                let minutes = Int(duration / 60)
                return "\(minutes) min"
            }
        case .task:
            if let count = taskCount {
                return "\(count) tasks"
            }
        case .schedule:
            return "Morning"
        case .location:
            return "Leave home"
        case .steps:
            return "2000 steps"
        case .sleep:
            return "Night mode"
        }
        return blockingType.title
    }
}

// MARK: - Default Templates
extension BlockingTemplate {
    static let defaults: [BlockingTemplate] = [
        BlockingTemplate(
            name: "Deep Work",
            icon: "💼",
            color: .accentOrange,
            blockingType: .timer,
            duration: 1800, // 30 minutes
            isDefault: true
        ),
        BlockingTemplate(
            name: "Study",
            icon: "📚",
            color: .accentOrange,
            blockingType: .timer,
            duration: 3600, // 1 hour
            isDefault: true
        ),
        BlockingTemplate(
            name: "Morning",
            icon: "☀️",
            color: .accentPurple,
            blockingType: .schedule,
            isDefault: true
        ),
        BlockingTemplate(
            name: "Tasks",
            icon: "✅",
            color: .accentGreen,
            blockingType: .task,
            taskCount: 3,
            isDefault: true
        ),
        BlockingTemplate(
            name: "Outside",
            icon: "🚶",
            color: .brandPrimary,
            blockingType: .location,
            isDefault: true
        ),
        BlockingTemplate(
            name: "Active",
            icon: "🏃",
            color: .accentYellow,
            blockingType: .steps,
            isDefault: true
        )
    ]
}

// MARK: - Templates View
struct TemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appStateManager: AppStateManager
    @Environment(\.managedObjectContext) private var viewContext

    @State private var templates: [BlockingTemplate] = []
    @State private var selectedTemplate: BlockingTemplate?
    @State private var showingWizard = false

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

                        // Templates grid
                        templatesGrid

                        // Custom template button
                        customTemplateButton

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadTemplates()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    dismiss()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.textSecondary)
                }

                Spacer()
            }

            VStack(spacing: 8) {
                Text("Quick Start")
                    .font(.duoTitle)
                    .foregroundColor(.textPrimary)

                Text("Start a focus session in one tap")
                    .font(.duoBody)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Templates Grid
    private var templatesGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(templates) { template in
                TemplateCard(template: template) {
                    startSession(with: template)
                }
            }
        }
    }

    // MARK: - Custom Template Button
    private var customTemplateButton: some View {
        Button {
            // For now, just dismiss and show regular selection
            dismiss()
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))

                Text("Create Custom Template")

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .heavy))
            }
            .font(.duoButton)
            .foregroundColor(.brandPrimary)
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandPrimary.opacity(0.5), lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Template Management
    private func loadTemplates() {
        // Load from UserDefaults or use defaults
        if let data = UserDefaults.standard.data(forKey: "blockingTemplates"),
           let saved = try? JSONDecoder().decode([BlockingTemplate].self, from: data) {
            templates = saved
        } else {
            templates = BlockingTemplate.defaults
            saveTemplates()
        }
    }

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: "blockingTemplates")
        }
    }

    // MARK: - Quick Start Session
    private func startSession(with template: BlockingTemplate) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        switch template.blockingType {
        case .timer:
            startTimerSession(template: template)
        case .task:
            startTaskSession(template: template)
        case .schedule:
            // Schedule needs wizard for now
            dismiss()
        case .location:
            // Location needs wizard for now
            dismiss()
        case .steps:
            startStepsSession(template: template)
        case .sleep:
            // Sleep needs wizard for now
            dismiss()
        }
    }

    private func startTimerSession(template: BlockingTemplate) {
        let duration = template.duration ?? 1800 // Default 30 min

        BlockingSessionManager.shared.startTimerSession(
            duration: duration,
            sessionName: template.name,
            familyControlsManager: appStateManager.familyControlsManager
        )

        dismiss()

        // Success feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }

    private func startTaskSession(template: BlockingTemplate) {
        // Get incomplete tasks
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "taskIsCompleted == NO")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.taskCreatedAt, ascending: false)]
        fetchRequest.fetchLimit = template.taskCount ?? 3

        do {
            let tasks = try viewContext.fetch(fetchRequest)

            if tasks.isEmpty {
                // Show alert: no tasks available
                print("⚠️ No incomplete tasks available")
                return
            }

            BlockingSessionManager.shared.startTaskSession(
                tasks: tasks,
                familyControlsManager: appStateManager.familyControlsManager,
                context: viewContext
            )

            dismiss()

            // Success feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        } catch {
            print("❌ Failed to fetch tasks: \(error)")
        }
    }

    private func startStepsSession(template: BlockingTemplate) {
        BlockingSessionManager.shared.startStepsSession(
            name: template.name,
            targetSteps: 2000,
            resetDaily: true,
            familyControlsManager: appStateManager.familyControlsManager,
            stepsManager: appStateManager.stepsManager
        )

        dismiss()

        // Success feedback
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: BlockingTemplate
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                // Emoji icon
                Text(template.icon)
                    .font(.system(size: 36))

                // Name
                Text(template.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textPrimary)

                // Subtitle
                Text(template.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                ZStack {
                    // Solid 3D shadow - moves up when pressed
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.uwCardShadow)
                        .offset(y: 4)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.uwCard)
                        .offset(y: isPressed ? 3 : 0)

                    // Color accent border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(template.color.darker(by: 0.2), lineWidth: 2)
                        .offset(y: isPressed ? 3 : 0)
                }
            )
            .offset(y: isPressed ? 3 : 0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
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

// MARK: - Color Extension for Hex
extension Color {
    func toHex() -> String {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255)
        return String(format: "#%06x", rgb)
        #else
        return "#000000"
        #endif
    }
}

#Preview {
    TemplatesView()
        .environmentObject(AppStateManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
