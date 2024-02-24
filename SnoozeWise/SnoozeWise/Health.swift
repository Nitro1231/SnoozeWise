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
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"
    case deepSleep = "Deep Sleep"
    case unknown = "Unknown"
}

struct StageData {
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    var stage: Stage
}

struct SleepData: Identifiable {
    var id = UUID()
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    var stages: [StageData]
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
    
    @Published var sleepData: [SleepData] = []
    // @Published var dateOfBirth: Date?
    
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
            let groupedSamples = Dictionary(grouping: samples) { sample -> Date in
                let components = Calendar.current.dateComponents([.year, .month, .day], from: sample.endDate)
                return Calendar.current.date(from: components)!
            }
            
            let sleepDataList: [SleepData] = groupedSamples.map { (date, samples) in
                let stages = samples.map { sample -> StageData in
                    let stage: Stage
                    switch sample.value {
                        case HKCategoryValueSleepAnalysis.inBed.rawValue:
                            stage = .inBed
                        case HKCategoryValueSleepAnalysis.awake.rawValue:
                            stage = .awake
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            stage = .remSleep
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            stage = .coreSleep
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            stage = .deepSleep
                        default:
                            stage = .unknown
                        }
                    return StageData(startTime: sample.startDate, endTime: sample.endDate, stage: stage)
                }
                
                let earliestStartTime: Date = stages.min(by: { $0.startTime < $1.startTime })!.startTime
                let latestEndTime: Date = stages.max(by: { $0.endTime < $1.endTime })!.endTime
                return SleepData(startTime: earliestStartTime, endTime: latestEndTime, stages: stages)
            }.sorted { $0.startTime > $1.startTime }
            print("END Fetching Sleep Data")

            DispatchQueue.main.async {
                self.sleepData = sleepDataList
            }
        }
        self.healthStore.execute(query)
    }
}
