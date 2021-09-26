//
//  SyncAddressBook.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/19/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube

struct SyncAddressBook: View {
    @State var confirmZeroAddress: Bool = false
    
    var body: some View {
        VStack(alignment: .center) {
            if confirmZeroAddress {
                Text("Sync your \nAddress Book")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 2.5)
                
                Text("Syncing your address book you will be able to discover registered contacts.")
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                                    
                Image("NoContacts")
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                    .padding(.horizontal)
                
                Button(action: {
                    changeAddressBookRealmData.shared.uploadAddressBook(completion: { result in })
                }) {
                    HStack {
                        Image(systemName: "book")
                            .resizable()
                            .frame(width: 25, height: 22, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.trailing, 5)
                        
                        Text("Sync Address Book")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }.buttonStyle(MainButtonStyle())
                .frame(height: 45)
                .frame(minWidth: 220, maxWidth: 270)
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                .padding(.top, 5)
                .padding()
            }
        }.onAppear() {
            Request.addressBook(withUdid: nil, successBlock: { (contacts) in
                if contacts.count > 0 {
                    changeAddressBookRealmData.shared.uploadAddressBook(completion: { _ in
                        self.confirmZeroAddress = true
                    })
                } else {
                    self.confirmZeroAddress = true
                }
            }) { (error) in
                self.confirmZeroAddress = true
            }
        }
    }
}
