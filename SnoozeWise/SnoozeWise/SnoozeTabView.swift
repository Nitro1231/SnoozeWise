//
//  TabView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/21/24.
//

import SwiftUI

struct SnoozeTabView: View {
    @EnvironmentObject var health: Health
    @State private var isRefreshing = false
    
    @State var selected = "HomePage"
    
    var body: some View {
        TabView(selection: $selected) {
            SleepDataView()
                .tag("SleepData")
                .tabItem{
                    Image(systemName: "bed.double")
                }
                .environmentObject(health)
            
            HomepageView()
                .tag("HomePage")
                .tabItem{
                    Image(systemName: "house")
                }
                .environmentObject(health)
            
            SleepPredictionView()
                .tag("SleepPrediction")
                .tabItem{
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                .environmentObject(health)
        }.toolbar {
            ToolbarItem() {
                Button(action: {
                    refreshData()
                }) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .disabled(isRefreshing)
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        health.fetchSleepAnalysis()
        isRefreshing = false
    }
}


struct SnoozeTabView_Previews: PreviewProvider {
    static var previews: some View {
        let h = Health()
        SnoozeTabView().environmentObject(h)
    }
}
