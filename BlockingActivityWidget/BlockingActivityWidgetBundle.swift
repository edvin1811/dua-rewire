//
//  BlockingActivityWidgetBundle.swift
//  BlockingActivityWidget
//
//  Created by Edvin Åslund on 2025-12-22.
//

import WidgetKit
import SwiftUI

@main
struct BlockingActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        BlockingActivityWidget()
        BlockingActivityWidgetControl()
        BlockingActivityWidgetLiveActivity()
    }
}
