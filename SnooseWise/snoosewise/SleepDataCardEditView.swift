//
//  SleepDataCardEditView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataCardEditView: View {
    @Binding var data: SleepData

    var body: some View {
        Form {
            Section(header: Text("Start time")) {
                DatePicker("Start Time", selection: $data.start_time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.automatic)
            }
            
            Section(header: Text("End time")) {
                DatePicker("End Time", selection: $data.end_time, displayedComponents: .hourAndMinute)
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
    }
}

