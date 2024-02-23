//
//  Health.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import Foundation
import HealthKit

enum Stage: String, CaseIterable {
    case awake = "Awake"
    case inBed = "In Bed"
    case coreSleep = "Core Sleep"
    case deepSleep = "Deep Sleep"
    case remSleep = "REM Sleep"
    case unknown = "Unknown"
}

struct SleepData: Identifiable {
    var id = UUID()
    var start_time: Date
    var end_time: Date
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
    
    @Published var sleepData: [SleepData] = []
    @Published var dateOfBirth: Date?
    
    init() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let allTypes: Set<HKSampleType> = [
            sleepType
        ]
        
        print()
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
            
            print("START Sleep Data")
            let sleepDataList: [SleepData] = samples.map { sample in
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
                    default:
                        stage = .unknown
                }
                
//                print("Sleep: \(stage.rawValue) - Start: \(sample.startDate), End: \(sample.endDate)")
                
                return SleepData(start_time: sample.startDate, end_time: sample.endDate, stage: stage)
            }
            print("END Sleep Data")
            
            DispatchQueue.main.async {
                self.sleepData = sleepDataList
            }
        }
            
        self.healthStore.execute(query)
    }
}
