//
//  SleepDataDayChartView.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/23/24.
//

import SwiftUI
import Charts

struct SleepDataDayChartView: View {
    @EnvironmentObject var health: Health
    @Binding var data: SleepDataDay
    
    
    struct StageData: Identifiable {
        let id = UUID()
        let stage: String
        let ratio: Double
        let duration: TimeInterval
    }

    var sleepStageChartData: [StageData] {
        let statistics = data.getStageStatistics()
        return statistics.durations.map { stage, duration in
            let ratio = statistics.ratios[stage] ?? 0
            return StageData(stage: stage.rawValue, ratio: ratio, duration: duration)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    VStack (alignment: .leading) {
                        Text("Time In Bed")
                            .font(.system(size: 18))
                            .foregroundColor(health.getColorForStage(.inBed))
                            .bold()
                        Text(data.formattedDuration)
                            .font(.system(size: 26))
                    }
                    .padding()
                    Spacer()
                    VStack (alignment: .leading) {
                        Text("Time Asleep")
                            .font(.system(size: 18))
                            .foregroundColor(health.getColorForStage(.coreSleep))
                            .bold()
                        Text(data.formattedTotalSleepDuration)
                            .font(.system(size: 26))
                    }
                    .padding()
                    Spacer()
                }
                Chart {
                    ForEach(data.intervals.sorted(by: { $0.stage < $1.stage }), id: \.id) { interval in
                        RectangleMark(
                            xStart: .value("Start Time", interval.startDate),
                            xEnd: .value("End Time", interval.endDate),
                            y: .value("Stage", interval.stage.rawValue)
                        )
                        .foregroundStyle(health.getColorForStage(interval.stage))
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
                .aspectRatio(8/7, contentMode: .fit)
                
                
                GroupBox(label: Label("Sleep Stage Ratios", systemImage: "moon.stars")) {
                    Chart(sleepStageChartData) { item in
                        SectorMark(
                            angle: .value(
                                item.stage,
                                item.ratio
                            )
                        )
                        .foregroundStyle(health.getColorForStage(Stage(rawValue: item.stage) ?? .unknown))
                        .annotation(position: .overlay) {
                            VStack {
                                Text(item.stage)
                                Text(String(format: "%.1f%%", item.ratio * 100))
                                Text("\(formatDuration(item.duration))")
                                    .font(.caption)
                            }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sleep Stages for " + data.endDate.formatDate(format: "MMM d, yyyy"))
                    .font(.headline)
                    .font(.system(size: 18))
            }
        }
    }
}
