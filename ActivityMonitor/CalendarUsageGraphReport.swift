//
//  CalendarUsageGraphReport.swift
//  ActivityMonitor
//
//  Report scene for Calendar view usage graph
//

import DeviceActivity
import SwiftUI

struct CalendarUsageGraphReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "CalendarUsageGraph")
    let content: (TotalActivityConfiguration) -> UsageGraphView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> TotalActivityConfiguration {
        await createConfiguration(from: data)
    }
}

