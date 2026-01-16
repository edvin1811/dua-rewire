import SwiftUI

struct ProductivityInsightsView: View {
    let configuration: TotalActivityConfiguration
    @State private var selectedProductivityType: ProductivityType? = nil
    
    private var productivityMetrics: ProductivityMetrics {
        return ProductivityCategorizer.shared.getProductivityScore(for: configuration.appUsageData)
    }
    
    private var filteredApps: [AppUsageInfo] {
        guard let selectedType = selectedProductivityType else {
            return configuration.appUsageData
        }
        
        return configuration.appUsageData.filter { app in
            app.productivityType == selectedType
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Productivity Score Card
                productivityScoreCard
                
                // Category Breakdown
                categoryBreakdownView
                
                // App List
                appListView
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Daily Productivity Report")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedProductivityType != nil {
                    Button("Show All") {
                        withAnimation {
                            selectedProductivityType = nil
                        }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }
            
            HStack {
                Text(configuration.formattedTotalTime)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Productivity Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(productivityMetrics.productivityPercentage)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(productivityScoreColor)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var productivityScoreColor: Color {
        let score = productivityMetrics.productivityScore
        if score >= 70 { return .green }
        else if score >= 40 { return .orange }
        else { return .red }
    }
    
    private var productivityScoreCard: some View {
        VStack(spacing: 16) {
            Text("Time Distribution")
                .font(.headline)
                .fontWeight(.medium)
            
            // Productivity Ring Chart
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                // Productive time arc
                Circle()
                    .trim(from: 0, to: CGFloat(productivityMetrics.productivityScore / 100))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: productivityMetrics.productivityScore)
                
                // Center text
                VStack(spacing: 2) {
                    Text(productivityMetrics.productivityPercentage)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Productive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Time breakdown
            HStack(spacing: 20) {
                productivityTimeCard(
                    title: "Productive",
                    time: productivityMetrics.formattedProductiveTime,
                    percentage: productivityMetrics.productivityPercentage,
                    color: .green,
                    count: productivityMetrics.productiveApps,
                    type: .productive
                )
                
                productivityTimeCard(
                    title: "Non-Productive",
                    time: productivityMetrics.formattedNonProductiveTime,
                    percentage: productivityMetrics.nonProductivityPercentage,
                    color: .red,
                    count: productivityMetrics.nonProductiveApps,
                    type: .nonProductive
                )
                
                productivityTimeCard(
                    title: "Neutral",
                    time: productivityMetrics.formattedNeutralTime,
                    percentage: String(format: "%.1f%%", productivityMetrics.totalTime > 0 ? (productivityMetrics.neutralTime / productivityMetrics.totalTime) * 100 : 0),
                    color: .gray,
                    count: productivityMetrics.neutralApps,
                    type: .neutral
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func productivityTimeCard(
        title: String,
        time: String,
        percentage: String,
        color: Color,
        count: Int,
        type: ProductivityType
    ) -> some View {
        Button {
            withAnimation {
                selectedProductivityType = selectedProductivityType == type ? nil : type
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(percentage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(count) apps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedProductivityType == type ? color.opacity(0.2) : Color.clear)
            )
            .scaleEffect(selectedProductivityType == type ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: selectedProductivityType)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryBreakdownView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.medium)

            let categoryCounts = getCategoryCounts()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(categoryCounts.keys.sorted()), id: \.self) { category in
                    if let data = categoryCounts[category] {
                        CategoryCard(
                            category: category,
                            count: data.count,
                            totalTime: data.time,
                            productivityType: ProductivityCategorizer.shared.classifyApp(categories: [category])
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor { traits in
                        traits.userInterfaceStyle == .dark
                            ? UIColor(red: 0.05, green: 0.08, blue: 0.09, alpha: 1)
                            : UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
                    }))
                    .offset(y: 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor { traits in
                        traits.userInterfaceStyle == .dark
                            ? UIColor(red: 0.14, green: 0.23, blue: 0.27, alpha: 1)
                            : UIColor.white
                    }))
            }
        )
    }

    private var appListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedProductivityType?.displayName ?? "All Apps")
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(filteredApps.count) apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVStack(spacing: 8) {
                ForEach(filteredApps.prefix(20), id: \.id) { app in
                    ProductivityAppRow(app: app)
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor { traits in
                        traits.userInterfaceStyle == .dark
                            ? UIColor(red: 0.05, green: 0.08, blue: 0.09, alpha: 1)
                            : UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)
                    }))
                    .offset(y: 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: UIColor { traits in
                        traits.userInterfaceStyle == .dark
                            ? UIColor(red: 0.14, green: 0.23, blue: 0.27, alpha: 1)
                            : UIColor.white
                    }))
            }
        )
    }
    
    private func getCategoryCounts() -> [String: (count: Int, time: TimeInterval)] {
        var categoryCounts: [String: (count: Int, time: TimeInterval)] = [:]
        
        for app in configuration.appUsageData {
            for category in app.categories {
                if let existing = categoryCounts[category] {
                    categoryCounts[category] = (existing.count + 1, existing.time + app.totalTime)
                } else {
                    categoryCounts[category] = (1, app.totalTime)
                }
            }
        }
        
        return categoryCounts
    }
}

struct CategoryCard: View {
    let category: String
    let count: Int
    let totalTime: TimeInterval
    let productivityType: ProductivityType
    
    var formattedTime: String {
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var categoryColor: Color {
        switch productivityType {
        case .productive: return .green
        case .nonProductive: return .red
        case .neutral: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
                
                Text(category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
            }
            
            Text(formattedTime)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("\(count) apps")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(categoryColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ProductivityAppRow: View {
    let app: AppUsageInfo
    
    var productivityColor: Color {
        switch app.productivityType {
        case .productive: return .green
        case .nonProductive: return .red
        case .neutral: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Productivity indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(productivityColor)
                .frame(width: 4, height: 40)
            
            // App icon placeholder
            Circle()
                .fill(productivityColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.caption)
                        .foregroundColor(productivityColor)
                )
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(app.categories.first ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(app.productivityType.displayName)
                        .font(.caption)
                        .foregroundColor(productivityColor)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Time and productivity indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(app.formattedTime)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Image(systemName: app.isProductive ? "arrow.up.circle.fill" :
                      app.isNonProductive ? "arrow.down.circle.fill" : "minus.circle.fill")
                    .font(.caption)
                    .foregroundColor(productivityColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let sampleApps = [
        AppUsageInfo(name: "Instagram", bundleIdentifier: "com.burbn.instagram", totalTime: 3600, categories: ["Social Networking"]),
        AppUsageInfo(name: "Notion", bundleIdentifier: "com.notion.NotionApp", totalTime: 2400, categories: ["Productivity"]),
        AppUsageInfo(name: "Safari", bundleIdentifier: "com.apple.mobilesafari", totalTime: 1800, categories: ["Utilities"]),
        AppUsageInfo(name: "YouTube", bundleIdentifier: "com.youtube.ios", totalTime: 2700, categories: ["Entertainment"]),
        AppUsageInfo(name: "Maps", bundleIdentifier: "com.apple.Maps", totalTime: 900, categories: ["Navigation"])
    ]
    
    let sampleConfig = TotalActivityConfiguration(
        totalScreenTime: 11400,
        appUsageData: sampleApps,
        hourlyBreakdown: []
    )
    
    return ProductivityInsightsView(configuration: sampleConfig)
}
