//
//  ChatMessagesView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI
import ConnectyCube

struct ChatMessagesView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var messages = MessagesRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(MessageStruct.self))
    @Binding var activeView: CGSize
    @Binding var keyboardChange: CGFloat
    @Binding var dialogID: String
    @Binding var textFieldHeight: CGFloat
    @Binding var keyboardDragState: CGSize
    @Binding var hasAttachment: Bool
    @Binding var newDialogFromSharedContact: Int
    @State var selectedID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
    @State var isLoadingMore: Bool = false
    @State var isLoadingAni: Bool = false
    @State private var delayViewMessages: Bool = false
    @State private var firstScroll: Bool = false
    @State private var isPrevious: Bool = true
    @State private var mesgCount: Int = -1

//    @ObservedObject var messages = MessagesRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(MessageStruct.self).filter(NSPredicate(format: "dialogID == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")).sorted(byKeyPath: "date", ascending: true))
    
    var body: some View {
        let currentMessages = self.messages.selectedDialog(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
        ZStack(alignment: .center) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack() {
                    //No Messages found:
                    Text(self.mesgCount == 0 ? "no messages found" : self.mesgCount == -1 ? "loading messages..." : "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: Constants.screenWidth)
                        .padding(.all, self.mesgCount >= 1 && self.delayViewMessages ? 0 : 20)
                        .offset(y: self.mesgCount >= 1 && self.delayViewMessages ? 0 : 40)
                        .opacity(self.mesgCount >= 1 && self.delayViewMessages ? 0 : 1)
                        .onAppear() {
                            if !Session.current.tokenHasExpired {
                                Request.countOfMessages(forDialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
                                    print("success getting message count: \(count)")
                                    self.mesgCount = Int(count)
                                }, errorBlock: { error in
                                    print("error getting message count: \(error.localizedDescription)")
                                })
                            }
                        }
                    

                    //CUSTOM MESSAGE BUBBLE:
                    if self.delayViewMessages {
                        ScrollViewReader { reader in
                            ForEach(currentMessages.indices, id: \.self) { message in
                                let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                let notLast = currentMessages[message] != currentMessages.last
                                let topMsg = currentMessages[message] == currentMessages.first

                                if topMsg && currentMessages.count > 20 {
                                    Button(action: {
                                        self.firstScroll = false
                                        self.auth.acceptScrolls = false
                                        changeMessageRealmData().loadMoreMessages(dialogID: currentMessages[message].dialogID, currentCount: currentMessages.count, completion: { _ in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                withAnimation {
                                                    reader.scrollTo(currentMessages[message + 20].id, anchor: .top)
                                                }
                                            }
                                        })
                                        
                                    }, label: {
                                        Text("Load More...")
                                            .foregroundColor(.blue)
                                    }).padding(.top)
                                }
                                
                                VStack {
                                    HStack() {
                                        if messagePosition == .right { Spacer() }
                                        if currentMessages[message].image != "" {
                                            AttachmentBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                        } else if currentMessages[message].contactID != 0 {
                                            ContactBubble(chatContact: self.$newDialogFromSharedContact, message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                        } else if currentMessages[message].longitude != 0 && self.messages.results[message].latitude != 0 {
                                            LocationBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                        } else {
                                            TextBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                                .transition(AnyTransition.scale)
                                        }
                                        
                                        if messagePosition == .left { Spacer() }
                                    }.background(Color.clear)
                                    .padding(.horizontal, 25)
                                    .padding(.top, topMsg && currentMessages.count < 20 ? 20 : 0)
                                    .padding(.bottom, self.hasPrevious(index: message) ? -4 : 15)
                                    .padding(.bottom, notLast && self.hasPrevious(index: message) && currentMessages[message].messageState != .error ? 0 : 10)
                                    .padding(.bottom, notLast ? 0 : self.keyboardChange + (self.textFieldHeight <= 120 ? self.textFieldHeight : 120) + (self.hasAttachment ? 95 : 0) + 50)
                                }.id(currentMessages[message].id)
                                .onAppear() {
                                    if !notLast {
                                        withAnimation {
                                            reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                        }
                                    }
                                }

                                if !notLast && self.auth.acceptScrolls {
                                    Scroll(reader: reader, id: self.messages.results[message].id)
                                }
                            }
                            .frame(width: Constants.screenWidth)
                            .contentShape(Rectangle())
                            //.opacity(self.delayViewMessages ? 1 : 0)
//                            .onAppear() {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
//                                }
//                            }
//                            .onChange(of: self.keyboardChange) { value in
//                                //self.auth.acceptScrolls = true
//                                print("keyboard changed: \(currentMessages.last?.id ?? "") && \(value)")
//                                if value > 0 {
//                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                        withAnimation {
//                                            reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
//                                        }
//                                    }
//                                }
//                            }
                        }.resignKeyboardOnDragGesture()
                    }
                }
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.delayViewMessages = true
                        self.auth.acceptScrolls = true
                    }
                }
            }.contentShape(Rectangle())
        }.contentShape(Rectangle())//.frame(width: Constants.screenWidth, height: Constants.screenHeight - 50 - (self.textFieldHeight <= 120 ? self.textFieldHeight : 120) - self.keyboardChange + self.keyboardDragState.height - (self.hasAttachment ? 95 : 0), alignment: .bottom)
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                changeMessageRealmData().getMessageUpdates(dialogID: self.selectedID, completion: { _ in
                    self.auth.acceptScrolls = true
                    self.firstScroll = true
                })
                
                let extRequest : [String: String] = ["sort_desc" : "lastMessageDate"]
                Request.dialogs(with: Paginator.limit(20, skip: 0), extendedRequest: extRequest, successBlock: { (dialogs, usersIDs, paginator) in
                    for dialog in dialogs {
                        if dialog.id == self.selectedID {
                            self.auth.selectedConnectyDialog = dialog
                            dialog.sendUserStoppedTyping()
                            
                            dialog.onUserIsTyping = { (userID: UInt) in
                                //print("this dude is typing!!: \(userID)")
                                if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    withAnimation { () -> () in
                                        changeMessageRealmData().addTypingMessage(userID: String(userID), dialogID: self.selectedID)
                                    }
                                }
                            }
                            
                            dialog.onUserStoppedTyping = { (userID: UInt) in
                                //print("this dude STOPPED typing!!: \(userID)")
                                if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    withAnimation { () -> () in
                                        changeMessageRealmData().removeTypingMessage(userID: String(userID), dialogID: self.selectedID)
                                    }
                                }
                            }
                            
                            if dialog.type == .group || dialog.type == .public {
                                
                                dialog.requestOnlineUsers(completionBlock: { (online, error) in
                                    print("The online count is!!: \(String(describing: online?.count))")
                                    self.auth.onlineCount = online?.count ?? 0
                                })
                                
                                dialog.onUpdateOccupant = { (userID: UInt) in
                                    print("update occupant: \(userID)")
                                    self.auth.setOnlineCount()
                                }
                                
                                dialog.onJoinOccupant = { (userID: UInt) in
                                    print("on join occupant: \(userID)")
                                    self.auth.setOnlineCount()
                                }
                                
                                dialog.onLeaveOccupant = { (userID: UInt) in
                                    print("on leave occupant: \(userID)")
                                    self.auth.setOnlineCount()
                                }
                                
                                if Chat.instance.isConnected || !Chat.instance.isConnecting {
                                    if !dialog.isJoined() {
                                        dialog.join(completionBlock: { error in
                                            print("we have joined the dialog!! \(String(describing: error))")
                                        })
                                    }
                                } else {
                                    ChatrApp.connect()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        if !dialog.isJoined() {
                                            dialog.join(completionBlock: { error in
                                                print("we have joined the dialog after atempt 2!! \(String(describing: error))")
                                            })
                                        }
                                    }
                                }
                            }
                            
                            print("done pulling the dialog! \(dialog.id ?? "")")
                            
                            break
                        }
                    }
                })
                
            }
        }
    }
    
    func Scroll(reader: ScrollViewProxy, id: String) -> some View {
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.firstScroll ? 0.05 : 0.05)) {
            withAnimation {
                reader.scrollTo(id, anchor: .bottom)
            }
//            if self.firstScroll {
               // withAnimation {
                    //reader.scrollTo(id, anchor: .bottom)
//                    self.auth.acceptScrolls = false
//                    print("scroll ani \(id)")
                //}
//            } else {
                //reader.scrollTo(id, anchor: .bottom)
                self.firstScroll = false
                //self.auth.acceptScrolls = false
//                print("NOOOO scroll ani \(id)")
//            }
        }
        return EmptyView()
    }
    
    func hasPrevious(index: Int) -> Bool {
        let result = self.messages.selectedDialog(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
        return result[index] != result.last ? (result[index + 1].senderID == result[index].senderID ? true : false) : false
    }
}
