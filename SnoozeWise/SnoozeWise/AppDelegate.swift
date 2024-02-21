//
//  AppDelegate.swift
//  SnoozeWise
//
//  Created by Jun Park on 2/21/24.
//

import UIKit
import HealthKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return true
        }
        
        let healthStore = HKHealthStore()
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Request permission
        healthStore.requestAuthorization(toShare: nil, read: Set([sleepType])) { (success, error) in
            if !success {
                // Handle the error here.
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

