//
//  MLPredictionView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/27/24.
//

import SwiftUI
import Charts
import CoreML


struct SleepStagePrediction {
    var stage: String
    var startTime: Date
    var endTime: Date
}

struct MLPredictionView: View {
    @EnvironmentObject var health: Health
    @State private var model: SleepStageRandomForest?
    @State private var sleepStartTime: Date?
    @State private var sleepEndTime: Date = Date().minutesAgo(-60*8)
    @State private var totalSleepHours: Double = 8
    @State private var predictedSleepData: SleepDataDay? = nil
    @State private var showPredictedChartView = false
    @State private var chartLoadedOnce = false
    @State private var addedToSleepData = false
    
    var body: some View {
        VStack {
            DatePicker("When do you want to wake up?", selection: $sleepEndTime, in: Date().minutesAgo(-5)...Date().daysBack(-1), displayedComponents: [.hourAndMinute, .date])
                .padding()
                .datePickerStyle(CompactDatePickerStyle())

            Button("Predict an IDEAL bed time for you") {
                health.fetchAnalysis()
                reinitializeViewVariables()
                predictSleepStages()
            }.padding()
            
            if let sleepStartTime = self.sleepStartTime {
                Text("You should sleep at \(sleepStartTime.formatDate(format: "h:mm a")) for the best sleep!")
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
                    .padding()
                    .aspectRatio(8/7, contentMode: .fit)
                    
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
        }
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
        let cappedDifference = min(timeDifference, 8.5 * 3600) // in seconds
        
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
            
            return convertStagesToSleepDataDay(stages: stages)
            
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
        
        return SleepDataDay(startDate: sleepStartTime, endDate: sleepEndTime, intervals: intervals, heartRateIntervals: [HeartRateInterval]())
    }
}

