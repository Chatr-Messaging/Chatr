//
//  RingtoneView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

// MARK: Ringtone Section
struct ringtoneView: View {
    var body: some View {
        ZStack {
            List {
                Section {
                    Text("no blocked contacts found...")
                }
            }.environment(\.horizontalSizeClass, .regular)
            .background(Color("bgColor"))
        }
    }
}
