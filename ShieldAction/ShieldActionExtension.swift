import ManagedSettings
import FamilyControls

class ShieldActionExtension: ShieldActionDelegate {
    
    func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            print("🛡️ Primary button pressed for app: \(application.bundleIdentifier ?? "Unknown")")
            // Keep the shield active - user needs to try again
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            print("🛡️ Secondary button pressed for app: \(application.bundleIdentifier ?? "Unknown")")
            // Dismiss the shield - allow access
            completionHandler(.close)
            
        @unknown default:
            print("🛡️ Unknown action for app: \(application.bundleIdentifier ?? "Unknown")")
            completionHandler(.defer)
        }
    }
    
    func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            print("🛡️ Primary button pressed for domain: \(webDomain.domain ?? "Unknown")")
            // Keep the shield active
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            print("🛡️ Secondary button pressed for domain: \(webDomain.domain ?? "Unknown")")
            // Dismiss the shield
            completionHandler(.close)
            
        @unknown default:
            print("🛡️ Unknown action for domain: \(webDomain.domain ?? "Unknown")")
            completionHandler(.defer)
        }
    }
    
    func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            
            print("🛡️ Primary button pressed for category: \(category.localizedDisplayName ?? "Unknown")")
            // Keep the shield active
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            print("🛡️ Secondary button pressed for category: \(category.localizedDisplayName ?? "Unknown")")
            // Dismiss the shield
            completionHandler(.close)
            
        @unknown default:
            print("🛡️ Unknown action for category: \(category.localizedDisplayName ?? "Unknown")")
            completionHandler(.defer)
        }
    }
}
