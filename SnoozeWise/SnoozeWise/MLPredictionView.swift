//
//  MLPredictionView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/27/24.
//

import SwiftUI
import Charts
import CoreML

struct MLPredictionView: View {
    @EnvironmentObject var health: Health
    @State private var model: SleepStageRandomForest?
    @State private var sleepStartTime: Date?
    @State private var sleepEndTime: Date = Date().minutesAgo(-60*10)
    @State private var totalSleepHours: Double = 8
    @State private var predictedSleepData: SleepDataDay? = nil
    @State private var showPredictedChartView = false
    @State private var chartLoadedOnce = false
    @State private var addedToSleepData = false
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var follow = true
    
    var body: some View {
        VStack {
            VStack {
                Toggle("Follow this?", isOn: $follow)
                    .font(.callout).frame(height:35)
                HStack{
                    HStack{
                        if follow {
                            Text("Your Usual Sleep Duration").font(.callout)
                        } else {
                            Text("Provide a General Desired Amount of Sleep").font(.callout)
                        }
                        Spacer()
                    }.minimumScaleFactor(0.5)
                    Spacer()
                    VStack {
                        Stepper(value: $selectedHours, in: 0...23){
                            Text("\(selectedHours) hrs").bold().font(.caption)
                        }
                        
                        Stepper(value: $selectedMinutes, in: 0...59){
                            Text("\(selectedMinutes) min").bold().font(.caption)
                        }
                    }
                    .frame(width: 150)
                    .disabled(follow)
                }
            }
            .padding()
            
            Divider()
            
            DatePicker("When do you want to wake up?", selection: $sleepEndTime, in: Date().minutesAgo(-5)...Date().daysBack(-1), displayedComponents: [.hourAndMinute, .date])
                .padding()
                .datePickerStyle(CompactDatePickerStyle())

            Button("Predict an IDEAL bed time for you") {
                health.fetchAnalysis()
                reinitializeViewVariables()
                predictBestSleep()
            }.padding()
            
            if let sleepStartTime = self.sleepStartTime {
                Text("Sleep at \(sleepStartTime.formatDate(format: "h:mm a")) for the best sleep!")
            }
            
            if let data = predictedSleepData {
                VStack{
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
//                    .padding()
//                    .aspectRatio(8/7, contentMode: .fit)
                    
                    Button(action: {
                        health.sleepDataDays.insert(data, at: 0)
                        self.addedToSleepData = true
                    }){
                        Text(self.addedToSleepData ? "Added to Sleep Data (refresh to remove)" : "Add this to your Sleep Data (temporary)")
                    }
                    .padding()
                    .disabled(self.addedToSleepData)
                }
                .onChange(of: data) {
                    // show sheet after consecutive button clicks
                    if(!self.chartLoadedOnce){
                        self.showPredictedChartView = true
                        self.chartLoadedOnce = true
                    }
                }
                .onAppear(){
                    // show sheet after first button click
                    if(!self.chartLoadedOnce){
                        self.showPredictedChartView = true
                        self.chartLoadedOnce = true
                    }
                }
                .sheet(isPresented: $showPredictedChartView) {
                    NavigationStack {
                        SleepDataDayChartView(data: data)
                        .environmentObject(health)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showPredictedChartView = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
//            self.loadModel()
            self.setAverageSleepTime()
        }
        .padding()
    }
    
    private func loadModel() {
        do {
            self.model = try SleepStageRandomForest(configuration: MLModelConfiguration())
        } catch {
            print("Error loading model: \(error.localizedDescription)")
        }
    }
    
    private func reinitializeViewVariables() {
        self.showPredictedChartView = false
        self.chartLoadedOnce = false
        self.addedToSleepData = false
        self.predictedSleepData = nil
    }
    

    private func predictBestSleep() {
        guard let ssModel = try? LSTMSleepStage(configuration: MLModelConfiguration()) else {
            print("Error: Failed to load Sleep Stage model.")
            return
        }
        guard let hrModel = try? LSTMHeartRate(configuration: MLModelConfiguration()) else {
            print("Error: Failed to load Heart Rate model.")
            return
        }
        
        var bestPrediction: SleepDataDay?
        for _ in 1...1{
            let prediction = runModelIteration(ssModel: ssModel, hrModel: hrModel)
            if let bestScore = bestPrediction?.qualityScore(), bestScore < prediction.qualityScore(){
                bestPrediction = prediction
            } else {
                bestPrediction = prediction
            }
        }

        self.predictedSleepData = bestPrediction!  // update chart display
        self.sleepStartTime = bestPrediction!.startDate
    }
    
    
    private func runModelIteration(ssModel: LSTMSleepStage, hrModel: LSTMHeartRate) -> SleepDataDay {
        
        calculateSleepDuration() // get a gaussian prediction for totalSleepHours
        let sleepDataDay = predictSleepStages(ssModel: ssModel)
        predictHeartRate(hrModel: hrModel, inputDay: sleepDataDay)
        
        return sleepDataDay
    }
    
    private func predictSleepStages(ssModel: LSTMSleepStage) -> SleepDataDay {
        do {
            let sleepInterval = try MLMultiArray(shape: [1, 3, 1], dataType: .float32)
            let sleepStartTime: Date = sleepEndTime.minutesAgo(Int(60*self.totalSleepHours))
            let inputTemp = LSTMSleepStageInput(lstm_10_input: sleepInterval)
            inputTemp.lstm_10_input[[0, 0, 0] as [NSNumber]] = NSNumber(value: sleepStartTime.minutesSinceMidnight())
            inputTemp.lstm_10_input[[0, 1, 0] as [NSNumber]] = NSNumber(value: sleepEndTime.minutesSinceMidnight())
            inputTemp.lstm_10_input[[0, 2, 0] as [NSNumber]] = NSNumber(value: sleepEndTime.getDayOfWeek())

            let prediction = try ssModel.prediction(input: inputTemp)
            let stages = prediction.Identity

            var final_stages: [Int] = []
            let sleepDurationMinutes = Int(sleepEndTime.timeIntervalSince(sleepStartTime) / 60)

            for i in 0..<sleepDurationMinutes {
                if i >= stages.count {
                    final_stages.append(final_stages[final_stages.count - 1])
                } else {
                    var maxIndex = 0
                    var maxProb: Float = 0
                    
                    for j in 0...3{
                        let prob = Float(truncating: stages[4*i+j])
                        if prob > maxProb{
                            maxProb = prob
                            maxIndex = j
                        }
                    }
                    
                    switch maxIndex {
                    case 0:
                        final_stages.append(4)
                    case 1:
                        final_stages.append(3)
                    case 2:
                        final_stages.append(1)
                    default:
                        final_stages.append(5)
                    }
                }
            }
            
            // grouping intervals
            var intervals = [SleepDataInterval]()
            var previousStage: Int?
            var startIndex = 0
            for i in 0..<final_stages.count {
                let currentStage = final_stages[i]

                if let prevStage = previousStage, currentStage != prevStage {
                    intervals.append(
                        SleepDataInterval(
                            startDate: sleepStartTime.minutesAgo(-startIndex),
                            endDate: sleepStartTime.minutesAgo(-i),
                            stage: Stage.stage(for: prevStage)!
                        )
                    )

                    startIndex = i
                }

                previousStage = currentStage
            }
            if let prevStage = previousStage {
                intervals.append(
                    SleepDataInterval(
                        startDate: sleepStartTime.minutesAgo(-startIndex),
                        endDate: sleepStartTime.minutesAgo(-final_stages.count),
                        stage: Stage.stage(for: prevStage)!
                    )
                )
            }
            intervals.sort { $0.startDate > $1.startDate }
            
            
            return SleepDataDay(startDate: sleepStartTime, endDate: sleepEndTime, intervals: intervals, heartRateIntervals: [HeartRateInterval]())
            
        } catch {
            print("Error predicting sleep stages: \(error.localizedDescription)")
            let dummyDate = Date()
            return SleepDataDay(startDate: dummyDate, endDate: dummyDate, intervals: [SleepDataInterval](), heartRateIntervals: [HeartRateInterval]())
        }
    }
    
    func predictHeartRate(hrModel: LSTMHeartRate, inputDay: SleepDataDay) {
        for (i, interval) in inputDay.intervals.enumerated() {
            do {
                let sleepInterval = try MLMultiArray(shape: [1, 4, 1], dataType: .float32)

                let inputTemp = LSTMHeartRateInput(lstm_input: sleepInterval)

                inputTemp.lstm_input[[0, 0, 0] as [NSNumber]] = NSNumber(value: interval.startDate.minutesSinceMidnight())
                inputTemp.lstm_input[[0, 1, 0] as [NSNumber]] = NSNumber(value: interval.endDate.minutesSinceMidnight())
                inputTemp.lstm_input[[0, 2, 0] as [NSNumber]] = NSNumber(value: i)
                inputTemp.lstm_input[[0, 3, 0] as [NSNumber]] = NSNumber(value: Stage.index(for: interval.stage))

                let prediction = try hrModel.prediction(input: inputTemp)
                let bpms = prediction.Identity
                
                let intervalDurationMinutes = Int(interval.duration / 60)
                var previousBPM: Int?
                var startIndex = 0

                for i in 0..<intervalDurationMinutes {
                    let currentBPM: Int
                    if i >= bpms.count {
                        currentBPM = bpms[bpms.count-1].intValue
                    } else {
                        currentBPM = max(35,bpms[i].intValue)
                    }
                    
                    if let prevBPM = previousBPM, currentBPM != prevBPM {
                        inputDay.heartRateIntervals.append(HeartRateInterval(startDate: interval.startDate.minutesAgo(-startIndex), endDate: interval.startDate.minutesAgo(-i), bpm: Double(prevBPM)))
                        
                        startIndex = i
                    }
                    
                    previousBPM = currentBPM
                }
                if let prevBPM = previousBPM {
                    inputDay.heartRateIntervals.append(HeartRateInterval(startDate: interval.startDate.minutesAgo(-startIndex), endDate: interval.startDate.minutesAgo(-intervalDurationMinutes), bpm: Double(prevBPM)))
                }
                
                inputDay.heartRateIntervals.sort { $0.startDate > $1.startDate }
                
            } catch {
                print("Error predicting heart rate: \(error.localizedDescription)")
            }
        }
    }
    
    private func calculateSleepDuration() {
        let timeDifference = self.sleepEndTime.timeIntervalSince(Date())
        let usualMinutesDesired = self.selectedHours*60 + self.selectedMinutes
        let cappedDifference:Double = min(timeDifference, TimeInterval(usualMinutesDesired*60)) // in seconds
        
        let mean = cappedDifference * 0.9
        let standardDeviation = cappedDifference * 0.15
        
        let randomNumber = Double.random(in: -1...1)
        let gaussianNumber = mean + randomNumber * standardDeviation
        
        print("timeDifference: \(cappedDifference / 3600), estimated sleep hours: \(gaussianNumber / 3600)")
        self.totalSleepHours = gaussianNumber / 3600
    }
    
    private func setAverageSleepTime(){
        if health.sleepDataDays.count > 0 {
            let maxDaysToLoad = min(14, health.sleepDataDays.count) - 1
            var sleepTime = 0.0
            for i in 0...maxDaysToLoad {
                sleepTime += health.sleepDataDays[i].duration / 60
            }
            sleepTime /= Double(maxDaysToLoad+1)
            selectedHours = Int(sleepTime / 60)
            selectedMinutes = Int(sleepTime) % 60
            
        }
    }
}

