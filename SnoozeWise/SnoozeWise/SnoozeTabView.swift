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
    @State private var isPopupVisible = false
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPopupVisible = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                    }
                    .disabled(isRefreshing)
                }
            }
            .popover(isPresented: $isPopupVisible) {
                SettingsPageView()
                    .environmentObject(health)
            }
        }
    }
    
    func getNavTitle() -> String {
        switch selected {
        case "SleepDataDays":
            return "Sleep Calendar"
        case "SleepDataIntervals":
            return "Sleep Intervals"
        case "SleepPrediction":
            return "Sleep Chart"
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
