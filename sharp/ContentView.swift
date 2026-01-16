import SwiftUI
import FamilyControls
import Clerk

// MARK: - Clean ContentView (Only High-Level Coordination) - MODERN VERSION
struct ContentView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var appStateManager = AppStateManager()
    
    var body: some View {
        Group {
            if let user = clerk.user {
                MainAppView(user: user)
                    .environmentObject(appStateManager.familyControlsManager)
                    .environmentObject(appStateManager)
            } else {
                ModernAuthenticationView() // Use the modern auth view
            }
        }
        .onAppear {
            appStateManager.initializeApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            appStateManager.handleAppForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            appStateManager.handleAppBackground()
        }
    }
}

// MARK: - Main App Container - UPDATED FOR MODERN DESIGN
struct MainAppView: View {
    let user: User
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedTab = 0
    @State private var presentingTemplates = false
    
    var body: some View {
        ZStack {
            // Modern background with subtle glow effects
            ModernBackground()
            
            VStack(spacing: 0) {
                // Session status overlay
                if appStateManager.showRestorationMessage {
                    sessionStatusOverlay
                }
                
                // Current tab content - KEEP YOUR EXISTING VIEWS
                tabContent
                    .background(Color.clear)
                    .overlay(
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.clear,                    // Transparent at top
                                                Color.appBackground.opacity(0.2),      // Semi-transparent
                                                Color.appBackground.opacity(0.5),      // More opaque
                                                Color.appBackground                     // Solid at bottom
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: 200)
                                    .allowsHitTesting(false)
                            },
                            alignment: .bottom
                            )
                    .ignoresSafeArea(.all, edges: .bottom)
            }
            
            // iOS 26 tab bar with quick action button
            VStack {
                Spacer()
                iOS26TabBar(
                    selectedTab: $selectedTab,
                    presentingTemplates: $presentingTemplates
                )
            }
        }
        .sheet(isPresented: $presentingTemplates) {
            TemplatesView()
                .environmentObject(appStateManager)
        }
        .onAppear {
            appStateManager.handleMainAppAppear()
        }
    }
    
    private var sessionStatusOverlay: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.successColor)
                
                Text(appStateManager.restorationMessage)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button {
                    appStateManager.hideRestorationMessage()
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.textSecondary)
                }
            }
            .modernCard()
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            CalendarView() // Calendar - Screen time insights with tasks
        case 1:
            NewUnifiedBlockingView() // Focus - Blocking sessions
        case 2:
            TasksView() // Tasks
        case 3:
            AccountView() // Account - Profile, goals, stats, insights
        default:
            CalendarView() // Default to calendar
        }
    }
}


