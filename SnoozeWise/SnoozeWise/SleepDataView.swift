//
//  SleepDataView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        NavigationView{
            VStack {
                HStack {
                    Text("Start Time")
                    Spacer()
                    Text("End Time")
                    Spacer()
                    Text("Sleep Stage")
                }
                .padding(.horizontal)

                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(health.sleepData.indices, id: \.self) { index in
                            NavigationLink(destination: SleepDataCardEditView(data: $health.sleepData[index])){
                                SleepDataCardView(data: $health.sleepData[index])
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

//struct SleepDataView_Previews: PreviewProvider {
//    static var previews: some View {
//        let h = Health()
//        SnoozeTabView().environmentObject(h)
//    }
//}
