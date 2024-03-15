//
//  SettingsPageView.swift
//  SnoozeWise
//
//  Created by Rohan Gupta on 2/26/24.
//

import SwiftUI

struct SettingsPageView: View {
    @EnvironmentObject var health: Health
    @State private var isAlertVisible = false

    var body: some View {
        VStack{
            Text("Settings").font(.title)
            
            Spacer()
            
            HStack{
                Text("HARD RESET: (This will only delete the sleep data from our app, not from your ios account) ")
                Button(action: {
                    isAlertVisible = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Text("Developers:").font(.title3).italic()
            Text("Rohan Gupta and Hyunjun Park").font(.title3).italic()
        }
        .padding()
        .alert(isPresented: $isAlertVisible){
            Alert(title: Text("Hard Reset"), message: Text("Are you sure you want to hard reset?"),
                  primaryButton: .default(Text("Confirm")) {
                    DispatchQueue.main.async {
                        health.hardReset()
                    }
                },
                secondaryButton: .cancel(Text("Return"))
            )
        }
    }
}

//#Preview {
//    SettingsPageView()
//}
