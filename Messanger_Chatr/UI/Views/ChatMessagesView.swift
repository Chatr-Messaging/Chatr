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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ChatMessagesView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel = ChatMessageViewModel()
    @Binding var activeView: CGSize
    @Binding var keyboardChange: CGFloat
    @Binding var dialogID: String
    @Binding var textFieldHeight: CGFloat
    @Binding var keyboardDragState: CGSize
    @Binding var hasAttachment: Bool
    @Binding var newDialogFromSharedContact: Int
    @State private var delayViewMessages: Bool = false
    @State private var firstScroll: Bool = true
    @State private var totalMessageCount: Int = -1
    @State private var unreadMessageCount: Int = 0
    @State private var scrollPage: Int = 1
    let keyboard = KeyboardObserver()
    let pageShowCount = 15
    var maxPagination: Int {
        if self.auth.messages.selectedDialog(dialogID: self.dialogID).count < pageShowCount {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        } else {
            return pageShowCount * self.scrollPage
        }
    }
    var minPagination: Int {
        if scrollPage <= 2 {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        } else {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count - (pageShowCount * (self.scrollPage - 2))
        }
    }

    var body: some View {
        let currentMessages = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        if UserDefaults.standard.bool(forKey: "localOpen") {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack() {
                    //No Messages found:
                    Text(self.totalMessageCount == 0 ? "no messages found" : self.totalMessageCount == -1 ? "loading messages..." : "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: Constants.screenWidth)
                        .padding(.all, self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 20)
                        .offset(y: self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 40)
                        .opacity(self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 1)
                    
                    //CUSTOM MESSAGE BUBBLE:
                    if self.delayViewMessages {
                        ScrollViewReader { reader in
                            VStack {
                                ForEach(currentMessages.count - self.maxPagination ..< self.minPagination, id: \.self) { message in
                                    let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                    let notLast = currentMessages[message].id != currentMessages.last?.id
                                    let topMsg = currentMessages[message].id == currentMessages.first?.id

                                    if message == (currentMessages.count - self.maxPagination) {
                                        VStack(alignment: .center) {
                                            //let load = geo.frame(in: .global).origin.y - 200 > -geo.frame(in: .global).minY
                                            
                                            //if load && !firstScroll {
                                                //Text("loading...")
                                                    //.font(.caption)
                                                    //.foregroundColor(.secondary)
//                                                        .onAppear {
//                                                            print("From Empty view the load is: \(load) origin: \(geo.frame(in: .global).origin.y)")
//                                                            changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 1), skip: self.minPagination, completion: { _ in
//                                                                DispatchQueue.main.async {
//                                                                    self.scrollPage += 1
//                                                                }
//                                                            })
//                                                        }
                                            //}
                                            Button(action: {
                                                self.firstScroll = false

                                                changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 1), skip: self.minPagination - currentMessages.count, completion: { _ in
                                                    DispatchQueue.main.async {
                                                        self.scrollPage += 1
                                                        withAnimation {
                                                            reader.scrollTo(currentMessages[message].id, anchor: .top)
                                                        }
                                                    }
                                                })
                                            }, label: {
                                                Text("Load More...")
                                                    .foregroundColor(.blue)
                                            }).padding(.top)
                                        }
                                    }

                                    VStack(spacing: 0) {
                                        HStack() {
                                            if messagePosition == .right { Spacer() }

                                            ContainerBubble(viewModel: self.viewModel, newDialogFromSharedContact: self.$newDialogFromSharedContact, message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message))
                                                .transition(AnyTransition.scale)
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                                .fixedSize(horizontal: false, vertical: true)
                                                .animation(.spring(response: 0.58, dampingFraction: 0.6, blendDuration: 0))
                                                .padding(.horizontal, 25)
                                                .padding(.bottom, self.hasPrevious(index: message) ? -6 : 10)
                                                .padding(.bottom, notLast ? 0 : self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 95 : 0) + 32)
                                                .id(currentMessages[message].id)

                                            if messagePosition == .left { Spacer() }
                                        }.frame(width: Constants.screenWidth)
                                        .background(Color.clear)
                                        .padding(.top, topMsg && currentMessages.count < 20 ? 20 : 0)
                                    }.onAppear {
                                        if !notLast {
                                            if self.firstScroll {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                                    self.firstScroll = false
                                                }
                                            } else {
                                                withAnimation(Animation.easeOut(duration: 0.6).delay(0.1)) {
                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                                }
                                            }
                                        }
                                    }
                                }.contentShape(Rectangle())
                            }.background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                    value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) {
                                print("offset >> \($0)")
                                if $0 > -1.34 && $0 < 0 {
                                    print("ran the laod more...")
                                    changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 1), skip: self.minPagination - currentMessages.count, completion: { _ in
                                        DispatchQueue.main.async {
                                            self.scrollPage += 1
//                                            withAnimation(Animation.easeOut(duration: 0.6).delay(0.1)) {
//                                                reader.scrollTo(currentMessages[currentMessages.count - self.maxPagination].id, anchor: .bottom)
//                                            }
                                        }
                                    })
                                }
                            }
                            .onAppear {
                                keyboard.observe { (event) in
                                    let keyboardFrameEnd = event.keyboardFrameEnd

                                    switch event.type {
                                    case .willShow:
                                        UIView.animate(withDuration: event.duration, delay: 0.0, options: [event.options], animations: {
                                            self.keyboardChange = keyboardFrameEnd.height - 10
                                            reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                                        }, completion: nil)
                                       
                                    case .willHide:
                                        UIView.animate(withDuration: event.duration, delay: 0.0, options: [event.options], animations: {
                                            self.keyboardChange = 0
                                        }, completion: nil)

                                    default:
                                        break
                                    }
                                }
                            }.opacity(self.firstScroll ? 0 : 1)
                        }
                    }
                }//.resignKeyboardOnDragGesture()
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadDialog()
                        self.delayViewMessages = true
                    }
                }
            }.coordinateSpace(name: "scroll")
            .frame(width: Constants.screenWidth)
            .contentShape(Rectangle())
            .onAppear() {
                DispatchQueue.global(qos: .utility).async {
                    if !Session.current.tokenHasExpired {
                        Request.countOfMessages(forDialogID: self.dialogID, extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
                            if self.auth.messages.selectedDialog(dialogID: self.dialogID).count != Int(count) {
                                print("local and pulled do not match... pulling delta: \(count) && \(self.auth.messages.selectedDialog(dialogID: self.dialogID).count)")
                                changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: self.maxPagination, skip: self.minPagination - currentMessages.count, completion: { _ in })
                            }
                            DispatchQueue.main.async {
                                print("the total count for this dialog: \(count)")
                                self.totalMessageCount = Int(count)
                            }
                        })

                        Request.totalUnreadMessageCountForDialogs(withIDs: Set([self.dialogID]), successBlock: { (count, dialogs) in
                            DispatchQueue.main.async {
                                print("the count for this dialog: \(count)")
                                self.unreadMessageCount = Int(count)
                            }
                        })
                    }
                }
            }
        }
    }
    
    func hasPrevious(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)
        return result[index] != result.last ? (result[index + 1].senderID == result[index].senderID ? true : false) : false
    }
    
    func loadDialog() {
        DispatchQueue.global(qos: .utility).async {
            Request.updateDialog(withID: self.dialogID, update: UpdateChatDialogParameters(), successBlock: { dialog in
                self.auth.selectedConnectyDialog = dialog

                dialog.onUserIsTyping = { (userID: UInt) in
                    if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                        changeMessageRealmData.shared.addTypingMessage(userID: String(userID), dialogID: self.dialogID)
                    }
                }

                dialog.onUserStoppedTyping = { (userID: UInt) in
                    if userID != UserDefaults.standard.integer(forKey: "currentUserID") {
                        changeMessageRealmData.shared.removeTypingMessage(userID: String(userID), dialogID: self.dialogID)
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
                                dialog.sendUserStoppedTyping()
                            })
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !dialog.isJoined() {
                                dialog.join(completionBlock: { error in
                                    print("we have joined the dialog after atempt 2!! \(String(describing: error))")
                                    dialog.sendUserStoppedTyping()
                                })
                            }
                        }
                    }
                }
            })
        }
    }
}
