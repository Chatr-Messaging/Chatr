//
//  HomeMessagesTitle.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

// MARK: Home Header Section
struct HomeMessagesTitle: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var isLocalOpen: Bool
    @Binding var contacts: Bool
    @Binding var newChat: Bool
    @Binding var showUserProfile: Bool
    @Binding var selectedContacts: [Int]

    var body: some View {
            HStack {
                Text("Messages")
                    .font(.system(size: 38))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
                
                ContactsBtn(showContacts: self.$contacts)
                    .offset(x: -5, y: -5)

                MenuBtn(showNewChat: self.$newChat, selectedContacts: self.$selectedContacts)
                    .offset(y: -5)
                    
        }.zIndex(self.isLocalOpen ? 0 : 2)
        .padding(.horizontal)
    }
}
