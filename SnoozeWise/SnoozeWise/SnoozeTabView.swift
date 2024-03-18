//
//  SnoozeTabView.swift
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
                SleepDataIntervalView()
                    .tag("SleepDataIntervals")
                    .tabItem{
                        Image(systemName: "bed.double")
                    }
                    .environmentObject(health)
                
                SleepDataDaysView()
                    .tag("SleepDataDays")
                    .tabItem{
                        Image(systemName: "calendar")
                    }
                    .environmentObject(health)
                
                HomePageView()
                    .tag("HomePage")
                    .tabItem{
                        Image(systemName: "house")
                    }
                    .environmentObject(health)
                
                SleepGraphView()
                    .tag("SleepPrediction")
                    .tabItem{
                        Image(systemName: "chart.bar")
                    }
                    .environmentObject(health)
                
                MLPredictionView()
                    .tag("MLPrediction")
                    .tabItem{
                        Image(systemName: "chart.xyaxis.line")
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
            .onAppear{
                loadData()
                refreshData()
            }
            .onDisappear{
//                health.hardReset()
                saveData()
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
        case "MLPrediction":
            return "Sleep Prediction"
        default:
            return "SnoozeWise"
        }
    }
    
    private func refreshData() {
//        if health.receivedAuthorization{
            isRefreshing = true
            health.fetchAnalysis()
            isRefreshing = false
//        }
    }
    
    private func loadData() {
        do {
//            while(!health.receivedAuthorization){
//                Thread.sleep(forTimeInterval: 2.0)
//            }
//            if health.receivedAuthorization,
            if
                let loadDate = UserDefaults.standard.object(forKey: "newLoadDate") as? Date,
                let sleepData = UserDefaults.standard.data(forKey: "sleepDataIntervals"),
                 let heartRateData = UserDefaults.standard.data(forKey: "heartRateIntervals"),
                  let userName = UserDefaults.standard.string(forKey: "userName"){
                health.newLoadDate = loadDate
                health.sleepDataIntervals = try JSONDecoder().decode([SleepDataInterval].self, from: sleepData)
                health.heartRateIntervals = try JSONDecoder().decode([HeartRateInterval].self, from: heartRateData)
                health.userName = userName
                print("Loaded Data")
            }
        }  catch {
            print("Error decoding intervals: \(error.localizedDescription)")
        }
    }
    
    private func saveData() {
        print("Entered save data")
        do {
//            health.fetchAnalysis()
            let sleepData = try JSONEncoder().encode(health.sleepDataIntervals)
            let heartRateData = try JSONEncoder().encode(health.heartRateIntervals)
            UserDefaults.standard.set(sleepData, forKey: "sleepDataIntervals")
            UserDefaults.standard.set(heartRateData, forKey: "heartRateIntervals")
            UserDefaults.standard.set(health.newLoadDate, forKey: "newLoadDate")
            UserDefaults.standard.set(health.userName, forKey: "userName")
            print("Saved Data")
        } catch {
            print("Error encoding intervals: \(error.localizedDescription)")
        }
    }
}

//struct SnoozeTabView_Previews: PreviewProvider {
//    static var previews: some View {
//        let h = Health()
//        SnoozeTabView().environmentObject(h)
//    }
//}
