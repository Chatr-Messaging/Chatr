//
//  HomeMessagesTitle.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

// MARK: Home Header Section
struct HomeMessagesTitle: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isLocalOpen: Bool
    @Binding var contacts: Bool
    @Binding var newChat: Bool
    @Binding var selectedContacts: [Int]

    var body: some View {
        HStack(alignment: .bottom) {
            Text("Messages")
                .font(.system(size: 38))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .offset(y: 8)

            Spacer()
            ContactsBtn(showContacts: self.$contacts)
                .offset(x: -5)

            MenuBtn(showNewChat: self.$newChat, selectedContacts: self.$selectedContacts)
        }
        .padding(.horizontal)
    }
}
