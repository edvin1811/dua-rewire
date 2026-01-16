import SwiftUI
import Clerk

@main
struct ScreenTimeAppApp: App {
    let persistenceController = PersistenceController.shared
    @State private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if clerk.isLoaded {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environment(clerk)
                        .preferredColorScheme(.light)
                } else {
                   
                    ModernBackground()
                        .ignoresSafeArea(.all)
                        .overlay(
                            VStack(spacing: 20) {
                                // App logo/icon
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text("Sharp")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.white)
                                
                                Text("Loading...")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.subheadline)
                            }
                        )
                }
            }
            .task {
                // Replace with your actual Clerk publishable key
                clerk.configure(publishableKey: "pk_test_ZWxlZ2FudC1zY3VscGluLTM2LmNsZXJrLmFjY291bnRzLmRldiQ")
                try? await clerk.load()
            }
        }
    }
}
