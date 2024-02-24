//
//  SleepDataView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        NavigationView{
            VStack {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(health.sleepData.indices, id: \.self) { index in
                            NavigationLink(destination: SleepDataChartView(data: $health.sleepData[index])){
                                SleepDataItemView(data: $health.sleepData[index])
                            }
//                            NavigationLink(destination: SleepDataCardEditView(data: $health.sleepData[index])){
//                                SleepDataCardView(data: $health.sleepData[index])
//                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

