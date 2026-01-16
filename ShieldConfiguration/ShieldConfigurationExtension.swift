import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Customize the shield appearance for blocked applications
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.8),
            icon: UIImage(systemName: "hourglass"),
            title: ShieldConfiguration.Label(
                text: "Time's Up!",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "You've reached your limit for \(application.localizedDisplayName ?? "this app")",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Ask for More Time",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Ignore Limit",
                color: UIColor.systemRed
            )
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield appearance for applications in blocked categories
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "app.badge"),
            title: ShieldConfiguration.Label(
                text: "Category Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "\(application.localizedDisplayName ?? "This app") is in a restricted category: \(category.localizedDisplayName ?? "Unknown")",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Access",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Override",
                color: UIColor.systemOrange
            )
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield appearance for blocked web domains
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.85),
            icon: UIImage(systemName: "globe.badge.chevron.backward"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Access to \(webDomain.domain ?? "this website") is currently restricted",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Request Access",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Continue Anyway",
                color: UIColor.systemRed
            )
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield appearance for web domains in blocked categories
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.9),
            icon: UIImage(systemName: "globe.badge"),
            title: ShieldConfiguration.Label(
                text: "Category Restricted",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "\(webDomain.domain ?? "This website") belongs to a restricted category: \(category.localizedDisplayName ?? "Unknown")",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Ask Permission",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Override Block",
                color: UIColor.systemOrange
            )
        )
    }
}
