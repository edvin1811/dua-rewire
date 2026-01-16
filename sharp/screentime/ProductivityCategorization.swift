//
//  ProductivityCategorization.swift
//  sharp
//

import Foundation
import FamilyControls

// MARK: - Productivity Classification
enum ProductivityType {
    case productive
    case nonProductive
    case neutral
    
    var displayName: String {
        switch self {
        case .productive: return "Productive"
        case .nonProductive: return "Non-Productive"
        case .neutral: return "Neutral"
        }
    }
    
    var color: String {
        switch self {
        case .productive: return "green"
        case .nonProductive: return "red"
        case .neutral: return "gray"
        }
    }
}

class ProductivityCategorizer {
    static let shared = ProductivityCategorizer()
    
    private init() {}
    
    // Apple's app categories mapped to productivity types
    private let categoryMapping: [String: ProductivityType] = [
        // Productive Categories
        "Productivity": .productive,
        "Business": .productive,
        "Education": .productive,
        "Reference": .productive,
        "Utilities": .productive,
        "Developer Tools": .productive,
        "Finance": .productive,
        "News": .productive,
        "Books": .productive,
        "Health & Fitness": .productive,
        "Medical": .productive,
        "Weather": .productive,
        
        // Non-Productive Categories
        "Social Networking": .nonProductive,
        "Entertainment": .nonProductive,
        "Games": .nonProductive,
        "Photo & Video": .nonProductive,
        "Music": .nonProductive,
        "Sports": .nonProductive,
        "Lifestyle": .nonProductive,
        "Shopping": .nonProductive,
        "Food & Drink": .nonProductive,
        "Travel": .nonProductive,
        
        // Neutral Categories
        "Navigation": .neutral,
        "Communication": .neutral,
        "Graphics & Design": .neutral,
        "Security": .neutral,
        "System": .neutral
    ]
    
    func classifyApp(categories: [String]) -> ProductivityType {
        // If no categories, default to neutral
        guard !categories.isEmpty else { return .neutral }
        
        // Check each category and return the first match
        for category in categories {
            if let productivity = categoryMapping[category] {
                return productivity
            }
        }
        
        // If no match found, default to neutral
        return .neutral
    }
    
    func getProductivityScore(for apps: [AppUsageInfo]) -> ProductivityMetrics {
        var productiveTime: TimeInterval = 0
        var nonProductiveTime: TimeInterval = 0
        var neutralTime: TimeInterval = 0
        
        var productiveApps = 0
        var nonProductiveApps = 0
        var neutralApps = 0
        
        for app in apps {
            let productivity = classifyApp(categories: app.categories)
            
            switch productivity {
            case .productive:
                productiveTime += app.totalTime
                productiveApps += 1
            case .nonProductive:
                nonProductiveTime += app.totalTime
                nonProductiveApps += 1
            case .neutral:
                neutralTime += app.totalTime
                neutralApps += 1
            }
        }
        
        let totalTime = productiveTime + nonProductiveTime + neutralTime
        
        return ProductivityMetrics(
            productiveTime: productiveTime,
            nonProductiveTime: nonProductiveTime,
            neutralTime: neutralTime,
            totalTime: totalTime,
            productiveApps: productiveApps,
            nonProductiveApps: nonProductiveApps,
            neutralApps: neutralApps,
            productivityScore: totalTime > 0 ? (productiveTime / totalTime) * 100 : 0
        )
    }
}

struct ProductivityMetrics {
    let productiveTime: TimeInterval
    let nonProductiveTime: TimeInterval
    let neutralTime: TimeInterval
    let totalTime: TimeInterval
    let productiveApps: Int
    let nonProductiveApps: Int
    let neutralApps: Int
    let productivityScore: Double // Percentage (0-100)
    
    var formattedProductiveTime: String {
        formatTime(productiveTime)
    }
    
    var formattedNonProductiveTime: String {
        formatTime(nonProductiveTime)
    }
    
    var formattedNeutralTime: String {
        formatTime(neutralTime)
    }
    
    var formattedTotalTime: String {
        formatTime(totalTime)
    }
    
    var productivityPercentage: String {
        String(format: "%.1f%%", productivityScore)
    }
    
    var nonProductivityPercentage: String {
        let nonProductiveScore = totalTime > 0 ? (nonProductiveTime / totalTime) * 100 : 0
        return String(format: "%.1f%%", nonProductiveScore)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
