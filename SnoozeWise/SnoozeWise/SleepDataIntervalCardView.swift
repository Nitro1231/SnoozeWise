//
//  SleepDataIntervalCardView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalCardView: View {
    @Binding var data: SleepDataInterval
    @State private var isPresentingEditView = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                HStack{
                    Text(data.startDate.formatDate(format:"h:mm a"))
                        .foregroundColor(Color(hex: "#f43c6f"))

                    Spacer()
                }
                .frame(width: geometry.size.width / 3)
                
                HStack{
                    Text(data.endDate.formatDate(format:"h:mm a"))
                        .foregroundColor(Color(hex: "#0983fe"))

                    Spacer()
                }
                .frame(width: geometry.size.width / 3)
                
                HStack {
                    Text(data.stage.rawValue).italic()
                    
                    Spacer()
                    
                    Button(action: {
                        self.isPresentingEditView = true
                    }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                .frame(width: geometry.size.width / 3)
            }
        }
        .padding()
        .shadow(radius:10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        
        .sheet(isPresented: $isPresentingEditView) {
            NavigationStack {
                SleepDataIntervalCardEditView(data: $data)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isPresentingEditView = false
                            }
                        }
                    }
            }
        }
    }
}
