//
//  SleepDataIntervalView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        VStack {
            GeometryReader { geometry in
                HStack {
                    HStack{
                        Text("Start Date").bold()

                        Spacer()
                    }
                    .frame(width: geometry.size.width / 3)
                    
                    HStack{
                        Text("End Date").bold()

                        Spacer()
                    }
                    .frame(width: geometry.size.width / 3)
                    
                    HStack {
                        Text("Sleep Stage").bold()
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width / 3)
                }
            }
            .frame(maxHeight: 10)
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            ScrollView(){
                LazyVStack(spacing: 20) {
                    ForEach(health.sleepDataDays.indices, id: \.self){ index in
                        VStack{
                            HStack {
                                Text( health.sleepDataDays[index].startDate.formatDate(format:"MMM d, yyy"))
                                    .font(.headline).foregroundColor(.gray)
                                Spacer()
                            }
                            ForEach(health.sleepDataDays[index].intervals.indices, id: \.self) { intervalIndex in
                                SleepDataIntervalCardView(data: $health.sleepDataDays[index].intervals[intervalIndex])
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

