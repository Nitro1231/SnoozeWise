//
//  HealthDataManager.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/21/24.
//

import HealthKit

class HealthDataManager {
    let healthStore = HKHealthStore()
    
    func fetchSleepAnalysis(completion: @escaping ([SleepData]) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let sleepResults = results as? [HKCategorySample] else {
                completion([])
                return
            }
            
            let sleepData: [SleepData] = sleepResults.map { sample in
                let start = sample.startDate
                let end = sample.endDate
                let stage: String
                switch sample.value {
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    stage = "Awake"
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    stage = "Core"
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stage = "Deep"
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stage = "REM"
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    stage = "In Bed"
                default:
                    stage = "Unknown"
                }
                
                return SleepData(start_time: start, end_time: end, stage: stage)
            }
            
            completion(sleepData)
        }
        
        healthStore.execute(query)
    }
}

struct SleepData {
    let start_time: Date
    let end_time: Date
    let stage: String
}

