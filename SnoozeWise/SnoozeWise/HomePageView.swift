//
//  HomePageView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct HomePageView: View {
    @EnvironmentObject var health: Health
    
    @State private var nameVisible = true
    @State private var recentQualityScores: Double = -1
    @State private var isPresentingInfoView = false
    @State private var selectedInfo:String = "intervals"
    
    struct InfoButtonView: View {
        let title: String
        let key: String
        @Binding var selectedInfo: String
        @Binding var isPresentingInfoView: Bool
        
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Button(action:{
                    selectedInfo = key
                    isPresentingInfoView = true
                }){
                    Image(systemName:"info.circle")
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing:9){
            if nameVisible {
                Button(action: {
                    nameVisible.toggle()
                }) {
                    Text("Hello, \(health.userName)")
                        .font(.title)
                        .foregroundColor(.blue)
                        .transition(.slide)
                }
            } else {
                HStack{
                    TextField("Enter your name", text: $health.userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .font(.title)
                    Spacer()
                    Button("Submit"){
                        withAnimation {
                            nameVisible.toggle()
                        }
                    }
                }
            }
            
            if recentQualityScores != -1{
                HStack{
                    Text("Average Recent Quality Score:").bold().font(.title3)
                    Spacer()
                    Text("\(String(format: "%.1f%", recentQualityScores))").bold().font(.title3).foregroundColor(.secondary)
                }
//                        .padding()
            }
//                .padding(.vertical)
//                .frame(height:40)
            
            if !health.sleepDataDays.isEmpty {
                Section(header: Text("Latest Sleep").bold().font(.callout).italic()){
                    SleepDataDayItemView(data:$health.sleepDataDays[0]).environmentObject(health)
                }
                
                Section(header: Text("Your All Time Best Sleep Days!").bold().font(.callout)) {
                    let sortedIndices = health.sleepDataDays.indices.sorted {
                        health.sleepDataDays[$0].qualityScore() > health.sleepDataDays[$1].qualityScore()
                    }.prefix(8)
                    ScrollView{
                        LazyVStack(spacing: 10){
                            ForEach(sortedIndices, id: \.self){ index in
                                SleepDataDayItemView(data:$health.sleepDataDays[index]).environmentObject(health).frame(height:100).padding()
                            }
                        }
                    }
                    .border(Color.black, width:0.5)
                    .cornerRadius(5)
                    .padding(.horizontal)
                }
            }
            
            VStack{
                Section(header: Text("Available Features").bold()){
                    List {
                        InfoButtonView(title: "Sleep Intervals", key: "intervals", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                        InfoButtonView(title: "Sleep Calendar", key: "calendar", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                        InfoButtonView(title: "Sleep Graph", key: "graph", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                        InfoButtonView(title: "Sleep Prediction", key: "prediction", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                        InfoButtonView(title: "Hard Resetting", key: "settings", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                        InfoButtonView(title: "Refreshing", key: "refresh", selectedInfo: $selectedInfo, isPresentingInfoView: $isPresentingInfoView)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .cornerRadius(7)
                }
            }
        }
        .sheet(isPresented: $isPresentingInfoView){
            NavigationStack {
                let view = getInfoText(selectedInfo)
                view
                    .font(.callout)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(15)
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingInfoView = false
                            }
                        }
                    }
            }
        }
        .padding()
        .onChange(of: health.sleepDataDays) {
            setRecentQualityScores()
        }
    }
    
    private func setRecentQualityScores(){
        if health.sleepDataDays.count > 0 {
            let maxDaysToLoad = min(3, health.sleepDataDays.count) - 1
            var score = 0.0
            for i in 0...maxDaysToLoad {
                score += health.sleepDataDays[i].qualityScore()
            }
            recentQualityScores = score / Double(maxDaysToLoad)
        }
    }
    
    private func getInfoText(_ selected: String) -> some View{
        switch selected {
        case "intervals":
            return GroupBox(label: Label("Sleep Intervals", systemImage: "info.circle")) {
                Text("Sleep Intervals lists all the intervals we receive directly from Apple's HealthKit API. You have the option to edit them as you see fit and all the charts will update accordingly. NOTICE: Editing any data on this app has NO effect on the data stored by Apple, they are saved seperately.")
            }
        case "calendar":
            return GroupBox(label: Label("Sleep Calendar", systemImage: "info.circle")) {
                Text("Sleep Calendar sorts your data by day and gives you the option to view sleep data for any date available and provides a variety of charts to allow you to see the distribution of your sleep data. It also provides a Quality Score, which is a comprehensive scoring of the day's sleep.")
            }
        case "graph":
            return GroupBox(label: Label("Sleep Graph", systemImage: "info.circle")) {
                Text("Sleep Graph gives you the option of looking at multiple days of your Sleep Data at one time. You can use the View Size slider to change the amount of visible days at a time.")
            }
        case "prediction":
            return GroupBox(label: Label("Sleep Prediction", systemImage: "info.circle")) {
                Text("Sleep Prediction gives you the opporunity to input a time you wish to wake up for the following day and we use Machine Learning algorithims to predict the MOST OPTIMAL time you should go to sleep based on your data and common healthy sleeping habits. It displays it in our Chart view format and it also gives you the option to temporarily add it your sleep data so you can examine it in the provided view tabs.")
            }
        case "settings":
            return GroupBox(label: Label("Hard Resetting", systemImage: "info.circle")) {
                Text("Available top left. Gives you the option of Hard Resetting / deleting your data. NOTICE: This will only delete your sleep data from our app, not from your ios account.")
            }
        case "refresh":
            return GroupBox(label: Label("Refreshing", systemImage: "info.circle")) {
                Text("Available top right. Refreshes the sleep data, while maintaining any edits made.")
            }
        default:
            return GroupBox(label: Label("", systemImage: "info.circle")) {
                Text("")
            }
        }
    }
}




//struct HomepageView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomepageView()
//    }
//}
