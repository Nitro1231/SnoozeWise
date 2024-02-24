//
//  Health.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import Foundation
import HealthKit

enum Stage: String, CaseIterable {
    case inBed = "In Bed"
    case awake = "Awake"
    case asleep = "Asleep"
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"
    case deepSleep = "Deep Sleep"
    case unknown = "Unknown"
}

struct SleepDataDay: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    var intervals: [SleepDataInterval]
}

struct SleepDataInterval: Identifiable {
    var id = UUID()
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    var stage: Stage
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
}

class Health: ObservableObject {
    let healthStore = HKHealthStore()
    
    // sleep data grouped by individual intervals (decending)
    @Published var sleepDataIntervals: [SleepDataInterval] = []
    // sleep data grouped by day (decending)
    @Published var sleepDataDays: [SleepDataDay] = []

    
    init() {
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
        let predicate = HKQuery.predicateForSamples(withStart: Date().daysBack(740), end: Date(), options: [])
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
            
            // process sleepDataIntervals
            let sleepDataIntervalsList: [SleepDataInterval] = samples.map { sample in
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
                
                return SleepDataInterval(startDate: sample.startDate, endDate: sample.endDate, stage: stage)
            }
            
            
            // process sleepDataDays
            let groupedSamplesByDay = Dictionary(grouping: sleepDataIntervalsList) { sample -> Date in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: sample.endDate)
                return Calendar.current.date(from: components)!
            }
            let sleepDataDayList: [SleepDataDay] = groupedSamplesByDay.map { (date, intervals) in
                let earliestStartTime: Date = intervals.min(by: { $0.startDate < $1.startDate })!.startDate
                let latestEndTime: Date = intervals.max(by: { $0.endDate < $1.endDate })!.endDate
                return SleepDataDay(startDate: earliestStartTime, endDate: latestEndTime, intervals: intervals)
            }.sorted { $0.startDate > $1.startDate }
            
            
            DispatchQueue.main.async {
                self.sleepDataIntervals = sleepDataIntervalsList
                self.sleepDataDays = sleepDataDayList
            }
            
            print("END Fetching Sleep Data")

        }
        self.healthStore.execute(query)
    }
}
