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
                Text("Start Date")
                Spacer()
                Text("End Date")
                Spacer()
                Text("Sleep Stage")
            }
            .padding(.horizontal)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(health.sleepDataIntervals.indices, id: \.self) { index in
                        NavigationLink(destination: SleepDataIntervalCardEditView(data: $health.sleepDataIntervals[index])){
                            SleepDataIntervalCardView(data: $health.sleepDataIntervals[index])
                        }
                    }
                }
            }
        }
        .padding()
    }
}

