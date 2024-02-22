//
//  SleepDataView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataView: View {
    @EnvironmentObject var health: Health
    @State private var hasLoadedData = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    Text("Sleep Data")
                    ForEach(health.sleepData.sorted(by: { $0.start_time > $1.start_time }), id: \.id) { item in
                        NavigationLink(destination: SleepDataCardEditView(data: Binding.constant(item))) {
                            SleepDataCardView(data: item)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                if !hasLoadedData {
                    health.fetchSleepAnalysis()
                    hasLoadedData = true
                }
            }
        }
    }
}
