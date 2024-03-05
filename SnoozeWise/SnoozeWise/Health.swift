//
//  Health.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import Foundation
import HealthKit
import SwiftUI

enum Stage: String, CaseIterable {
    case inBed = "In Bed"
    case awake = "Awake"
    case asleep = "Asleep"
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"
    case deepSleep = "Deep Sleep"
    case unknown = "Unknown"
}

extension Stage: Comparable {
    static func < (lhs: Stage, rhs: Stage) -> Bool {
        let order: [Stage] = [.inBed, .awake, .asleep, .remSleep, .coreSleep, .deepSleep, .unknown]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

struct StageStats{
    var durations: [Stage: TimeInterval]
    var ratios: [Stage: Double]
}

class SleepDataDay: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var intervals: [SleepDataInterval]

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    init(startDate: Date, endDate: Date, intervals: [SleepDataInterval]) {
        self.startDate = startDate
        self.endDate = endDate
        self.intervals = intervals
    }

    func getStageStatistics() -> StageStats {
        var stageDurations = [Stage: TimeInterval]()
        let relevantStages: [Stage] = [.awake, .asleep, .remSleep, .coreSleep, .deepSleep]

        for interval in intervals where relevantStages.contains(interval.stage) {
            stageDurations[interval.stage, default: 0] += interval.duration
        }

        let totalDuration = stageDurations.values.reduce(0, +)
        
        var stageRatios = [Stage: Double]()
        stageDurations.forEach { stage, duration in
            stageRatios[stage] = totalDuration > 0 ? duration / totalDuration : 0
        }
        return StageStats(durations: stageDurations, ratios: stageRatios)
    }
}

class SleepDataInterval: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var stage: Stage

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    init(startDate: Date, endDate: Date, stage: Stage) {
        self.startDate = startDate
        self.endDate = endDate
        self.stage = stage
    }
}

extension SleepDataDay {
    var formattedDuration: String {
        let durationInHours = Int(self.duration) / 3600
        let durationInMinutes = (Int(self.duration) % 3600) / 60
        return "\(durationInHours) hr \(durationInMinutes) min"
    }
    
    var totalSleepDuration: TimeInterval {
        intervals.filter { $0.stage == .asleep || $0.stage == .remSleep || $0.stage == .coreSleep || $0.stage == .deepSleep }.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalSleepDuration: String {
        let durationInHours = Int(self.totalSleepDuration) / 3600
        let durationInMinutes = (Int(self.totalSleepDuration) % 3600) / 60
        return "\(durationInHours) hr \(durationInMinutes) min"
    }
}

extension Date {
    func formatDate(format: String = "MMM d, yyyy h:mm a") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func daysBack(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -days, to: self) ?? self
    }
    
    func minutesAgo(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: -minutes, to: self) ?? self
    }
    
    func secondsAgo(_ seconds: Int) -> Date {
        return Calendar.current.date(byAdding: .second, value: -seconds, to: self) ?? self
    }
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

class Health: ObservableObject {
    let healthStore = HKHealthStore()
    
    // sleep data grouped by individual intervals (decending)
    @Published var sleepDataIntervals: [SleepDataInterval] = []
    
    // sleep data grouped by day (decending)
    @Published var sleepDataDays: [SleepDataDay] = []
    
    // last loaded date
    let daysToLoad = 740
    var newLoadDate: Date

    
    init() {
        newLoadDate = Date().daysBack(daysToLoad)
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let allTypes: Set<HKSampleType> = [sleepType]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: allTypes)
                
                fetchSleepAnalysis()
            } catch {
                print("Error fetching health data: \(error.localizedDescription)")
            }
        }
    }

    func fetchSleepAnalysis() -> Void {
//        print(newLoadDate.formatDate())
        let predicate = HKQuery.predicateForSamples(withStart: newLoadDate, end: Date(), options: [])
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, samples, error in
            guard let samples = samples as? [HKCategorySample] else {
                if let error = error {
                    print("Error fetching sleep data: \(error.localizedDescription)")
                }
                return
            }
                
            print("START Fetching Sleep Data")
//            print(samples.count)
            
            // process sleepDataIntervals
            var sleepDataIntervalsList: [SleepDataInterval] = self.sleepDataIntervals
            for sample in samples{
                let stage: Stage
                switch sample.value {
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    stage = .awake
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    stage = .coreSleep
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stage = .deepSleep
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stage = .remSleep
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    stage = .inBed
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    stage = .asleep
                default:
                    stage = .unknown
                }
                
                sleepDataIntervalsList.append(SleepDataInterval(startDate: sample.startDate, endDate: sample.endDate, stage: stage))
            }
            sleepDataIntervalsList.sort { $0.startDate > $1.startDate }
            
            // process sleepDataDays
            let groupedSamplesByDay = Dictionary(grouping: sleepDataIntervalsList) { sample -> Date in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: sample.endDate)
                return Calendar.current.date(from: components)!
            }
            
            let sleepDataDayList: [SleepDataDay] = groupedSamplesByDay.map { (date, intervals) in
                let earliestStartTime: Date = intervals.min(by: { $0.startDate < $1.startDate })!.startDate
                let latestEndTime: Date = intervals.max(by: { $0.endDate < $1.endDate })!.endDate
                let object = SleepDataDay(startDate: earliestStartTime, endDate: latestEndTime, intervals: intervals)
                
                return object
                
            }.sorted { $0.startDate > $1.startDate }
            
            
            DispatchQueue.main.async {
                // set new load date
                if(samples.count > 0){
                    self.newLoadDate = samples[0].endDate.secondsAgo(-30)
                }
                
                self.sleepDataIntervals = sleepDataIntervalsList
                self.sleepDataDays = sleepDataDayList
                
                print("END Fetching Sleep Data")
            }
        }
        self.healthStore.execute(query)
    }
    
    func hardReset() -> Void {
        self.sleepDataIntervals.removeAll()
        self.sleepDataDays.removeAll()
        self.newLoadDate = Date().daysBack(self.daysToLoad)
    }
    
    func getColorForStage(_ stage: Stage) -> Color {
        switch stage {
        case .inBed:
            return Color(hex: "#f43c6f")
        case .awake:
            return Color(hex: "#ff674f")
        case .asleep:
            return Color(hex: "#63d2ff")
        case .remSleep:
            return Color(hex: "#63d2ff")
        case .coreSleep:
            return Color(hex: "#0983fe")
        case .deepSleep:
            return Color(hex: "#3634a2")
        case .unknown:
            return Color(hex: "#808080")
        }
    }
}
