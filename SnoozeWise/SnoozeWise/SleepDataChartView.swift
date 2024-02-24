//
//  SleepDataChartView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataChartView: View {
    @Binding var data: SleepData

    var body: some View {
        VStack {
            Text("Sleep Stages")
                .font(.headline)
                .padding()
            Chart {
                ForEach(data.stages, id: \.startTime) { stage in                    
                    RectangleMark(
                        xStart: .value("Start Time", stage.startTime),
                        xEnd: .value("End Time", stage.endTime),
                        y: .value("Stage", stage.stage.rawValue)
                    )
                    .foregroundStyle(by: .value("Stage", stage.stage.rawValue))
                    .cornerRadius(15)
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
