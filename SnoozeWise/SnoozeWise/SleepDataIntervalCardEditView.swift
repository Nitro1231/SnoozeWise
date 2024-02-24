//
//  SleepDataCardEditView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalCardEditView: View {
    @Binding var data: SleepDataInterval
    var body: some View {
        Form {
            // disabled start date
            Section(header: Text("Start Date")) {
                DatePicker("Start Date", selection: $data.startDate, displayedComponents: .date)
                    .disabled(true)
                    .labelsHidden()
                    .foregroundColor(.gray)
            }
            
            // disabled end date
            Section(header: Text("End Date")) {
                DatePicker("End Date", selection: $data.endDate, displayedComponents: .date)
                    .disabled(true)
                    .labelsHidden()
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Start time")) {
                DatePicker("Start Time", selection: $data.startDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.automatic)
            }
            
            Section(header: Text("End time")) {
                DatePicker("End Time", selection: $data.endDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.automatic)
            }
            
            Section(header: Text("Sleep Stage")) {
                Picker("Stage", selection: $data.stage) {
                    ForEach(Stage.allCases, id: \.self) { stage in
                        Text(stage.rawValue)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
        }
        .padding()
    }
}
