//
//  MessageReplyCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct messageReplyStruct {
    var id: String
    var fromId: String
    var text: String
    var date: Date
}

struct MessageReplyCell: View {
    var reply: messageReplyStruct
    @State var avatar: String = ""
    @State var fullName: String = ""

    var body: some View {
        HStack(alignment: .top) {
            Menu {
                Text(self.fullName + "   \(reply.date.getElapsedInterval(lastMsg: "just now"))")
                    .fontWeight(.bold)

                Button(action: {
                    print("view profile")
                }) {
                    Label("Add", systemImage: "plus.circle")
                }

                Button(action: {
                    print("delete button")
                }) {
                    Label("delete reply", systemImage: "trash")
                        .foregroundColor(.red)
                }

                Button(action: {
                    print("report button")
                }) {
                    Label("report reply", systemImage: "exclamationmark.icloud")
                        .foregroundColor(.red)
                }
            } label: {
                ZStack {
                    Circle()
                        .frame(width: 30, height: 30, alignment: .center)
                        .foregroundColor(Color("bgColor"))
                    
                    WebImage(url: URL(string: self.avatar))
                        .resizable()
                        .placeholder{ Image("empty-profile").resizable().frame(width: 30, height: 30, alignment: .center).scaledToFill() }
                        .indicator(.activity)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 30, height: 30, alignment: .center)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                }
            }.buttonStyle(ClickButtonStyle())
            
            VStack(alignment: .leading, spacing: 2.5) {
                Text(self.fullName + "   \(reply.date.getElapsedInterval(lastMsg: "just now"))")
                    .font(.caption)
                    .fontWeight(.none)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                HStack {
                    Capsule()
                        .frame(width: 2.5, alignment: .center)
                        .frame(minHeight: 20)
                        .foregroundColor(.blue)
                    
                    Text(reply.text)
                        .font(.none)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }.onAppear() {
            do {
                let realm = try Realm(configuration: Realm.Configuration(schemaVersion: 1))
                if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: Int(self.reply.fromId) ?? 0) {
                    if foundContact.avatar == "" {
                        Request.users(withIDs: [NSNumber(value: Int(self.reply.fromId) ?? 0)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            for i in users {
                                if i.id == UInt(self.reply.fromId) {
                                    self.avatar = PersistenceManager().getCubeProfileImage(usersID: i) ?? ""
                                    self.fullName = i.fullName ?? "no name"
                                }
                            }
                        })
                    } else {
                        self.avatar = foundContact.avatar
                        self.fullName = foundContact.fullName
                    }
                } else {
                    Request.users(withIDs: [NSNumber(value: Int(self.reply.fromId) ?? 0)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                        for i in users {
                            if i.id == UInt(self.reply.fromId) {
                                self.avatar = PersistenceManager().getCubeProfileImage(usersID: i) ?? ""
                                self.fullName = i.fullName ?? "no name"
                            }
                        }
                    })
                }
            } catch { }
        }
    }
}
