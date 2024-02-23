//
//  SleepPredictionView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI
import Charts

struct SleepPredictionView: View {
    @EnvironmentObject var health: Health

    var body: some View {
//        Text("Sleep prediction")
        Chart(health.sleepData) { data in
//            AreaMark(
            RectangleMark(
                xStart: .value("Start Date", data.start_time),
                xEnd: .value("End Date", data.end_time),
                y: .value("Stage", data.stage.rawValue)
            )
        }
//        .chartScrollTargetBehavior(.paging)
    }
}

struct SleepPredictionView_Previews: PreviewProvider {
    static var previews: some View {
        SleepPredictionView()
    }
}
