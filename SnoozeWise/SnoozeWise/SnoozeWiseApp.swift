//
//  SnoozeWiseApp.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/21/24.
//

import SwiftUI

@main
struct SnoozeWiseApp: App {
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false
    @StateObject var health = Health()
    
    var body: some Scene {
        WindowGroup {
            SnoozeTabView()
                .onAppear {
                    if !hasLaunchedBefore {
                        if UserDefaults.standard.object(forKey: "newLoadDate") != nil { // clear old data
                            UserDefaults.standard.removeObject(forKey: "newLoadDate")
                            UserDefaults.standard.removeObject(forKey: "sleepDataIntervals")
                        }
                        hasLaunchedBefore = true
                    }
                }
                .environmentObject(health)
        }
    }
}
