//
//  DialogList.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import CoreData
import SwiftUI

struct DialogList: View {
    //var fetchRequest: FetchRequest<UserDialogs>
    @EnvironmentObject var auth: AuthModel
    
    var body: some View {
        VStack {
            Button(action: {
                ChatrApp.messages.sendMessage(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", text: "test text from hard code...", occupentID: PersistenceManager.shared.fetchDialogs(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID"))[0].occupentsID as! [NSNumber])
                print("send fake message")
            }) {
                Image(systemName: "paperplane")
                    .resizable()
                    .font(.none)
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundColor(.black)
            }.padding()
            
            Button(action: {
                if let selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") {
                    ChatrApp.messages.getMessageUpdates(dialogID: selectedDialogID, completion: { newMessages in
                        print("'Dialog' view successfully pulled new messages!")
                    })
                }
            }) {
                Image(systemName: "arrow.2.circlepath")
                    .resizable()
                    .font(.none)
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundColor(.black)
            }.padding()
            
            ScrollView {
                ForEach(PersistenceManager.shared.fetchMessages(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""), id: \.self) { item in
                    NavigationLink(destination: Text("possible text view")) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(item.text ?? "No Name")")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 3)
                                
                                if let date = item.date?.getElapsedInterval(lastMsg: "now") {
                                    Text("\(date)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                            }.padding()
                            Spacer()
    //                        Text("\(item.date?.getElapsedInterval() ?? "")")
    //                            .font(.caption)
    //                            .foregroundColor(.primary)
    //                            .padding()
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .frame(height: 75)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                }
            }
            Spacer()
        }
        
    }
    
}
