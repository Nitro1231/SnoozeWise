//
//  SleepDataChartView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataDayChartView: View {
    @Binding var data: SleepDataDay

    var body: some View {
        VStack {
            Text("Sleep Stages for " + data.endDate.formatDate(format: "MMM d, yyyy"))
                .font(.headline)
                .padding()
            Chart {
                ForEach(data.intervals, id: \.id) { interval in
                    RectangleMark(
                        xStart: .value("Start Time", interval.startDate),
                        xEnd: .value("End Time", interval.endDate),
                        y: .value("Stage", interval.stage.rawValue)
                    )
                    .foregroundStyle(by: .value("Stage", interval.stage.rawValue))
                    .cornerRadius(8)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: Calendar.Component.hour)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: Date.FormatStyle().hour())
                }
            }
            .chartYAxis {
                AxisMarks(preset: .automatic, position: .leading)
            }
            .padding()
            .aspectRatio(1, contentMode: .fit)

            GroupBox(label: Label("Title", systemImage: "star")) {
                Text("Content goes here")
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
    }
}