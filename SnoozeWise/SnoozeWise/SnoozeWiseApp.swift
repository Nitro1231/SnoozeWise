//
//  SnoozeWiseApp.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/21/24.
//

import SwiftUI

@main
struct SnoozeWiseApp: App {
    @StateObject var health = Health()
    
    var body: some Scene {
        WindowGroup {
            SnoozeTabView()
                .environmentObject(health)
        }
    }
}
