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
    @State var data: SleepDataDay
    @State private var chartType: ChartType = .pie
    @State private var isPresentingQualityInfoView = false
    @State private var isPresentingStageRatioView = false
    @State private var isPresentingHeartRateView = false
    
    
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
                overviewText
                sleepStageChart
                sleepRatioView
                sleepHeartRateView
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sleep Stages for " + data.endDate.formatDate(format: "MMM d, yyyy"))
                    .font(.headline)
                    .font(.system(size: 18))
            }
        }
        .sheet(isPresented:$isPresentingQualityInfoView){
            NavigationStack {
                GroupBox(label: Label("About Quality Score", systemImage: "info.circle")) {
                    Text("Our sleep quality score is a comprehensive metric, thoughtfully crafted to encapsulate the intricate dynamics of your sleep stages. By assigning weighted values to each stage—reflecting their relative contribution to restorative sleep—we offer a nuanced glimpse into the quality of your slumber. Higher scores, particularly those closer to 100, denote a sleep pattern rich in deep and REM sleep, essential for physical recuperation and cognitive restoration. Conversely, lower scores might indicate room for improvement, perhaps signaling an excess of light or disrupted sleep. It's an invitation to delve deeper into your sleep habits, understand the factors influencing your rest, and embrace strategies that enhance your sleep quality. Remember, this score is a tool for insight and improvement, guiding you toward a more restful, rejuvenating night's sleep.")
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            self.isPresentingQualityInfoView = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented:$isPresentingStageRatioView){
            NavigationStack {
                ScrollView {
                    GroupBox(label: Label("About Sleep Stage Ratios", systemImage: "moon.stars").foregroundColor(.blue)) {
                        VStack (alignment: .leading) {
                            Text("While we sleep, our brains and bodies restore themselves. Each sleep stage plays a different role, such as memory consolidation, emotional regulation, and physical restoration, and they're all essential to waking up refreshed.")
                            
                            Label("Awake", systemImage: "circle.fill")
                                .foregroundColor(health.getColorForStage(.awake))
                                .padding(.top).font(.headline)
                            Text("It takes time to fall asleep and we wake up periodically throughout the night. This time is represented as \"Awake\" in your charts.")
                            
                            Label("REM Sleep", systemImage: "circle.fill")
                                .foregroundColor(health.getColorForStage(.remSleep))
                                .padding(.top).font(.headline)
                            Text("Studies show that REM sleep may play a key role in memory and refreshing your brain. It's where most of your dreaming happens. Your eyes will also move side to side. REM sleep first occurs about 90 minutes after falling asleep.")
                            
                            Label("Core Sleep", systemImage: "circle.fill")
                                .foregroundColor(health.getColorForStage(.coreSleep))
                                .padding(.top).font(.headline)
                            Text("This stage, where muscle activity lowers and body temperature drops, represents the bulk of your time asleep. While it's sometimes referred to as light sleep, it's just as critical as any other sleep stage.")
                            
                            Label("Deep Sleep", systemImage: "circle.fill")
                                .foregroundColor(health.getColorForStage(.deepSleep))
                                .padding(.top).font(.headline)
                            Text("Also known as slow wave sleep, this stage allows the body to repair itself and release essential hormones. It happens in longer periods during the first half of the night. It's often difficult to wake up from deep sleep because you're so relaxed.")
                        }
                    }
                    .cornerRadius(15)
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                self.isPresentingStageRatioView = false
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented:$isPresentingHeartRateView){
            NavigationStack {
                GroupBox(label: Label("About Sleep Heart Rate", systemImage: "heart.fill").foregroundColor(.pink)) {
                    Text("A normal sleep heart rate can vary widely depending on several factors such as age, overall health, and fitness level. However, in general, during sleep, the heart rate can drop significantly as the body enters a state of relaxation and reduced metabolic needs. For most adults, a normal sleeping heart rate typically falls between 40 to 70 beats per minute (bpm). This range is generally lower than the normal resting heart rate for adults, which is between 60 to 100 bpm, as the heart rate drops during sleep to promote relaxation and recovery\n\nIt's worth noting that athletes or individuals with a high level of physical fitness might have a sleeping heart rate well below 60 bpm, sometimes as low as 40 bpm, due to their more efficient heart function.\n\nThese numbers can serve as a general guideline, but for an accurate assessment of what's normal for you personally, especially if you have any health conditions or concerns, it's best to consult with a healthcare provider.")
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .padding()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            self.isPresentingHeartRateView = false
                        }
                    }
                }
            }
        }
    }
    
    
    var overviewText: some View {
        VStack {
            HStack {
                VStack (alignment: .leading) {
                    HStack {
                        Text("Quality Score")
                            .font(.system(size: 18))
                            .bold()
                        Button(action:{
                            self.isPresentingQualityInfoView = true
                        }){
                            Image(systemName:"info.circle")
                        }
                    }
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
                    Text(data.formattedDuration)
                        .font(.system(size: 26))
                }
                .padding()
                Spacer()
            }
        }
    }
    
    var sleepStageChart: some View {
        Chart {
            ForEach(data.intervals.sorted(by: { $0.stage < $1.stage }), id: \.id) { interval in
                BarMark(
                    xStart: .value("Start Time", interval.startDate),
                    xEnd: .value("End Time", interval.endDate),
                    y: .value("Stage", interval.stage.rawValue)
                )
                .interpolationMethod(.catmullRom)
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
    }
    
    var sleepRatioView: some View {
        GroupBox(label: HStack {
            Label("Sleep Stage Ratio", systemImage: "moon.stars").foregroundColor(.blue)
            Spacer()
            Button(action: {
                self.isPresentingStageRatioView = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
            }
        }) {
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
    
    var sleepHeartRateView: some View {
        GroupBox(label: HStack {
            Label("Sleep Heart Rate", systemImage: "heart.fill").foregroundColor(.pink)
            Spacer()
            Button(action: {
                self.isPresentingHeartRateView = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue) // Set the color to blue or any color you prefer.
            }
        }) {
            Chart {
                ForEach(data.intervals.sorted(by: { $0.stage < $1.stage }), id: \.id) { interval in
                    RuleMark(
                        xStart: .value("Start Time", interval.startDate),
                        xEnd: .value("End Time", interval.endDate),
                        y: .value("Stage", 10)
                    )
                    .foregroundStyle(health.getColorForStage(interval.stage))
                    .cornerRadius(5)
                    .lineStyle(StrokeStyle(lineWidth: 10))
                }
                ForEach(data.heartRateIntervals) { interval in
                    LineMark(
                        x: .value("Start Time", interval.startDate),
                        y: .value("Heart Rate (bpm)", interval.bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Gradient(colors: [Color.red, Color.orange]))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: Calendar.Component.hour)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: Date.FormatStyle().hour())
                }
            }
            .chartYAxis {
                AxisMarks(preset: .automatic, position: .trailing) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .aspectRatio(2.5, contentMode: .fit)
            .padding([.vertical, .bottom])
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(15)
        .padding()
    }
}
