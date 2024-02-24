//
//  SleepDataItemView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataDayItemView: View {
    @Binding var data: SleepDataDay

    var body: some View {
        VStack {
            Text(data.endDate.formatDate(format: "MMM d, yyyy"))
                .padding()
            Chart {
                ForEach(data.intervals, id: \.id) { interval in
                    RuleMark(
                        xStart: .value("Start Time", interval.startDate),
                        xEnd: .value("End Time", interval.endDate),
                        y: .value("Stage", 0)
                    )
                    .foregroundStyle(by: .value("Stage", interval.stage.rawValue))
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
