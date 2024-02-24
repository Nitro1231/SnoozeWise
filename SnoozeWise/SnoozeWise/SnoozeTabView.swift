//
//  TabView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/21/24.
//

import SwiftUI

struct SnoozeTabView: View {
    @EnvironmentObject var health: Health
    @State var selected = "HomePage"
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selected) {
                SleepDataDaysView()
                    .tag("SleepDataDays")
                    .tabItem{
                        Image(systemName: "calendar")
                    }
                    .environmentObject(health)
                
                SleepDataIntervalView()
                    .tag("SleepDataIntervals")
                    .tabItem{
                        Image(systemName: "bed.double")
                    }
                    .environmentObject(health)
                
                HomePageView()
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
            }
            .navigationBarTitle(getNavTitle(), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    .disabled(isRefreshing)
                }
            }
        }
    }
    
    func getNavTitle() -> String {
        switch selected {
        case "SleepDataDays":
            return "Sleep Days"
        case "SleepDataIntervals":
            return "Sleep Intervals"
        case "SleepPrediction":
            return "Sleep Calendar"
        default:
            return "SnoozeWise"
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
