//
//  SleepDataCardView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataIntervalCardView: View {
    @Binding var data: SleepDataInterval
    
    var body: some View {
        HStack {
            Text(data.startDate.formatDate())
            Spacer()
            Text(data.endDate.formatDate())
            Spacer()
            Text(data.stage.rawValue)
        }
        .padding()
        .border(Color.gray, width: 0.4)
        .cornerRadius(10)
    }
}
