//
//  SleepDataCardView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalCardView: View {
    @Binding var data: SleepDataInterval
    @State private var isPresentingEditView = false
    
    var body: some View {
        HStack {
            Text(data.startDate.formatDate())
            Spacer()
            Text(data.endDate.formatDate())
            Spacer()
            Text(data.stage.rawValue)
            Spacer()
            Button(action: {
                self.isPresentingEditView = true
            }) {
                Image(systemName: "square.and.pencil")
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
