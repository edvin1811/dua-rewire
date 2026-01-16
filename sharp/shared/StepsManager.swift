import Foundation
import HealthKit
import Combine

class StepsManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var todaySteps = 0
    @Published var isAuthorized = false
    @Published var authorizationDenied = false
    @Published var authorizationError: Error?

    // MARK: - Background Monitoring (Important: Store query to prevent deallocation)
    private var observerQuery: HKObserverQuery?
    private var onGoalReached: (() -> Void)?
    private var currentTargetSteps: Int?



    func checkAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available")
            await MainActor.run {
                self.isAuthorized = false
                self.authorizationDenied = false
            }
            return
        }

        let stepType = HKQuantityType(.stepCount)

        // Try to fetch steps - this is the only reliable way to check if we have access
        do {
            let steps = try await fetchTodaySteps()
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationDenied = false
                self.todaySteps = steps
                print("HealthKit authorized - fetched \(steps) steps")
            }
        } catch {
            // If we can't fetch, we don't have access
            let status = healthStore.authorizationStatus(for: stepType)
            await MainActor.run {
                // Only mark as denied if status is explicitly denied
                // Otherwise it's just not determined yet
                self.isAuthorized = false
                self.authorizationDenied = (status == .sharingDenied)
                print("HealthKit not authorized - status: \(status.rawValue), error: \(error)")
            }
        }
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw StepsError.notAvailable
        }
        
        let stepType = HKQuantityType(.stepCount)
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            
            // Check the actual status after request
            await checkAuthorization()
            
            print("HealthKit authorization requested, final status: \(self.isAuthorized)")
        } catch {
            await MainActor.run {
                self.authorizationError = error
                self.isAuthorized = false
            }
            throw error
        }
    }
    
    func fetchTodaySteps() async throws -> Int {
        let stepType = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery

    /// Enable background delivery for step count updates
    /// Call this at app launch to ensure HealthKit can wake the app when steps change
    func enableBackgroundDelivery() {
        let stepType = HKQuantityType(.stepCount)

        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("✅ HealthKit background delivery enabled for steps")
            } else if let error = error {
                print("❌ Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }

    /// Disable background delivery (call when no longer monitoring)
    func disableBackgroundDelivery() {
        let stepType = HKQuantityType(.stepCount)

        healthStore.disableBackgroundDelivery(for: stepType) { success, error in
            if success {
                print("✅ HealthKit background delivery disabled")
            } else if let error = error {
                print("❌ Failed to disable background delivery: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Monitoring

    /// Start monitoring steps towards a target goal
    /// Stores the observer query to prevent deallocation and ensure background reliability
    func startMonitoring(targetSteps: Int, onGoalReached: @escaping () -> Void) {
        let stepType = HKQuantityType(.stepCount)

        // Stop any existing query first (before updating callbacks)
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
            print("🛑 Stopped previous steps monitoring")
        }

        // Store callback and target
        self.onGoalReached = onGoalReached
        self.currentTargetSteps = targetSteps

        // Fetch steps immediately
        Task {
            if let steps = try? await fetchTodaySteps() {
                await MainActor.run {
                    self.todaySteps = steps
                    print("👟 Current steps: \(steps), target: \(targetSteps)")
                    if steps >= targetSteps {
                        print("🎉 Goal already reached!")
                        onGoalReached()
                    }
                }
            }
        }

        // Set up continuous monitoring via observer query (IMPORTANT: Store as instance variable)
        observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("❌ Steps monitoring error: \(error.localizedDescription)")
                completionHandler()
                return
            }

            Task {
                guard let self = self else {
                    completionHandler()
                    return
                }

                if let steps = try? await self.fetchTodaySteps() {
                    await MainActor.run {
                        self.todaySteps = steps
                        print("👟 Steps updated: \(steps), target: \(targetSteps)")

                        if steps >= targetSteps {
                            print("🎉 Goal reached in background!")

                            // Send notification
                            Task {
                                await NotificationManager.shared.sendStepsGoalReached(
                                    steps: steps,
                                    target: targetSteps
                                )
                            }

                            // Update Live Activity if available
                            if #available(iOS 16.1, *) {
                                // Note: Need session ID to update, will be handled in BlockingSessionManager integration
                            }

                            // Trigger callback
                            self.onGoalReached?()
                        }
                    }
                }
                completionHandler()
            }
        }

        // Execute the stored query
        if let query = observerQuery {
            healthStore.execute(query)
            print("✅ Started monitoring steps with stored observer query")
        }

        // Background delivery should already be enabled at app launch
        // But enable it again just in case
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery confirmed for steps monitoring")
            } else if let error = error {
                print("⚠️ Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }

    /// Stop monitoring steps and clean up
    func stopMonitoring() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
            print("🛑 Stopped steps monitoring")
        }

        onGoalReached = nil
        currentTargetSteps = nil
    }
}

enum StepsError: Error {
    case notAvailable
    case notAuthorized
}
