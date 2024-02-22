//
//  Homepage.swift
//  snoosewise
//
//  Created by Rohan Gupta on 2/22/24.
//

import SwiftUI

struct HomepageView: View {
    @EnvironmentObject var health: Health

    var body: some View {
        VStack{
            Text("Home")
        }
    }
}

struct HomepageView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView()
    }
}
