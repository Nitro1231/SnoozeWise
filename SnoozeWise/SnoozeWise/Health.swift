//
//  Health.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import Foundation
import HealthKit
import SwiftUI

enum Stage: String, CaseIterable, Codable, Comparable {
    case inBed = "In Bed"
    case awake = "Awake"
    case asleep = "Asleep"
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"
    case deepSleep = "Deep Sleep"
    case unknown = "Unknown"
    
    static func index(for stage: Stage) -> Int {
        let order: [Stage] = [.inBed, .awake, .asleep, .remSleep, .coreSleep, .deepSleep, .unknown]
        return order.firstIndex(of: stage)!
    }
    
    static func < (lhs: Stage, rhs: Stage) -> Bool {
        return index(for: lhs) < index(for: rhs)
    }
}


//extension Stage: Comparable {
//    static func < (lhs: Stage, rhs: Stage) -> Bool {
//        let order: [Stage] = [.inBed, .awake, .asleep, .remSleep, .coreSleep, .deepSleep, .unknown]
//        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
//    }
//}

struct StageStats{
    var durations: [Stage: TimeInterval]
    var ratios: [Stage: Double]
}

class SleepDataDay: Identifiable, Equatable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var intervals: [SleepDataInterval]
    var heartRateIntervals: [HeartRateInterval]

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    init(startDate: Date, endDate: Date, intervals: [SleepDataInterval], heartRateIntervals: [HeartRateInterval]) {
        self.startDate = startDate
        self.endDate = endDate
        self.intervals = intervals
        self.heartRateIntervals = heartRateIntervals
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
    
    static func == (lhs: SleepDataDay, rhs: SleepDataDay) -> Bool {
        return lhs.startDate == rhs.startDate && lhs.intervals.count == rhs.intervals.count
    }

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
    
    func qualityScore() -> Double {
        if self.startDate == self.endDate{
            return 0.0
        }
        
        let weights: [Stage: Double] = [
            .deepSleep: 4,
            .remSleep: 3,
            .coreSleep: 2,
            .asleep: 0,
            .awake: -2.5,
            .inBed: 0
        ]
        
        let stageStats = getStageStatistics()
        var weightedSum: Double = 0
        
        for (stage, ratio) in stageStats.ratios {
            weightedSum += weights[stage]!*ratio
        }
        
        let maxScore = 0.25 * weights[Stage.deepSleep]! + 0.5 * weights[Stage.coreSleep]! + 0.25 * weights[Stage.remSleep]! // typical healthy sleep
        let score = weightedSum / maxScore * 100
        
        return max(0, min(score, 100))
    }
}

class HeartRateInterval: Identifiable, Codable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var bpm: Double

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    init(startDate: Date, endDate: Date, bpm: Double) {
        self.startDate = startDate
        self.endDate = endDate
        self.bpm = bpm
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case bpm
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        bpm = try container.decode(Double.self, forKey: .bpm)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(bpm, forKey: .bpm)
    }
}


class SleepDataInterval: Identifiable, Codable {
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
    
    private enum CodingKeys: String, CodingKey {
        case id
        case startDate
        case endDate
        case stage
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        stage = try container.decode(Stage.self, forKey: .stage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(stage, forKey: .stage)
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
    
    // return dayOfWeek as double (0 is monday, 1 is tuesday...)
    func getDayOfWeek() -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: self)
        if let weekday = components.weekday {
            let dayOfWeek = Double((weekday - 2) % 7)
            return dayOfWeek
        } else {
            return 0.0
        }
    }
    
    func minutesSinceMidnight() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        guard let hour = components.hour, let minute = components.minute else {
            return 0
        }
        return hour * 60 + minute
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
    
    @Published var sleepDataIntervals: [SleepDataInterval] = []
    @Published var sleepDataDays: [SleepDataDay] = []
    @Published var heartRateIntervals: [HeartRateInterval] = []
    
    @Published var userName: String = ""
    
    let initialDaysToLoad = 740
    var newLoadDate: Date

    
    init() {
        newLoadDate = Date().daysBack(initialDaysToLoad)
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let allTypes: Set<HKSampleType> = [sleepType, heartRateType]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: allTypes)
            } catch {
                print("Error fetching health data: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchAnalysis() {
        let group = DispatchGroup()
        
        group.enter()
        fetchSleepAnalysis {
            group.leave()
            
            group.enter()
            self.fetchHeartRateAnalysis {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.setSleepDataDays()
        }
    }
    
    func setSleepDataDays(){
        let groupedSleepSamplesByDay = Dictionary(grouping: self.sleepDataIntervals) { sample -> Date in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: sample.endDate)
            return Calendar.current.date(from: components)!
        }
        let groupedHRSamplesByDay = Dictionary(grouping: self.heartRateIntervals) { sample -> Date in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: sample.endDate)
            return Calendar.current.date(from: components)!
        }
        
        let sleepDataDayList: [SleepDataDay] = groupedSleepSamplesByDay.map { (date, intervals) in
            let earliestStartTime: Date = intervals.min(by: { $0.startDate < $1.startDate })!.startDate
            let latestEndTime: Date = intervals.max(by: { $0.endDate < $1.endDate })!.endDate
            let hrIntervals = groupedHRSamplesByDay[date] ?? [HeartRateInterval]()
            return SleepDataDay(startDate: earliestStartTime, endDate: latestEndTime, intervals: intervals, heartRateIntervals: hrIntervals)
        }.sorted { $0.startDate > $1.startDate }
        
        DispatchQueue.main.async {
            self.sleepDataDays = sleepDataDayList
            if(sleepDataDayList.count > 0){
                self.newLoadDate = self.sleepDataDays[0].endDate.secondsAgo(-30)  // set new load date
            }
        }
    }

    func fetchSleepAnalysis(completion: @escaping () -> Void) -> Void {
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
            
            print("LOAD DATE: \(self.newLoadDate.formatDate()) - received \(samples.count) (SLEEP ANALYSIS)")
                        
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
            
            DispatchQueue.main.async {
                self.sleepDataIntervals = sleepDataIntervalsList
                completion()
            }
        }
        self.healthStore.execute(query)
    }

    func fetchHeartRateAnalysis(completion: @escaping () -> Void) {
        let end = sleepDataIntervals.count > 0 ? sleepDataIntervals[0].endDate : self.newLoadDate
        print(end.formatDate())
        let predicate = HKQuery.predicateForSamples(withStart: self.newLoadDate, end: end, options: [])
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let heartRateSamples = samples as? [HKQuantitySample], error == nil else {
                if let error = error {
                    print("Error fetching heart rate data: \(error.localizedDescription)")
                }
                return
            }
            
            print("LOAD DATE: \(self.newLoadDate.formatDate()) - received \(heartRateSamples.count) (HEART RATE)")

            var heartRateIntervals: [HeartRateInterval] = self.heartRateIntervals
            for sample in heartRateSamples {
                heartRateIntervals.append(HeartRateInterval(startDate: sample.startDate, endDate: sample.endDate, bpm: sample.quantity.doubleValue(for: HKUnit(from: "count/min"))))
            }
            heartRateIntervals.sort { $0.startDate > $1.startDate }
            
            DispatchQueue.main.async {
                self.heartRateIntervals = heartRateIntervals
                completion()
            }
        }
        self.healthStore.execute(query)
    }

    
    func hardReset() -> Void {
        DispatchQueue.main.async {
            self.sleepDataIntervals.removeAll()
            self.sleepDataDays.removeAll()
            self.newLoadDate = Date().daysBack(self.initialDaysToLoad)
            if UserDefaults.standard.object(forKey: "newLoadDate") != nil { // clear old data
                UserDefaults.standard.removeObject(forKey: "newLoadDate")
                UserDefaults.standard.removeObject(forKey: "sleepDataIntervals")
                UserDefaults.standard.removeObject(forKey: "heartRateIntervals")
                UserDefaults.standard.removeObject(forKey: "userName")
            }
            print("Hard Reseted Data")
        }
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
