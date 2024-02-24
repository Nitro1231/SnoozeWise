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
            let maxDaysToLoad = min(3, health.sleepDataDays.count)
            Chart(health.sleepDataDays.lazy.prefix(maxDaysToLoad)) { day in
                ForEach(day.intervals.lazy) { interval in
                    RectangleMark(
                        xStart: .value("Start Date", interval.startDate),
                        xEnd: .value("End Hour", interval.endDate),
                        y: .value("Stage", interval.stage.rawValue)
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Stage", interval.stage.rawValue))
                }
            }
            .chartLegend(.hidden)
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(initialX: health.sleepDataIntervals[0].startDate)
            .chartXVisibleDomain(length: 60*45)
        }
    }
}
