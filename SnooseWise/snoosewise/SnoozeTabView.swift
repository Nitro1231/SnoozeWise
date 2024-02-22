//
//  TabView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/21/24.
//

import SwiftUI

struct SnoozeTabView: View {
    @EnvironmentObject var health: Health
    
    @State var selected = "HomePage"
    
    var body: some View {
        TabView(selection: $selected) {
            SleepDataView()
                .tag("SleepData")
                .tabItem{
                    Image(systemName: "square.and.pencil.circle.fill")
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
                    Image(systemName: "bed.double.fill")
                }
                .environmentObject(health)
        }
    }
}

struct SnoozeTabView_Previews: PreviewProvider {
    static var previews: some View {
        let h = Health()
        SnoozeTabView().environmentObject(h)
    }
}
