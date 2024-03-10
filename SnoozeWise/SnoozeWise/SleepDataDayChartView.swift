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
    @State private var chartType: ChartType = .pie
    
    enum ChartType: String, CaseIterable {
        case pie = "Pie Chart"
        case bar = "Bar Chart"
    }

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
        .sorted(by: { $0.stage < $1.stage })
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
                        Text("Quality Score")
                            .font(.system(size: 18))
                            .bold()
                        Text("\(String(format: "%.1f%", data.qualityScore()))")
                            .font(.system(size: 26))
                    }
                    .padding([.horizontal])
                    Spacer()
                }
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
                    Picker("Select Chart Type", selection: $chartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    if chartType == .pie {
                        pieChartView
                    } else {
                        barChartView
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding()
                GroupBox(label: Label("Quality Score", systemImage: "info.circle")) {
                    Text("Our sleep quality score is a comprehensive metric, thoughtfully crafted to encapsulate the intricate dynamics of your sleep stages. By assigning weighted values to each stage—reflecting their relative contribution to restorative sleep—we offer a nuanced glimpse into the quality of your slumber. Higher scores, particularly those closer to 100, denote a sleep pattern rich in deep and REM sleep, essential for physical recuperation and cognitive restoration. Conversely, lower scores might indicate room for improvement, perhaps signaling an excess of light or disrupted sleep. It's an invitation to delve deeper into your sleep habits, understand the factors influencing your rest, and embrace strategies that enhance your sleep quality. Remember, this score is a tool for insight and improvement, guiding you toward a more restful, rejuvenating night's sleep.")
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
    
    var pieChartView: some View {
        Chart(sleepStageChartData) { item in
            SectorMark(
                angle: .value(item.stage, item.ratio)
            )
            .foregroundStyle(health.getColorForStage(Stage(rawValue: item.stage) ?? .unknown))
            .annotation(position: .overlay) {
                VStack {
                    Text(item.stage)
                    Text(String(format: "%.1f%%", item.ratio * 100))
                    Text("\(formatDuration(item.duration))")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }

    var barChartView: some View {
        Chart(sleepStageChartData) { item in
            BarMark(
                x: .value("Ratio", item.ratio),
                y: .value("Stage", item.stage)
            )
            .cornerRadius(8)
            .foregroundStyle(health.getColorForStage(Stage(rawValue: item.stage) ?? .unknown))
            .annotation(position: .trailing) {
                Text("\(String(format: "%.1f%%", item.ratio * 100)) (\(formatDuration(item.duration)))").font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(preset: .automatic, position: .leading) {
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartXAxis (.hidden)
        .frame(height: CGFloat(sleepStageChartData.count * 60))
        .padding()
    }
}
