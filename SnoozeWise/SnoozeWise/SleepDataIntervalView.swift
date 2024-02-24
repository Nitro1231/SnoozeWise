//
//  SleepDataView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        VStack {
            HStack {
                Text("Start Date").bold()
                Spacer()
                Text("End Date").bold()
                Spacer()
                Text("Sleep Stage").bold()
            }
            .padding(.horizontal)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(health.sleepDataIntervals.indices, id: \.self) { index in
                        SleepDataIntervalCardView(data: $health.sleepDataIntervals[index])
                    }
                }
            }
        }
        .padding()
    }
}

