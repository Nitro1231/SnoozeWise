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
    case unknown = "Uknown"
}

struct SleepData {
    var id = UUID()
    var start_time: Date
    var end_time: Date
    var stage: Stage
}

extension Date {
    func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter.string(from: self)
    }
    
    func oneYearAgo() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -1, to: self)!
    }
    
    var oneWeekAgo: Date {
        return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: self)!
    }
    
    static func oneDayAgo() -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
}

class Health: ObservableObject {
    
    @Published var sleepData: [SleepData] = []
    let healthStore = HKHealthStore()
    
    init() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let allTypes: Set<HKSampleType> = [
            sleepType
        ]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: allTypes)
                
//                self.fetchSleepAnalysis()
            } catch {
                print("Error fetching health data: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchSleepAnalysis() -> Void {
        // Get the date for one week ago
//        let oneWeekAgoDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days * 24 hours * 60 minutes * 60 seconds

        // Create a predicate to fetch samples recorded after one week ago
        let predicate = HKQuery.predicateForSamples(withStart: Date().oneYearAgo(), end: Date(), options: [])

            
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
    
    func dateOfBirth(completion: @escaping (DateComponents?, Error?) -> Void) {
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            completion(dateOfBirth, nil)
        } catch {
            print("Error fetching date of birth: \(error.localizedDescription)")
            completion(nil, error)
        }
    }
}

