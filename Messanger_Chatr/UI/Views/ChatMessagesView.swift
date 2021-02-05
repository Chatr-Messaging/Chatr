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
    @Binding var activeView: CGSize
    @Binding var keyboardChange: CGFloat
    @Binding var dialogID: String
    @Binding var textFieldHeight: CGFloat
    @Binding var keyboardDragState: CGSize
    @Binding var hasAttachment: Bool
    @Binding var newDialogFromSharedContact: Int
    @State var isLoadingMore: Bool = false
    @State var isLoadingAni: Bool = false
    @State private var delayViewMessages: Bool = false
    @State private var firstScroll: Bool = true
    @State private var isPrevious: Bool = true
    @State private var mesgCount: Int = -1
    let fontSize: CGFloat = CGFloat(12)
    
    var body: some View {
        let currentMessages = self.auth.messages.selectedDialog(dialogID: self.dialogID)
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
                            Request.countOfMessages(forDialogID: self.dialogID, extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
                                print("success getting message count: \(count)")
                                self.mesgCount = Int(count)
                            })
                        }
                    }
                
                //CUSTOM MESSAGE BUBBLE:
                if self.delayViewMessages {
                    ScrollViewReader { reader in
                        VStack {
                            ForEach(currentMessages.indices, id: \.self) { message in
                                let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                let notLast = currentMessages[message] != currentMessages.last
                                let topMsg = currentMessages[message] == currentMessages.first

                                if topMsg && currentMessages.count > 20 {
                                    Button(action: {
                                        self.firstScroll = false
                                        self.auth.acceptScrolls = false
                                        changeMessageRealmData.loadMoreMessages(dialogID: currentMessages[message].dialogID, currentCount: currentMessages.count, completion: { _ in
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
                                
                                VStack(spacing: 0) {
                                    HStack() {
                                        if messagePosition == .right { Spacer() }

                                        if currentMessages[message].image != "" {
                                            AttachmentBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                        } else if currentMessages[message].imageType == "video" {
                                            Text("Video here")
                                        } else if currentMessages[message].contactID != 0 {
                                            ContactBubble(chatContact: self.$newDialogFromSharedContact, message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                        } else if currentMessages[message].longitude != 0 && currentMessages[message].latitude != 0 {
                                            LocationBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                        } else {
                                            TextBubble(message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .environmentObject(self.auth)
                                                .animation(.spring(response: 0.65, dampingFraction: 0.55, blendDuration: 0))
                                                .contentShape(Rectangle())
                                                .transition(AnyTransition.scale)
                                        }
                                        
                                        if messagePosition == .left { Spacer() }
                                    }.id(currentMessages[message].id)
                                    .background(Color.clear)
                                    .padding(.horizontal, 25)
                                    .padding(.top, topMsg && currentMessages.count < 20 ? 20 : 0)
                                    .padding(.bottom, self.hasPrevious(index: message) ? -6 : 10)
                                    .padding(.bottom, notLast ? 0 : self.keyboardChange + (self.textFieldHeight <= 120 ? self.textFieldHeight : 120) + (self.hasAttachment ? 95 : 0) + 50)
                                }.onAppear {
                                    if currentMessages[message].id == currentMessages.last?.id {
                                        reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                                    }
                                }
                            }.contentShape(Rectangle())
                        }.onChange(of: self.keyboardChange) { value in
                            if value > 0 {
                                withAnimation {
                                    reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                                }
                            }
                        }.onChange(of: currentMessages) { msg in
                            reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                        }
                    }.resignKeyboardOnDragGesture()
                }
            }.onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.delayViewMessages = true
                    self.auth.acceptScrolls = true
                }
            }
        }.frame(width: Constants.screenWidth)
        .contentShape(Rectangle())
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                changeMessageRealmData.getMessageUpdates(dialogID: self.dialogID, completion: { _ in
                    self.auth.acceptScrolls = true
                    self.firstScroll = true
                })
                
                Request.updateDialog(withID: self.dialogID, update: UpdateChatDialogParameters(), successBlock: { dialog in
                    self.auth.selectedConnectyDialog = dialog
                    dialog.sendUserStoppedTyping()
                    
                    dialog.onUserIsTyping = { (userID: UInt) in
                        if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                            withAnimation { () -> () in
                                changeMessageRealmData.addTypingMessage(userID: String(userID), dialogID: self.dialogID)
                            }
                        }
                    }
                    
                    dialog.onUserStoppedTyping = { (userID: UInt) in
                        if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                            withAnimation { () -> () in
                                changeMessageRealmData.removeTypingMessage(userID: String(userID), dialogID: self.dialogID)
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
                })
            }
        }
    }
    
    func hasPrevious(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)
        return result[index] != result.last ? (result[index + 1].senderID == result[index].senderID ? true : false) : false
    }
}
