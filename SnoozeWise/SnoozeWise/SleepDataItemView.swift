//
//  SleepDataItemView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataItemView: View {
    @Binding var data: SleepData

    var body: some View {
        VStack {
            Text(data.endTime.formatDate(format: "MMM d, yyyy"))
                .padding()
            Chart {
                ForEach(data.stages, id: \.startTime) { stage in
                    RuleMark(
                        xStart: .value("Start Time", stage.startTime),
                        xEnd: .value("End Time", stage.endTime),
                        y: .value("Stage", 0)
                    )
                    .foregroundStyle(by: .value("Stage", stage.stage.rawValue))
                    .lineStyle(StrokeStyle(lineWidth: 5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .cornerRadius(15)
            .frame(height: 5)
            .background(Color(UIColor.systemBackground))
            .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
    }
}
