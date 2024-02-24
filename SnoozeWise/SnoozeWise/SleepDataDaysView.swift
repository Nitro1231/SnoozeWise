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
            LazyVStack(spacing: 20) {
                ForEach(health.sleepDataDays.indices, id: \.self) { index in
                    NavigationLink(destination: SleepDataDayChartView(data: $health.sleepDataDays[index])){
                        SleepDataDayItemView(data: $health.sleepDataDays[index])
                    }
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    SleepDataDaysView()
//}
