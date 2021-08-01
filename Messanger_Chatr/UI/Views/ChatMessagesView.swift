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
import Firebase

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct ChatMessagesView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: ChatMessageViewModel
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
    @State private var permissionLoadMore: Bool = true
    @State private var scrollPage: Int = 0
    @State private var scrollToId: String = ""
    @State private var maxMessageCount: Int = -1
    @State private var scrollViewHeight: CGFloat = 0
    var namespace: Namespace.ID
    let keyboard = KeyboardObserver()
    let pageShowCount = 10
    //let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count
    var tempPagination: Int {
        if maxMessageCount > pageShowCount {
            return maxMessageCount - pageShowCount
        } else {
            return 0
        }
    }
    
    var currentMessages: Results<MessageStruct> {
        return auth.messages.selectedDialog(dialogID: self.dialogID)
    }

    var minPagination: Int {
        //let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count

        guard UserDefaults.standard.bool(forKey: "localOpen") else {
            return currentMessages.count
        }

        if scrollPage <= 2 {
            return currentMessages.count
        } else if pageShowCount * self.scrollPage < self.maxMessageCount {
            print("the max message pagintonnn: \(pageShowCount * self.scrollPage) && \(self.maxMessageCount)")
            return currentMessages.count - (pageShowCount * (self.scrollPage - 2))
        } else {
            print("the min pagintonnn: \(pageShowCount * self.scrollPage) && \(pageShowCount * 2)")
            return pageShowCount * 2
        }
    }

    var maxPagination: Int {
        guard UserDefaults.standard.bool(forKey: "localOpen") else {
            return 0
        }
        //let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count

        if currentMessages.count < pageShowCount {
            return 0
        } else if pageShowCount * self.scrollPage < currentMessages.count {
            return currentMessages.count - (pageShowCount * self.scrollPage)
        } else {
            return 0
        }
    }

    var body: some View {
        //let currentMessages = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        if UserDefaults.standard.bool(forKey: "localOpen") {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .center) {
                    Text(self.maxMessageCount == 0 ? "no messages found" : maxMessageCount == -1 ? "loading messages..." : "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 160)
                        .padding(.all, self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 20)
                        .offset(y: self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 40)
                        .opacity(self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 1)
                    
                    //CUSTOM MESSAGE BUBBLE:
                    if self.delayViewMessages {
                        ScrollViewReader { reader in
                            VStack(alignment: .center) {
                                //Spacer()
                                ForEach(maxPagination ..< currentMessages.count, id: \.self) { message in
                                    let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                    let topMsg = currentMessages[message].id == currentMessages.first?.id && currentMessages.count >= self.maxMessageCount

                                    if topMsg {
                                        VStack {
                                            Text("Beginning of Chat")
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
                                                .padding(.top, 5)
                                                .padding(.bottom)
                                                .padding(.horizontal, 30)
                                        }
                                    }
                                    
                                    if needsTimestamp(index: message) {
                                        Text("\(self.viewModel.dateFormatTime(date: currentMessages[message].date))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, message == 0 ? 0 : 15)
                                            .padding(.bottom, 15)
                                    }

                                    if self.isLoadingMore && !firstScroll && self.maxPagination != 0 && message == self.maxPagination {
                                        VStack(alignment: .center) {
                                            Circle()
                                                .trim(from: 0, to: 0.8)
                                                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                .frame(width: 20, height: 20)
                                                .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                                                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                                .rotationEffect(.degrees(self.isLoadingMore ? 360 : 0))

                                            Text("loading more...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    HStack() {
                                        if messagePosition == .right { Spacer() }
                                        let hasPrevious = self.hasPrevious(index: message)
                                        
                                        ContainerBubble(viewModel: self.viewModel, newDialogFromSharedContact: self.$newDialogFromSharedContact, isPriorWider: self.isPriorWider(index: message), message: currentMessages[message], messagePosition: messagePosition, hasPrior: hasPrevious, namespace: self.namespace)
                                            .environmentObject(self.auth)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.horizontal, 25)
                                            .padding(.trailing, messagePosition != .right ? 40 : 0)
                                            .padding(.leading, messagePosition == .right ? 40 : 0)
                                            .padding(.bottom, hasPrevious ? -6 : 10)
                                            //.padding(.bottom, notLast ? 0 : self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 110 : 0) + 32)
                                            .resignKeyboardOnDragGesture()
                                            .id(currentMessages[message].id)

                                        if messagePosition == .left { Spacer() }
                                    }.background(Color.clear)
                                    .onAppear {
                                        //print("the adding mesg id is: \(currentMessages[message].id) but the on i am looking for is: \(currentMessages[(pageShowCount * self.scrollPage) + self.pageShowCount].id) at index: \((pageShowCount * self.scrollPage) - self.pageShowCount)")
                                        let notLast = currentMessages[message].id != currentMessages.last?.id
                                        if !notLast {
                                            print("called on appear: \(message)")
                                            if self.firstScroll {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                                    print("scrolllling2222 is nowwww \(message)")
                                                    self.firstScroll = false
                                                }
                                            } else if self.scrollViewHeight > Constants.screenHeight * 0.8 && self.permissionLoadMore {
                                                print("scrolllling is nowwww \(self.scrollViewHeight) ** \(Constants.screenHeight * 0.8)")
                                                withAnimation(Animation.easeOut(duration: 0.25)) {
                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                                }
                                            }
                                        }

                                        if self.scrollToId == currentMessages[message].id {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                reader.scrollTo(currentMessages[message].id, anchor: .top)
                                                self.scrollToId = ""
                                            }
                                        }
                                    }
                                    .onDisappear {
                                        guard let prevIndex = currentMessages.firstIndex(of: currentMessages[message - 1]) else {
                                            return
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            withAnimation(Animation.easeOut(duration: 0.30)) {
                                                reader.scrollTo(currentMessages[prevIndex].id, anchor: .bottom)
                                            }
                                            self.scrollToId = ""
                                        }
                                    }
                                    
                                }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(Animation.easeOut(duration: 0.35)), removal: AnyTransition.move(edge: .bottom).animation(Animation.easeOut(duration: 0.35))))
                                .contentShape(Rectangle())
                            }.background(GeometryReader { fullView in
                                Color.clear.preference(key: ViewOffsetKey.self,
                                    value: -fullView.frame(in: .named("scroll")).origin.y)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                        //If the 10 to show is not enough then show another page
                                            self.scrollViewHeight = fullView.size.height
                                            print("the view height on aprear: \(self.scrollViewHeight) ** \(Constants.screenHeight * 0.8)")
                                            if self.scrollViewHeight < Constants.screenHeight * 0.8, self.maxPagination != 0, self.scrollPage <= 1 {
                                                print("added another scroll pageee")
                                                //self.scrollToId = currentMessages.last?.id ?? ""
                                                self.scrollPage += 1
                                            }
                                        }
                                    }
                                    .onChange(of: fullView.size.height) { value in
                                        print("the view height isss: \(value)")
                                        self.scrollViewHeight = value
                                        if self.scrollViewHeight < Constants.screenHeight * 0.8, self.maxPagination != 0, self.scrollPage <= 1 {
                                            print("added another scroll page")
                                            //self.scrollToId = currentMessages.last?.id ?? ""
                                            self.scrollPage += 2
                                        }
                                    }
                            })
                            .onPreferenceChange(ViewOffsetKey.self) {
                                guard self.activeView.height == 0 else {
                                    print("dragging down dialog cell...")
                                    return
                                }

                                print("the offset is: \($0)")
                                if $0 < -60 && !firstScroll, !self.isLoadingMore, self.permissionLoadMore {
                                    self.isLoadingMore = true
                                    self.permissionLoadMore = false
                                    //$0 > self.scrollViewHeight && self.minPagination != currentMessages.count {
                                    if self.maxPagination != 0 {
                                        //have more local data to load
                                        print("has more needs to just increase the local page \(self.maxMessageCount) && \(self.maxPagination) && \(currentMessages.count)")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                            self.scrollPage += 1
                                            if self.maxPagination != 0 {
                                                print("scrolling tooo: \(self.maxPagination + pageShowCount - 1)")
                                                self.scrollToId = self.currentMessages[self.maxPagination + pageShowCount - 1].id
                                            } else {
                                                let divisor = currentMessages.count / pageShowCount
                                                let remainder = currentMessages.count - divisor * pageShowCount
                                                let scrollToIndex = remainder == 0 ? pageShowCount - 1 : remainder - 1
                                                print("the scroll to max is attt 0: \(divisor) && \(remainder) && \(scrollToIndex)")
                                                self.scrollToId = currentMessages[scrollToIndex].id
                                            }

                                            self.isLoadingMore = false
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                self.permissionLoadMore = true
                                            }
                                        }
                                    } else if self.maxMessageCount > currentMessages.count {
                                        //loading more from server
                                        print("local has more to fetch \(self.maxMessageCount) && \(self.viewModel.unreadMessageCount) && \(currentMessages.count) limit: \(pageShowCount * (self.scrollPage + 1)) skip: \(currentMessages.count)")

                                        changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 1), skip: currentMessages.count, completion: { _ in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                                self.scrollPage += 1

                                                if self.maxMessageCount >= currentMessages.count {
                                                    print("scrolling to: \(pageShowCount - 1)")
                                                    self.scrollToId = self.currentMessages[pageShowCount - 1].id
                                                } else {
                                                    let divisor = currentMessages.count / pageShowCount
                                                    let remainder = currentMessages.count - divisor * pageShowCount
                                                    let scrollToIndex = remainder == 0 ? pageShowCount - 1 : remainder - 1
                                                    print("the scroll to max is at 0: \(divisor) && \(remainder) && \(scrollToIndex)")
                                                    self.scrollToId = currentMessages[scrollToIndex].id
                                                }
                                                self.isLoadingMore = false
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                    self.permissionLoadMore = true
                                                }
                                            }
                                        })
                                    } else {
                                        //do nothing.. turn everything back
                                        print("has it all good \(maxMessageCount) && \(currentMessages.count)")
                                        
                                        let divisor = currentMessages.count / pageShowCount
                                        let remainder = currentMessages.count - divisor * pageShowCount
                                        let scrollToIndex = remainder == 0 ? pageShowCount - 1 : remainder - 1

                                        print("the scroll to max is at 0: \(divisor) && \(remainder) && \(scrollToIndex)")
                                        self.scrollToId = currentMessages[scrollToIndex].id
                                        self.isLoadingMore = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                            self.permissionLoadMore = true
                                        }
                                    }
                                }
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                    keyboard.observe { (event) in
                                        guard !self.viewModel.isDetailOpen else { return }

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
                                }
                            }
                        }
                    }
                }.ignoresSafeArea(.keyboard, edges: .bottom)
                .resignKeyboardOnDragGesture()
            }
            .bottomSafeAreaInset(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.clear)
                    .frame(height: self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 110 : 0) + 38)
            )
            .coordinateSpace(name: "scroll")
            .frame(width: Constants.screenWidth)
            .contentShape(Rectangle())
            .onAppear() {
                //self.dialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    print("the dialog id is: \(dialogID)")
                    self.maxMessageCount = self.currentMessages.count
                    self.delayViewMessages = true
                    self.scrollPage += 1
                    viewModel.loadDialog(auth: auth, dialogId: dialogID, completion: {
                        print("done loading dialogggg: \(dialogID) && \(self.viewModel.totalMessageCount) && \(currentMessages.count) &&& \(self.viewModel.unreadMessageCount)")
                        self.maxMessageCount = self.viewModel.totalMessageCount
                        if (self.viewModel.totalMessageCount > self.currentMessages.count && self.viewModel.unreadMessageCount != 0) || self.currentMessages.count == 0 {
                            print("local and pulled do not match... pulling delta: \(self.viewModel.totalMessageCount) && \(self.currentMessages.count)")
                            changeMessageRealmData.shared.getMessageUpdates(dialogID: dialogID, limit: pageShowCount * (self.scrollPage), skip: currentMessages.count - self.minPagination, completion: { done in
                                DispatchQueue.main.async {
                                    
                                    print("STARTTT Load more From Empty view the load limit: \(pageShowCount * (self.scrollPage + 1)) and the skip:\(currentMessages.count - self.minPagination)...... the indexes are \(self.maxPagination).....< \(self.minPagination) anddddd nowww the scroll to index is: \(self.maxPagination + 1)")
                                }
                            })
                        } else {
                            DispatchQueue.main.async {
                                //self.scrollPage += 1
                                
                                print("STARTTT From Empty view the load limit: \(pageShowCount * (self.scrollPage)) and the skip:\(currentMessages.count - self.minPagination).....\(self.maxMessageCount). the indexes are \(self.maxPagination).....< \(self.minPagination) anddddd nowww the scroll to index is: \(self.maxPagination + 1)")
                            }
                        }

                        //self.loadUnreadMessages()
                        self.observePinnedMessages()
                    })
                }
            }.onDisappear() {
                self.scrollPage = 0
                self.maxMessageCount = -1
                self.scrollViewHeight = 0
                self.firstScroll = true
                self.dialogID = ""
                self.delayViewMessages = false
            }
        }
    }

    func hasPrevious(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)
        print("has previous")
        
        return result[index].id != result.last?.id ? (result[index + 1].senderID == result[index].senderID && result[index + 1].date <= result[index].date.addingTimeInterval(86400) ? true : false) : false
    }

    func needsTimestamp(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.first ? (result[index].messageState != .isTyping && result[index].date >= result[index - 1].date.addingTimeInterval(86400) ? true : false) : false
    }
    
    func isPriorWider(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.first ? (result[index].senderID == result[index - 1].senderID && (result[index].date >= result[index - 1].date.addingTimeInterval(86400) ? false : true) && result[index].bubbleWidth > result[index - 1].bubbleWidth ? false : true) : true //- (result[index].dislikedId.count >= 1 && result[index].likedId.count >= 1 ? 48 : 16)
    }
    
    func loadUnreadMessages() {
        //Need to come back when the total count request works
        Request.totalUnreadMessageCountForDialogs(withIDs: Set([self.dialogID]), successBlock: { (unread, directory) in
            print("the unread count for this dialogzzz: \(unread) && \(directory)")
            self.maxMessageCount = currentMessages.count
            self.viewModel.unreadMessageCount = Int(unread)
            if unread != 0 {
                changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: currentMessages.count + Int(unread > 40 ? 40 : unread), skip: currentMessages.count - self.minPagination, completion: { _ in
                    self.maxMessageCount = currentMessages.count
                })
            }
        })
    }
    
    func loadMoreMessages() {
        
    }
    
    func observePinnedMessages() {
        let msg = Database.database().reference().child("Dialogs").child(self.dialogID).child("pinned")

        msg.observe(.childAdded, with: { snapAdded in
            changeDialogRealmData.shared.addDialogPin(messageId: snapAdded.key, dialogID: self.dialogID)
        })

        msg.observe(.childRemoved, with: { snapRemoved in
            changeDialogRealmData.shared.removeDialogPin(messageId: snapRemoved.key, dialogID: self.dialogID)
        })
    }
}
