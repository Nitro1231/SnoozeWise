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
        VStack {
            Chart(health.sleepDataIntervals) { data in
                RectangleMark(
                    xStart: .value("Start Date", data.startDate),
                    xEnd: .value("End Date", data.endDate),
                    y: .value("Stage", data.stage.rawValue)
                )
                .cornerRadius(8)
                .foregroundStyle(by: .value("Stage", data.stage.rawValue))
                
            }
            .chartLegend(.hidden)
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(initialX: health.sleepDataIntervals[0].startDate)
        }
    }
}

struct SleepPredictionView_Previews: PreviewProvider {
    static var previews: some View {
        SleepPredictionView()
    }
}
