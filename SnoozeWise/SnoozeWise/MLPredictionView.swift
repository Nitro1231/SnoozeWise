//
//  MLPredictionView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/27/24.
//

import SwiftUI
import Charts
import CoreML


//struct SleepStagePrediction {
//    var stage: String
//    var startTime: Date
//    var endTime: Date
//}

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
                predictSleepStages()
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
            self.loadModel()
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
    
    private func calculateSleepDuration() {
        let timeDifference = self.sleepEndTime.timeIntervalSince(Date())
        let usualMinutesDesired = self.selectedHours*60 + self.selectedMinutes
        let cappedDifference:Double = min(timeDifference, TimeInterval(usualMinutesDesired*60)) // in seconds
        
        let mean = cappedDifference * 0.9
        let standardDeviation = cappedDifference * 0.15
        
        let randomNumber = Double.random(in: -1...1)
        let gaussianNumber = mean + randomNumber * standardDeviation
        
//        print("timeDifference: \(cappedDifference / 3600), estimated sleep hours: \(gaussianNumber / 3600)")
        self.totalSleepHours = gaussianNumber / 3600
    }

    private func predictSleepStages() {
        guard let model = model else {
            print("ML model is not loaded.")
            return
        }
              
        var bestPrediction: SleepDataDay = runModelIteration(model)
        for _ in 1...5{
            // get a gaussian prediction for totalSleepHours
            calculateSleepDuration()
              
            let prediction = runModelIteration(model)
            if(prediction.qualityScore() > bestPrediction.qualityScore()){
                bestPrediction = prediction
            }
        }

        // update chart display
        self.predictedSleepData = bestPrediction
        self.sleepStartTime = bestPrediction.startDate
    }
    
    private func runModelIteration(_ model: SleepStageRandomForest) -> SleepDataDay {
        do {
            let inputFeatures: [SleepStageRandomForestInput] = prepareInputFeatures()
            
            var stages: [Int64] = []
            for inputFeature:SleepStageRandomForestInput in inputFeatures {
                let prediction: SleepStageRandomForestOutput = try model.prediction(input: inputFeature)
                stages.append(prediction.sleep_stage)
            }
            
//            return convertStagesToSleepDataDay(stages: stages)
            let sleepDataDay = convertStagesToSleepDataDay(stages: stages)
            self.predictHeartRate(inputDay: sleepDataDay)
            return sleepDataDay
            
            
        } catch {
            print("Error during prediction: \(error.localizedDescription)")
            
            let dummyDate = Date()
            return SleepDataDay(startDate: dummyDate, endDate: dummyDate, intervals: [], heartRateIntervals: [HeartRateInterval]())
        }
    }
    
    private func prepareInputFeatures() -> [SleepStageRandomForestInput] {
        var list: [SleepStageRandomForestInput] = []
        
        let day_of_week = self.sleepEndTime.getDayOfWeek()
        let numMinutes = Int(60*self.totalSleepHours)
        let currentDate = self.sleepEndTime.minutesAgo(numMinutes)
        var start_time_counter = Double(NSCalendar(calendarIdentifier: .gregorian)!.component(.hour, from: currentDate)*60 + Calendar.current.component(.minute, from: currentDate))

        for i in 0...numMinutes {
            list.append(SleepStageRandomForestInput(start_time: start_time_counter, interval:Double(i), day_of_week: day_of_week))
            start_time_counter += 1
        }
        
        return list
    }

    func convertStagesToSleepDataDay(stages: [Int64], totalSleepHours: Double = 8) -> SleepDataDay {
        var intervals = [SleepDataInterval]()
        var currentStageIndex = stages.first ?? 0
        var intervalStartIndex = 0
        
        let sleepStartTime = self.sleepEndTime.minutesAgo(Int(60*self.totalSleepHours))
        let stageValues: [Stage] = [.inBed, .awake, .asleep, .remSleep, .coreSleep, .deepSleep, .unknown]

        // group contiguous minutes with the same stage
        for (index, stageIndex) in stages.enumerated() {
            if stageIndex != currentStageIndex {
                if let stage = stageValues.enumerated().first(where: { $0.offset == currentStageIndex })?.element {
                    let startDate = sleepStartTime.minutesAgo(-intervalStartIndex)
                    let endDate = sleepStartTime.minutesAgo(-index)
                    let interval = SleepDataInterval(startDate: startDate, endDate: endDate, stage: stage)
                    intervals.append(interval)
                }
                
                currentStageIndex = stageIndex
                intervalStartIndex = index
            }
        }
        
        // close the last interval
        if let stage = stageValues.enumerated().first(where: { $0.offset == currentStageIndex })?.element {
            let startDate = sleepStartTime.minutesAgo(-intervalStartIndex)
            let endDate = sleepStartTime.minutesAgo(-stages.count)
            let interval = SleepDataInterval(startDate: startDate, endDate: endDate, stage: stage)
            intervals.append(interval)
        }
        intervals.sort { $0.startDate > $1.startDate }
        
        return SleepDataDay(startDate: sleepStartTime, endDate: sleepEndTime, intervals: intervals, heartRateIntervals: [HeartRateInterval]())
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
    
    func predictHeartRate(inputDay: SleepDataDay) {
        guard let hrModel = try? LSTMHeartRate(configuration: MLModelConfiguration()) else {
            print("Error: Failed to load Core ML model.")
            return
        }
        
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
                
                for i in 0..<Int(interval.duration / 60) {
                    let p_bpm = bpms[i].intValue
                    inputDay.heartRateIntervals.append(HeartRateInterval(startDate: interval.startDate.minutesAgo(i), endDate: interval.endDate.minutesAgo(i), bpm: Double(p_bpm)))
                }
                
            } catch {
                print("Error when predicting heart rate: \(error.localizedDescription)")
            }
        }
    }



}

