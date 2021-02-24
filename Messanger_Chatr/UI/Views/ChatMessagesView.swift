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
    @State private var isLoadingMore: Bool = false
    @State private var totalMessageCount: Int = -1
    @State private var unreadMessageCount: Int = 0
    @State private var scrollPage: Int = 1
    @State private var scrollToId: String = ""
    @State var topAvatarUrls: [String] = []
    let keyboard = KeyboardObserver()
    let pageShowCount = 15
    var maxPagination: Int {
        if self.auth.messages.selectedDialog(dialogID: self.dialogID).count < pageShowCount {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        } else if pageShowCount * self.scrollPage < self.totalMessageCount {
            return pageShowCount * self.scrollPage
        } else {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        }
    }
    var minPagination: Int {
        if scrollPage <= 2 {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        } else if pageShowCount * self.scrollPage < self.totalMessageCount {
            return self.auth.messages.selectedDialog(dialogID: self.dialogID).count - (pageShowCount * (self.scrollPage - 2))
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
                    if (self.totalMessageCount == 0 || self.maxPagination == self.totalMessageCount) {
                        VStack {
                            HStack(spacing: -7) {
                                ForEach(self.topAvatarUrls.indices, id: \.self) { url in
                                    if url < 7 {
                                        ZStack {
                                            Circle()
                                                .background(Color.clear)
                                                .frame(width: 30, height: 30, alignment: .center)

                                            WebImage(url: URL(string: self.topAvatarUrls[url]))
                                                .resizable()
                                                .placeholder{ Image("empty-profile").resizable().frame(width: 30, height: 30, alignment: .center).scaledToFill() }
                                                .indicator(.activity)
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .frame(width: 30, height: 30, alignment: .center)
                                                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2.2))
                                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                                            
                                            if url == 6 && self.topAvatarUrls.count >= 7 {
                                                Circle()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.black)
                                                    .opacity(0.4)
                                                
                                                Text("+\(self.topAvatarUrls.count - 6)")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                            }.padding(.top, 15)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.topAvatarUrls.removeAll()
                                    for occu in changeDialogRealmData.shared.getRealmDialog(dialogId: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").occupentsID {
                                        print("the found occc: \(occu)")
                                        self.viewModel.getUserAvatar(senderId: occu) { (avatar, _) in
                                            print("the found occc2222: \(avatar)")
                                            
                                            guard avatar != "self" else {
                                                self.topAvatarUrls.append(self.auth.profile.results.first?.avatar ?? "")
                                                return
                                            }
                                            self.topAvatarUrls.append(avatar)
                                        }
                                    }
                                }
                            }
                            
                            Text("Start of Chatr")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .padding(.top, 2.5)
                                .padding(.horizontal, 40)
                            
                            Text("created \(self.viewModel.dateFormatTime(date: changeDialogRealmData.shared.getRealmDialog(dialogId: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").createdAt))")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .offset(y: 2)

                            Divider()
                                .padding(.top, 10)
                                .padding(.horizontal, 30)
                        }
                    }

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
                            VStack(alignment: .center) {
                                ForEach(currentMessages.count - self.maxPagination ..< self.minPagination, id: \.self) { message in
                                    let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                    let notLast = currentMessages[message].id != currentMessages.last?.id
                                    //let topMsg = currentMessages[message].id == currentMessages.first?.id
                                    if needsTimestamp(index: message) {
                                        Text("\(self.viewModel.dateFormatTime(date: currentMessages[message].date))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, message == 0 ? 0 : 15)
                                            .padding(.bottom, 15)
                                    }
                                    
                                    if message == (currentMessages.count - self.maxPagination) {
                                        VStack(alignment: .center) {
                                            if self.isLoadingMore && !firstScroll && self.maxPagination != self.totalMessageCount {
                                                Circle()
                                                    .trim(from: 0, to: 0.8)
                                                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                    .frame(width: 20, height: 20)
                                                    .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                                                    .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                                    .rotationEffect(.degrees(self.isLoadingMore ? 360 : 0))
                                                    .padding(.bottom, 10)

                                                Text("loading more...")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
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
                                    }.onAppear {
                                        //print("the adding mesg id is: \(currentMessages[message].id) but the on i am looking for is: \(currentMessages[(pageShowCount * self.scrollPage) + self.pageShowCount].id) at index: \((pageShowCount * self.scrollPage) - self.pageShowCount)")
                                        if !notLast {
                                            print("called on appear: \(message)")
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

                                        if self.scrollToId == currentMessages[message].id {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                reader.scrollTo(currentMessages[message].id, anchor: .top)
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
                                if $0 < 0 && !firstScroll && !self.isLoadingMore && self.maxPagination != self.totalMessageCount {
                                    self.isLoadingMore = true
                                    changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 0), skip: currentMessages.count - self.minPagination, completion: { _ in
                                        DispatchQueue.main.async {
                                            self.scrollToId = currentMessages[currentMessages.count - self.maxPagination - 1].id
                                            self.scrollPage += 1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.isLoadingMore = false
                                        }

                                        //need to make the very last ending of convo scroll to item due to the page not being divisible.
                                        //also need to add the scroll down functions
                                        print("From Empty view the load limit: \(pageShowCount * (self.scrollPage + 1)) and the skip:\(currentMessages.count - self.minPagination)...... the indexes are \(currentMessages.count - self.maxPagination).....< \(self.minPagination) anddddd nowww the scroll to index is: \(currentMessages.count - self.maxPagination - 1)")
                                        
                                        if self.auth.messages.selectedDialog(dialogID: self.dialogID).count != self.totalMessageCount {
                                            print("pulling delta from scrolling...\(self.totalMessageCount) && \(self.auth.messages.selectedDialog(dialogID: self.dialogID).count)")
                                            changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: (pageShowCount * self.scrollPage + 50), skip: currentMessages.count - self.minPagination, completion: { _ in })
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
                }
            }.coordinateSpace(name: "scroll")
            .frame(width: Constants.screenWidth)
            .contentShape(Rectangle())
            .onAppear() {
                DispatchQueue.global(qos: .utility).async {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.loadDialog()
                        self.delayViewMessages = true
                    }
                    
                    if !Session.current.tokenHasExpired {
                        Request.countOfMessages(forDialogID: self.dialogID, extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
                            if self.auth.messages.selectedDialog(dialogID: self.dialogID).count != Int(count) {
                                print("local and pulled do not match... pulling delta: \(count) && \(self.auth.messages.selectedDialog(dialogID: self.dialogID).count)")
                                changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * self.scrollPage, skip: 0, completion: { _ in })
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
    
    func needsTimestamp(index: Int) -> Bool {
        //need to filter out the deleted messages
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.first ? (result[index - 1].senderID != result[index].senderID ? (result[index].date >= result[index - 1].date.addingTimeInterval(86400) ? true : false) : false) : false
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
