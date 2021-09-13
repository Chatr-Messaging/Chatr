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

struct Stack<Content: View>: View {
    var axis: Axis.Set
    var content: Content
    
    init(_ axis: Axis.Set = .vertical, @ViewBuilder builder: ()->Content) {
        self.axis = axis
        self.content = builder()
    }
    
    var body: some View {
        switch axis {
        case .horizontal:
            HStack {
                content
            }
        case .vertical:
            VStack {
                content
            }
        default:
            VStack {
                content
            }
        }
    }
}

struct ReversedScrollView<Content: View>: View {
    var axis: Axis.Set
    var content: Content
    
    init(_ axis: Axis.Set = .horizontal, @ViewBuilder builder: ()->Content) {
        self.axis = axis
        self.content = builder()
    }
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(axis, showsIndicators: false) {
                Stack(axis) {
                    Spacer()
                    content
                }
                .frame(
                   minWidth: minWidth(in: proxy, for: axis),
                   minHeight: minHeight(in: proxy, for: axis)
                )
            }
        }
    }
    
    func minWidth(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
       axis.contains(.horizontal) ? proxy.size.width : nil
    }
        
    func minHeight(in proxy: GeometryProxy, for axis: Axis.Set) -> CGFloat? {
       axis.contains(.vertical) ? proxy.size.height : nil
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
    @Binding var isKeyboardActionOpen: Bool
    @Binding var isHomeDialogOpen: Bool
    @Binding var isDetailOpen: Bool
    @Binding var emptyQuickSnaps: Bool
    @Binding var detailMessageModel: MessageStruct
    @State private var delayViewMessages: Bool = false
    @State private var firstScroll: Bool = true
    @State private var isLoadingMore: Bool = false
    //@State private var permissionToScroll: Bool = false
    @State private var permissionLoadMore: Bool = true
    @State private var scrollPage: Int = 0
    @State private var scrollToId: String = ""
    @State private var maxMessageCount: Int = -1
    @State private var scrollViewHeight: CGFloat = 0
    @State private var scrollBuffer: CGFloat = 0
    @State private var scrollLocationPercent: Double = 0.0
    @State var playingVideoId = ""
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

        if UserDefaults.standard.bool(forKey: "localOpen") {
            ReversedScrollView(.vertical) {
                LazyVStack(alignment: .center) {
                    Text(self.maxMessageCount == 0 ? "no messages found" : maxMessageCount == -1 ? "loading messages..." : "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 160)
                        .padding(.all, self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 20)
                        .padding(.vertical, self.maxMessageCount >= 1 ? 0 : 80)
                        //.offset(y: self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 40)
                        .opacity(self.maxMessageCount >= 1 && self.delayViewMessages ? 0 : 1)
                    
                    //CUSTOM MESSAGE BUBBLE:
                    if self.delayViewMessages {
                        ScrollViewReader { reader in
                            VStack(alignment: .center) {
                                ForEach(self.maxPagination ..< self.currentMessages.count, id: \.self) { message in
                                    if currentMessages[message].isHeader, self.currentMessages.count >= self.maxMessageCount {
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
                                    
                                    if self.isLoadingMore && !firstScroll && self.maxPagination != 0 && message == self.maxPagination {
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
                                    
                                    if currentMessages[message].needsTimestamp {
                                        Text("\(self.viewModel.dateFormatTime(date: currentMessages[message].date))")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, message == 0 ? 0 : 15)
                                            .padding(.bottom, 15)
                                    }

                                    ContainerBubble(viewModel: self.viewModel, newDialogFromSharedContact: self.$newDialogFromSharedContact, dialogID: self.$dialogID, isHomeDialogOpen: self.$isHomeDialogOpen, isDetailOpen: self.$isDetailOpen, detailMessageModel: self.$detailMessageModel, playingVideoId: self.$playingVideoId, isPriorWider: currentMessages[message].isPriorWider, message: currentMessages[message], messagePosition: currentMessages[message].positionRight ? .right : .left, hasPrior: currentMessages[message].hasPrevious, namespace: self.namespace)
                                        .environmentObject(self.auth)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.horizontal, 25)
                                        .padding(.trailing, !currentMessages[message].positionRight ? 40 : 0)
                                        .padding(.leading, currentMessages[message].positionRight ? 40 : 0)
                                        .padding(.bottom, currentMessages[message].hasPrevious ? -6 : 10)
                                        .padding(.bottom, self.auth.userHasiOS15 ? 0 : currentMessages[message].id != currentMessages.last?.id ? 0 : self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 110 : 0) + (self.isKeyboardActionOpen ? 80 : 0) + 32)
                                        .resignKeyboardOnDragGesture()
                                        .id(currentMessages[message].id)
                                        .background(Color.clear)
                                        .transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity).animation(Animation.easeOut(duration: 0.35)), removal: AnyTransition.move(edge: .bottom).combined(with: AnyTransition.opacity).animation(Animation.easeInOut(duration: 0.35))))
                                        .contentShape(Rectangle())
                                        .onAppear {
        //                                        //print("the adding mesg id is: \(currentMessages[message].id) but the on i am looking for is: \(currentMessages[(pageShowCount * self.scrollPage) + self.pageShowCount].id) at index: \((pageShowCount * self.scrollPage) - self.pageShowCount)")
                                            print("the scroll to id is: \(self.scrollToId)")
                                            if self.firstScroll, currentMessages[message].id == currentMessages.last?.id, UserDefaults.standard.integer(forKey: "messageViewScrollHeight") > Int(Constants.screenHeight * 0.7) {
        //                                            print("called on appear: \(message)")
                                                //if  {
                                                self.firstScroll = false
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    reader.scrollTo(self.currentMessages.last?.id, anchor: .bottom)
                                                    //self.permissionToScroll = true
                                                }
                                                //} //else if self.scrollViewHeight > Constants.screenHeight * 0.8 && self.permissionLoadMore {
        //                                                print("scrolllling is nowwww \(self.scrollViewHeight) ** \(Constants.screenHeight * 0.8)")
        //                                                withAnimation(Animation.easeOut(duration: 0.25)) {
        //                                                    reader.scrollTo(currentMessages[message].id, anchor: .bottom)
        //                                                }
        //                                            }
                                            } else if self.scrollToId == currentMessages[message].id {
                                                //self.permissionToScroll = false
                                                self.scrollToId = ""
                                                reader.scrollTo(currentMessages[message].id, anchor: .top)
//                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
//                                                    print("the new loging scroll to is: \(message)")
//                                                    withAnimation(Animation.easeInOut(duration: 0.25)) {
//                                                        reader.scrollTo(currentMessages[message].id, anchor: .top)
//                                                    }
//                                                }
                                            } else if !self.firstScroll, currentMessages[message].id == currentMessages.last?.id, self.scrollLocationPercent <= 1.3 {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                                    withAnimation(Animation.easeInOut(duration: 0.4)) {
                                                        reader.scrollTo(currentMessages.last?.id, anchor: .bottom)
                                                    }
                                                }
                                            }
                                        }
                                }
                            }.background(GeometryReader { fullView in
                                Color.clear.preference(key: ViewOffsetKey.self, value: -fullView.frame(in: .named("scroll")).origin.y)
                                    .onAppear {
                                        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        //If the 10 to show is not enough then show another page
                                            self.scrollViewHeight = fullView.size.height
                                            UserDefaults.standard.set(fullView.size.height, forKey: "messageViewScrollHeight")
                                            print("the view height on appear: \(self.scrollViewHeight) ** \(Constants.screenHeight)")
                                            if self.scrollViewHeight < Constants.screenHeight * 0.8, self.maxPagination != 0, self.scrollPage <= 1 {
                                                print("added another scroll pageee")
                                                //self.scrollToId = currentMessages.last?.id ?? ""
                                                self.scrollPage += 1
                                            }
                                        //}
                                    }
                                    .onChange(of: fullView.size.height) { value in
                                        print("the view height isss: \(value) && \(Constants.screenHeight * 0.7)")
                                        self.scrollViewHeight = value
                                        UserDefaults.standard.set(value, forKey: "messageViewScrollHeight")
                                        if self.scrollViewHeight < Constants.screenHeight * 0.8, self.maxPagination != 0, self.scrollPage <= 1 {
                                            print("added another scroll page")
                                            //self.scrollToId = currentMessages.last?.id ?? ""
                                            self.scrollPage += 2
                                        }
                                        
                                        if self.maxMessageCount != self.currentMessages.count {
                                            self.maxMessageCount = self.currentMessages.count
                                        }
                                    }
                            })
                            .onChange(of: self.isKeyboardActionOpen) { keyboardOpen in
                                //Keyboard action drawer or the paperclip button
                                if keyboardOpen, self.scrollLocationPercent <= 1.1, UserDefaults.standard.integer(forKey: "messageViewScrollHeight") > Int(Constants.screenHeight * 0.7) {
                                    withAnimation(Animation.easeOut(duration: 0.35)) {
                                        reader.scrollTo(self.currentMessages.last?.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: self.textFieldHeight) { kHeight in
                                //Keyboard text field height
                                if kHeight != 38, self.scrollLocationPercent <= 1.1, UserDefaults.standard.integer(forKey: "messageViewScrollHeight") > Int(Constants.screenHeight * 0.7) {
                                    withAnimation(Animation.easeOut(duration: 0.35)) {
                                        reader.scrollTo(self.currentMessages.last?.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: self.hasAttachment) { hasAttach in
                                //Keyboard pending media
                                if hasAttach, self.scrollLocationPercent <= 1.1, UserDefaults.standard.integer(forKey: "messageViewScrollHeight") > Int(Constants.screenHeight * 0.7) {
                                    withAnimation(Animation.easeOut(duration: 0.35)) {
                                        reader.scrollTo(self.currentMessages.last?.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onPreferenceChange(ViewOffsetKey.self) { scrollOffsetz in
                                guard self.activeView.height == 0 else {
                                    print("dragging down dialog cell...")
                                    return
                                }
                                
                                self.scrollLocationPercent = CGFloat(self.scrollViewHeight) / (scrollOffsetz + (Constants.screenHeight - (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 127 : 91) : 201)))
                                
                                //pause video if scrolling too much & is playing video
                                if self.playingVideoId != "" {
                                    self.scrollBuffer = self.scrollBuffer == 0 ? scrollOffsetz : self.scrollBuffer
                                    print("caught the video playing and scrolling \(self.scrollBuffer)")
                                    
                                    if (scrollOffsetz > self.scrollBuffer + 200) || (scrollOffsetz < self.scrollBuffer - 200) {
                                        print("susses reset the videooo \(self.scrollBuffer)")
                                        self.playingVideoId = ""
                                        self.scrollBuffer = 0
                                    }
                                }

                                print("the offset is: \(self.scrollLocationPercent) && \(self.scrollViewHeight) && nowww: \(scrollOffsetz + (Constants.screenHeight - (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 127 : 91) : 201))) ** \(scrollOffsetz)")
                                
                                print("the blocker iss: \(self.firstScroll) ** \(self.isLoadingMore) ** \(self.permissionLoadMore)")
                                
                                if scrollOffsetz < -60, !self.firstScroll, !self.isLoadingMore, self.permissionLoadMore {
                                    self.isLoadingMore = true
                                    self.permissionLoadMore = false
                                    //$0 > self.scrollViewHeight && self.minPagination != currentMessages.count {
                                    if self.maxPagination >= self.pageShowCount {
                                        //have more local data to load
                                        print("has more needs to just increase the local page \(self.maxMessageCount) && \(self.maxPagination) && \(currentMessages.count)")
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                            self.isLoadingMore = false
                                            self.scrollPage += 1

                                            if self.maxPagination != 0 {
                                                print("scrolling tooo: \(self.maxPagination + pageShowCount - 1) == \(self.currentMessages[self.maxPagination + pageShowCount - 1].id)")
                                                self.scrollToId = self.currentMessages[self.maxPagination + pageShowCount - 1].id
                                                //self.permissionToScroll = true
                                            } else {
                                                let divisor = currentMessages.count / pageShowCount
                                                let remainder = currentMessages.count - divisor * pageShowCount
                                                let scrollToIndex = remainder == 0 ? pageShowCount - 1 : remainder - 1
                                                print("the scroll to max is attt 0: \(divisor) && \(remainder) && \(scrollToIndex)")
                                                self.scrollToId = currentMessages[scrollToIndex].id
                                                //self.permissionToScroll = true
                                            }
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                self.permissionLoadMore = true
                                            }
                                        }
                                    } else {
                                        //loading more from server
                                        print("local has more to fetch \(self.maxMessageCount) && \(self.viewModel.unreadMessageCount) && \(currentMessages.count) limit: \(pageShowCount * (self.scrollPage + 1)) skip: \(currentMessages.count)")

                                        changeMessageRealmData.shared.getMessageUpdates(dialogID: self.dialogID, limit: pageShowCount * (self.scrollPage + 2), skip: currentMessages.count, completion: { _ in
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                                
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
                                                self.scrollPage += 1

                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                                    self.permissionLoadMore = true
                                                }
                                            }
                                        })
                                    }
//                                    else {
//                                        //do nothing.. turn everything back
//                                        print("has it all good \(maxMessageCount) && \(currentMessages.count)")
//
//                                        let divisor = currentMessages.count / pageShowCount
//                                        let remainder = currentMessages.count - divisor * pageShowCount
//                                        let scrollToIndex = remainder == 0 ? pageShowCount - 1 : remainder - 1
//
//                                        print("the scroll to max is at 0: \(divisor) && \(remainder) && \(scrollToIndex)")
//                                        self.scrollToId = currentMessages[scrollToIndex].id
//                                        self.isLoadingMore = false
//                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
//                                            self.permissionLoadMore = true
//                                        }
//                                    }
                                }
                            }
                            .onAppear {
                                if #available(iOS 15.0, *) {
                                    self.auth.userHasiOS15 = true
                                } else {
                                    self.auth.userHasiOS15 = false
                                }
                                
                                //Scroll to bottom notification
                                NotificationCenter.default.addObserver(forName: NSNotification.Name("scrollToLastId"), object: nil, queue: .main) { (_) in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        withAnimation(.easeOut) {
                                            reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                                        }
                                    }
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    keyboard.observe { (event) in
                                        guard !self.viewModel.isDetailOpen else { return }

                                        let keyboardFrameEnd = event.keyboardFrameEnd
                                        
                                        switch event.type {
                                        case .willShow:
                                            self.keyboardChange = keyboardFrameEnd.height - 10

                                            if self.scrollLocationPercent <= 1.1 {
                                                withAnimation(.easeOut) {
                                                    reader.scrollTo(currentMessages.last?.id ?? "", anchor: .bottom)
                                                }
                                            }
                                        case .willHide:
                                            withAnimation(.easeOut) {
                                                self.keyboardChange = 0
                                            }

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
                    .animation(Animation.easeInOut(duration: 0.35))
                    .frame(height: self.keyboardChange + (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) + (self.hasAttachment ? 110 : 0) + (self.isKeyboardActionOpen ? 80 : 0) + 38)
            )
            .coordinateSpace(name: "scroll")
            .frame(width: Constants.screenWidth)
            .contentShape(Rectangle())
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.delayViewMessages = true
                    self.scrollPage += 1
                    self.maxMessageCount = self.currentMessages.count
                    print("the dialog id is: \(dialogID)")
                    
                    viewModel.loadDialog(auth: auth, dialogId: dialogID, completion: {
                        print("done loading dialogggg: \(dialogID) && \(self.viewModel.totalMessageCount) && \(currentMessages.count) &&& \(self.viewModel.unreadMessageCount)")
                        self.maxMessageCount = self.viewModel.totalMessageCount
                        
                        if self.viewModel.totalMessageCount > self.currentMessages.count || self.currentMessages.count == 0 || self.viewModel.totalMessageCount == 100 {
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
