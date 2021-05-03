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
    @State private var totalMessageCount: Int = -1
    @State private var unreadMessageCount: Int = 0
    @State private var scrollPage: Int = 1
    @State private var scrollToId: String = ""
    @State var topAvatarUrls: [String] = []
    var namespace: Namespace.ID
    let keyboard = KeyboardObserver()
    let pageShowCount = 7
    var tempPagination: Int {
        let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        if count > pageShowCount {
            return count - pageShowCount
        } else {
            return 0
        }
    }
    var minPagination: Int {
        guard UserDefaults.standard.bool(forKey: "localOpen") else {
            return 0
        }
        let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count
        
        if scrollPage <= 2 {
            return count
        } else if pageShowCount * self.scrollPage < count {
            return count - (pageShowCount * (self.scrollPage - 2))
        } else {
            return count - (pageShowCount * (self.scrollPage - 2))
        }
    }
    var maxPagination: Int {
        guard UserDefaults.standard.bool(forKey: "localOpen") else {
            return 0
        }
        let count = self.auth.messages.selectedDialog(dialogID: self.dialogID).count

        if count < pageShowCount {
            return 0
        } else if pageShowCount * self.scrollPage < count {
            guard minPagination > pageShowCount * self.scrollPage else {
                return 0
            }

            return pageShowCount * self.scrollPage
        } else {
            return 0
        }
    }

    var body: some View {
        let currentMessages = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        if UserDefaults.standard.bool(forKey: "localOpen") {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .center) {
                    Text(self.totalMessageCount == 0 ? "no messages found" : self.totalMessageCount == -1 ? "loading messages..." : "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 160)
                        .padding(.all, self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 20)
                        .offset(y: self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 40)
                        .opacity(self.totalMessageCount >= 1 && self.delayViewMessages ? 0 : 1)
                    
                    //CUSTOM MESSAGE BUBBLE:
                    if self.delayViewMessages {
                        ScrollViewReader { reader in
                            VStack(alignment: .center) {
                                ForEach(tempPagination ..< currentMessages.count, id: \.self) { message in
                                    let messagePosition: messagePosition = UInt(currentMessages[message].senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left
                                    let notLast = currentMessages[message].id != currentMessages.last?.id
                                    let topMsg = currentMessages[message].id == currentMessages.first?.id

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
                                                .padding(.top, 10)
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
                                    
                                    if message == self.maxPagination {
                                        VStack(alignment: .center) {
                                            if self.isLoadingMore && !firstScroll && self.maxPagination != 0 {
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
                                            
                                            ContainerBubble(viewModel: self.viewModel, newDialogFromSharedContact: self.$newDialogFromSharedContact, isPriorWider: self.isPriorWider(index: message), message: currentMessages[message], messagePosition: messagePosition, hasPrior: self.hasPrevious(index: message), namespace: self.namespace)
                                                .environmentObject(self.auth)
                                                .contentShape(Rectangle())
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.horizontal, 25)
                                                .padding(.trailing, messagePosition != .right ? 40 : 0)
                                                .padding(.leading, messagePosition == .right ? 40 : 0)
                                                .padding(.bottom, self.hasPrevious(index: message) ? -6 : 10)
                                                .padding(.bottom, notLast ? 0 : self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 95 : 0) + 32)
                                                .id(currentMessages[message].id)

                                            if messagePosition == .left { Spacer() }
                                        }
                                        .background(Color.clear)
                                    }.onAppear {
                                        //print("the adding mesg id is: \(currentMessages[message].id) but the on i am looking for is: \(currentMessages[(pageShowCount * self.scrollPage) + self.pageShowCount].id) at index: \((pageShowCount * self.scrollPage) - self.pageShowCount)")
                                        if !notLast {
                                            print("called on appear: \(message)")
                                            if self.firstScroll {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
                                                    self.firstScroll = false
                                                }
                                            } else {
                                                withAnimation(Animation.easeOut(duration: 0.6).delay(0.15)) {
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
                                
//                                Rectangle()
//                                    .frame(width: Constants.screenWidth, height: self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 95 : 0) + 32)
//                                    .foregroundColor(.clear)
                            }.background(GeometryReader {
                                Color.clear.preference(key: ViewOffsetKey.self,
                                    value: -$0.frame(in: .named("scroll")).origin.y)
                            })
                            .onPreferenceChange(ViewOffsetKey.self) {
                                if $0 < 0 && !firstScroll && !self.isLoadingMore && self.maxPagination != 0 {
                                    self.isLoadingMore = true
                                    changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 0), skip: currentMessages.count - self.minPagination, completion: { _ in
                                        DispatchQueue.main.async {
                                            self.scrollToId = currentMessages[self.maxPagination].id
                                            self.scrollPage += 1
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                            self.isLoadingMore = false
                                        }

                                        //need to make the very last ending of convo scroll to item due to the page not being divisible.
                                        //also need to add the scroll down functions
                                        print("From Empty view the load limit: \(pageShowCount * (self.scrollPage + 1)) and the skip:\(currentMessages.count - self.minPagination)...... the indexes are \(self.maxPagination).....< \(self.minPagination) anddddd nowww the scroll to index is: \(self.maxPagination + 1)")
                                        
                                        if self.auth.messages.selectedDialog(dialogID: self.dialogID).count != self.totalMessageCount {
                                            print("pulling delta from scrolling...\(self.totalMessageCount) && \(self.auth.messages.selectedDialog(dialogID: self.dialogID).count)")
                                            changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: (pageShowCount * self.scrollPage + 50), skip: currentMessages.count - self.minPagination, completion: { _ in })
                                        }
                                    })
                                }
                            }
                            .onAppear {
                                UIScrollView.appearance().keyboardDismissMode = .onDrag

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
                            }.opacity(self.firstScroll ? 0 : 1)
                        }
                    }
                }
            }.coordinateSpace(name: "scroll")
            .frame(width: Constants.screenWidth)
            .contentShape(Rectangle())
            .onAppear() {
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
                    print("the dialog id is: \(dialogID)")
                    viewModel.loadDialog(auth: auth, dialogId: dialogID, completion: {
                        print("done loading dialogggg: \(dialogID)")
                        Request.countOfMessages(forDialogID: dialogID, extendedRequest: ["sort_desc" : "lastMessageDate"], successBlock: { count in
                            DispatchQueue.main.async {
                                self.totalMessageCount = Int(count)
                                print("the total message count is: \(Int(count))")
                                if self.auth.messages.selectedDialog(dialogID: dialogID).count != Int(count) {
                                    print("local and pulled do not match... pulling delta: \(count) && \(self.auth.messages.selectedDialog(dialogID: self.dialogID).count)")

                                    changeMessageRealmData.shared.getMessageUpdates(dialogID: dialogID, limit: pageShowCount * scrollPage, skip: 0, completion: { _ in
                                    })
                                }
                            }

                            Request.totalUnreadMessageCountForDialogs(withIDs: Set([dialogID]), successBlock: { (unread, _) in
                                DispatchQueue.main.async {
                                    print("the unread count for this dialog: \(unread)")
                                    unreadMessageCount = Int(unread)
                                }
                            })
                        })
                    })
                    delayViewMessages = true

                    //guard !Session.current.tokenHasExpired else { return }
                    
//                    Request.updateDialog(withID: dialogID, update: UpdateChatDialogParameters(), successBlock: { dialog in
//                        auth.selectedConnectyDialog = dialog
//                        dialog.join(completionBlock: { errors in
//                            print("error joininggg: \(errors?.localizedDescription)")
//                        })
//                    }) { error in
//                        print("error getting messagese: \(error.localizedDescription)")
//                    }
                }
            }
        }
    }

    func hasPrevious(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.last ? (result[index + 1].senderID == result[index].senderID && result[index + 1].date <= result[index].date.addingTimeInterval(86400) ? true : false) : false
    }

    func needsTimestamp(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.first ? (result[index].date >= result[index - 1].date.addingTimeInterval(86400) ? true : false) : false
    }
    
    func isPriorWider(index: Int) -> Bool {
        let result = self.auth.messages.selectedDialog(dialogID: self.dialogID)

        return result[index] != result.first ? (result[index].senderID == result[index - 1].senderID && (result[index].date >= result[index - 1].date.addingTimeInterval(86400) ? false : true) && result[index].bubbleWidth > result[index - 1].bubbleWidth ? false : true) : true //- (result[index].dislikedId.count >= 1 && result[index].likedId.count >= 1 ? 48 : 16)
    }
}
