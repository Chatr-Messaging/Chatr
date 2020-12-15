//
//  AlertIndicator.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct AlertIndicator: View {
    @ObservedObject var dialogModel : DialogStruct

    var body: some View {
        ZStack {
            HStack {
                Text(String(self.dialogModel.notificationCount))
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                    .font(.footnote)
                    .padding(.horizontal, 5)
            }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 5, x: 0, y: 5))
        }.offset(x: Constants.avitarSize * 0.2, y: 5)
        .opacity(self.dialogModel.notificationCount > 0 ? 1 : 0)
    }
}
