//
//  SleepDataCardView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepDataCardView: View {
    @State var data: SleepData
    
    var body: some View {
        HStack {
            Text(data.start_time.formatDate())
            Spacer()
            Text(data.end_time.formatDate())
            Spacer()
            Text(data.stage.rawValue)
        }
        .padding(.horizontal)
    }
}
