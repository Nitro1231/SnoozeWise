//
//  SleepGraphView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI
import Charts

struct SleepGraphView: View {
    @EnvironmentObject var health: Health
    @State private var sliderValueMinutes: Double = 60*24 // Initial value for the slider
        
    var body: some View {
        VStack{
            VStack{
                Text("View Size").font(.footnote)
                HStack{
                    Text("1.5 hour").font(.caption2)
                    Slider(value: $sliderValueMinutes, in: 90...2*24*60, step: 30)
                    Text("48 hours").font(.caption2)
                }
                .padding(.horizontal)
            }
            .padding()
            
            Chart(health.sleepDataDays.prefix(3)) { day in
                ForEach(day.intervals) { interval in
                    RectangleMark(
                        xStart: .value("Start Date", interval.startDate),
                        xEnd: .value("End Hour", interval.endDate),
                        y: .value("Stage", interval.stage.rawValue)
                    )
                    .cornerRadius(7)
                    .foregroundStyle(health.getColorForStage(interval.stage))
                }
            }
            .chartLegend(.hidden)
            .chartScrollableAxes(.horizontal)
            .chartScrollPosition(initialX: (health.sleepDataIntervals.count == 0 ? Date() : health.sleepDataIntervals[0].endDate))
            .chartXVisibleDomain(length: 60*sliderValueMinutes)
            .chartYAxis {
                AxisMarks(preset: .automatic, position: .leading)
            }
        }
    }
}
