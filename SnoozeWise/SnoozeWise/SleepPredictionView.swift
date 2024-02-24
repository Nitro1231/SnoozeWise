//
//  SleepPredictionView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI
import Charts

struct SleepPredictionView: View {
    @EnvironmentObject var health: Health
        
    var body: some View {
        VStack{
            Chart(health.sleepDataIntervals.lazy) { data in
                RectangleMark(
                    xStart: .value("Start Date", data.startDate),
                    xEnd: .value("End Hour", data.endDate),
                    y: .value("Stage", data.stage.rawValue)
                )
                .cornerRadius(5)
                .foregroundStyle(by: .value("Stage", data.stage.rawValue))
            }
            .chartLegend(.hidden)
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(initialX: health.sleepDataIntervals[0].startDate)
            .chartXVisibleDomain(length: 60*60*15)
        }
    }
}
