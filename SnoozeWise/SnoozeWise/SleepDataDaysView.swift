//
//  SleepDataDaysView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/24/24.
//

import SwiftUI

struct SleepDataDaysView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(health.sleepDataDays.indices, id: \.self) { index in
                    SleepDataDayItemView(data: $health.sleepDataDays[index])
                        .environmentObject(health)
                        .padding(.horizontal)
                }
            }
        }
    }
        
}
