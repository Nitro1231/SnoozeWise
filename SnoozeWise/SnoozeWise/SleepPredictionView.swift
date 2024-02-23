//
//  SleepPredictionView.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct SleepPredictionView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        Text("Sleep prediction")
    }
}

struct SleepPredictionView_Previews: PreviewProvider {
    static var previews: some View {
        SleepPredictionView()
    }
}
