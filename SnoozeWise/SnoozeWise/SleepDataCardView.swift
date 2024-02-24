//
//  SleepDataCardView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataCardView: View {
    @Binding var data: SleepData
    
    var body: some View {
        HStack {
            Text(data.startTime.formatDate())
            Spacer()
            Text(data.endTime.formatDate())
            Spacer()
            // Text(data.stage.rawValue)
        }
        .padding()
    }
}
