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
    var stage: String // E.g., "REM", "Deep", etc.
    var startTime: Date
    var endTime: Date
}

struct MLPredictionView: View {
    @EnvironmentObject var health: Health
    @State private var model: sleepCoreML?
    @State private var sleepStartTime: Date = Date()
    @State private var totalSleepHours: Double = 8
    @State private var wakeUpTime: String = ""
    @State private var predictedSleepData: SleepDataDay?

    
    var body: some View {
        VStack {
            DatePicker("Sleep Start Time:", selection: $sleepStartTime, displayedComponents: .hourAndMinute)
               .padding()
           
           Stepper(value: $totalSleepHours, in: 1...12, step: 0.5) {
               Text("Total Sleep Hours: \(totalSleepHours, specifier: "%.1f")")
           }.padding()

           Button("Calculate Wake-up Time & Predict Stages") {
               calculateWakeUpTime()
               predictSleepStages()
           }.padding()

           Text("Expected Wake-up Time: \(wakeUpTime)")
            
            
            if let data = predictedSleepData {
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
            }
        }
        .onAppear {
            self.loadModel()
        }
    }
    
    private func loadModel() {
        do {
            model = try sleepCoreML(configuration: MLModelConfiguration())
        } catch {
            print("Error loading model: \(error.localizedDescription)")
        }
    }

    private func calculateWakeUpTime() {
        let calendar = Calendar.current
        if let wakeUpDate = calendar.date(byAdding: .hour, value: Int(totalSleepHours), to: sleepStartTime) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            wakeUpTime = formatter.string(from: wakeUpDate)
        }
    }
    
    private func prepareInputFeatures(from startTime: Date, totalHours: Double) -> sleepCoreMLInput {
        let totalMinutes = Int(totalHours * 60)
        let modelInputSize = 128 // Fixed model input size
        let dayOfWeek = Calendar.current.component(.weekday, from: startTime) - 1 // Adjust for model
        
        guard let multiArray = try? MLMultiArray(shape: [modelInputSize as NSNumber, 2], dataType: .float32) else {
            fatalError("Creating MLMultiArray failed")
        }
        
        // Calculate the sampling rate to reduce the total minutes to fit the model input size
        let samplingRate = max(1, totalMinutes / modelInputSize)
        
        for i in 0..<modelInputSize {
            let minuteIndex = i * samplingRate
            multiArray[i * 2] = NSNumber(value: minuteIndex) // Sampled time in minutes
            multiArray[i * 2 + 1] = NSNumber(value: dayOfWeek) // Day of the week
        }
        
        return sleepCoreMLInput(src_1: multiArray)
    }

    private func predictSleepStages() {
        guard let model = model else {
              print("ML model is not loaded.")
              return
          }
          
          let inputFeatures = prepareInputFeatures(from: sleepStartTime, totalHours: totalSleepHours)
          
          do {
              let predictionOutput = try model.prediction(input: inputFeatures)
              // Use the output feature name that your model provides for its predictions
              guard let outputArray = predictionOutput.featureValue(for: "linear_13")?.multiArrayValue else {
                  print("Failed to get prediction output")
                  return
              }
              print(outputArray)
              
              // Extract the predictions from the MLMultiArray
              let predictions = extractPredictions(from: outputArray)
              
              // Convert model output to SleepDataDay
              let sleepDataDay = convertModelOutputToSleepDataDay(modelOutput: predictions, sleepStartTime: sleepStartTime, totalSleepHours: totalSleepHours)
              
              // Update state variable
              self.predictedSleepData = sleepDataDay
          } catch {
              print("Error during prediction: \(error.localizedDescription)")
          }
    }
    
    func extractPredictions(from outputArray: MLMultiArray) -> [Int] {
        var predictions: [Int] = []
        
        // Assuming the shape of the outputArray is [128 x 6]
        let rowCount = outputArray.shape[0].intValue
        let colCount = outputArray.shape.count > 1 ? outputArray.shape[1].intValue : 1
        
        for i in 0..<rowCount {
            var maxIndex = 0
            var maxValue: Float = -Float.greatestFiniteMagnitude
            for j in 0..<colCount {
                let value = outputArray[[NSNumber(value: i), NSNumber(value: j)]].floatValue
                if value > maxValue {
                    maxValue = value
                    maxIndex = j
                }
            }
            predictions.append(maxIndex)
        }
        
        return predictions
    }

    
    func convertModelOutputToSleepDataDay(modelOutput: [Int], sleepStartTime: Date, totalSleepHours: Double) -> SleepDataDay {
        var intervals = [SleepDataInterval]()
        var currentStageIndex = modelOutput.first ?? -1 // Initialize with the first stage index
        var intervalStartIndex = 0
        
        let stages: [Stage] = [.inBed, .awake, .asleep, .remSleep, .coreSleep, .deepSleep, .unknown]

        // Iterate over the output to group contiguous minutes with the same stage
        for (index, stageIndex) in modelOutput.enumerated() {
            if stageIndex != currentStageIndex {
                // When the stage changes, close the previous interval and start a new one
                if let stage = stages.enumerated().first(where: { $0.offset == currentStageIndex })?.element {
                    let startDate = Calendar.current.date(byAdding: .minute, value: intervalStartIndex, to: sleepStartTime)!
                    let endDate = Calendar.current.date(byAdding: .minute, value: index, to: sleepStartTime)!
                    let interval = SleepDataInterval(startDate: startDate, endDate: endDate, stage: stage)
                    intervals.append(interval)
                }
                currentStageIndex = stageIndex
                intervalStartIndex = index
            }
        }
        
        // Close the last interval
        if let stage = stages.enumerated().first(where: { $0.offset == currentStageIndex })?.element {
            let startDate = Calendar.current.date(byAdding: .minute, value: intervalStartIndex, to: sleepStartTime)!
            let endDate = Calendar.current.date(byAdding: .minute, value: modelOutput.count, to: sleepStartTime)!
            let interval = SleepDataInterval(startDate: startDate, endDate: endDate, stage: stage)
            intervals.append(interval)
        }
        
        // Calculate the end date based on total sleep hours
        let endDate = Calendar.current.date(byAdding: .hour, value: Int(totalSleepHours), to: sleepStartTime)!
        
        // Create SleepDataDay
        let sleepDataDay = SleepDataDay(startDate: sleepStartTime, endDate: endDate, intervals: intervals)
        
        return sleepDataDay
    }

}

