//
//  ContainerBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/11/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import RealmSwift
import Firebase
import ConnectyCube
import MobileCoreServices
import Photos
import Cache

struct ContainerBubble: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var viewModel: ChatMessageViewModel
    @Binding var newDialogFromSharedContact: Int
    var isPriorWider: Bool
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = true
    @State var subText: String = ""
    @State var avatar: String = ""
    @State var fullName: String = ""
    @State var replyCount: Int = 0

    ///Interaction variables:
    @State var showInteractions: Bool = false
    @State var likeBtnAnimation: Bool = false
    @State var dislikeBtnAnimation: Bool = false
    @State var interactionSelected: String = ""
    @State var reactions: [String] = []
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State private var deleteActionSheet: Bool = false
    @State var player: AVPlayer = AVPlayer()
    @State var totalDuration: Double = 0
    var namespace: Namespace.ID

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        let dragInteractionGesture = DragGesture()
            .onChanged { value in
                onChangedInteraction(value: value)
            }.onEnded { valueEnd in
                onEndedInteraction(value: valueEnd)
            }

        // a long press gesture that enables isDragging
        let pressInteractionGesture = LongPressGesture()
            .onEnded { _ in
                if self.message.messageState != .isTyping && self.message.messageState != .error {
                    withAnimation {
                        self.showInteractions = true
                    }
                }
            }

        // a combined gesture that forces the user to long press then drag
        let combined = pressInteractionGesture.sequenced(before: dragInteractionGesture)

        ZStack(alignment: self.messagePosition == .right ? .topTrailing : .topLeading) {
            ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
               //MARK: Main content section:
                ZStack(alignment: self.messagePosition == .left ? .topTrailing : .topLeading) {
                    ZStack(alignment: self.messagePosition == .left ? .trailing : .leading) {
                        
                        if self.message.image != "" || self.message.uploadMediaId != "" {
                            AttachmentBubble(viewModel: self.viewModel, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior, player: self.$player, totalDuration: self.$totalDuration, namespace: self.namespace)
                                .environmentObject(self.auth)
                        } else if self.message.contactID != 0 {
                            ContactBubble(viewModel: self.viewModel, chatContact: self.$newDialogFromSharedContact, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior, namespace: self.namespace)
                                .environmentObject(self.auth)
                        } else if self.message.channelID != "" && self.message.messageState != .deleted {
                            ChannelBubble(viewModel: self.viewModel, dialogId: self.message.channelID, hasPrior: self.hasPrior)
                                .environmentObject(self.auth)
                        } else if self.message.longitude != 0 && self.message.latitude != 0 {
                            LocationBubble(viewModel: self.viewModel, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior, namespace: self.namespace)
                        } else {
                            TextBubble(message: self.message, messagePosition: messagePosition, namespace: self.namespace)
                                .transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(Animation.spring().delay(0.4)), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(Animation.easeOut(duration: 0.25).delay(0.4))))
                        }

                        if self.message.messageState == .error {
                            Image(systemName: "exclamationmark.icloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22, alignment: .center)
                                .foregroundColor(.red)
                                .offset(x: messagePosition == .right ? -30 : 30)
                        }
                        
                        if self.replyCount > 0 {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.openReplyDetailView()
                            }, label: {
                                HStack(spacing: self.replyCount > 1 ? 5 : 0) {
                                    Image(systemName: "arrowshape.turn.up.left.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.white)
                                        .frame(width: 14, height: 14, alignment: .center)

                                    Text(self.replyCount > 1 ? "\(self.replyCount)" : "")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }.padding(.horizontal, 7.5)
                                .padding(.vertical, 5)
                            })
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.black).shadow(color: Color.black.opacity(0.75), radius: 5, x: 0, y: 2.5).opacity(0.5))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 1).opacity(0.6))
                            .offset(x: messagePosition == .right ? (self.replyCount > 1 ? -55 : -40) : (self.replyCount > 1 ? 55 : 40))
                        }
                    }.padding(.bottom, self.hasPrior ? 0 : 10)
                    .padding(.top, (self.message.likedId.count != 0 || self.message.dislikedId.count != 0) && (self.isPriorWider) ? 22 : 0)
                    .scaleEffect(self.showInteractions ? 1.1 : 1.0)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: SizePreferenceKey.self, value: proxy.size)
                        })
                    .onPreferenceChange(SizePreferenceKey.self) { preferences in
                        if self.message.bubbleWidth != Int(preferences.width) {
                            changeMessageRealmData.shared.updateBubbleWidth(messageId: self.message.id, width: Int(preferences.width))
                        }
                    }
                    .onTapGesture(count: 2) {
                        if self.messagePosition == .left && self.message.messageState != .isTyping && self.message.messageState != .error {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if self.messagePosition == .left && self.message.messageState != .deleted  {
                                self.viewModel.message = self.message
                                self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                    self.hasUserLiked = like
                                })
                            }
                        }
                    }
                    .onTapGesture(count: 1) {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.openReplyDetailView()
                    }
                    .gesture(combined)
                    .onChange(of: self.showInteractions) { _ in
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }.onAppear() {
                        self.observeInteractions()
                        if self.messagePosition == .right {
                            if self.message.imageType == "image/gif" || self.message.imageType == "image/png" || self.message.imageType == "video/mov" {
                                self.reactions.append("save")
                            } else {
                                self.reactions.append("reply")
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                                guard let dialog = self.auth.selectedConnectyDialog, let admins = dialog.adminsIDs, (admins.contains(NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID"))) || dialog.userID == UserDefaults.standard.integer(forKey: "currentUserID")), (dialog.type == .group || dialog.type == .public) else {
                                    self.reactions.append("copy")
                                    self.reactions.append("trash")

                                    return
                                }

                                if !self.message.isPinned {
                                    self.reactions.append("pin")
                                    self.reactions.append("trash")
                                } else {
                                    self.reactions.append("unpin")
                                    self.reactions.append("trash")
                                }
                            }
                        } else {
                            self.reactions.append("like")
                            self.reactions.append("dislike")
                            self.reactions.append("reply")
                            if self.message.imageType == "image/gif" || self.message.imageType == "image/png" || self.message.imageType == "video/mov" {
                                self.reactions.append("save")
                            } else {
                                self.reactions.append("copy")
                            }
                        }
                    }.zIndex(self.showInteractions ? 1 : 0)
                    
                    //MARK: Interaction Labels / Buttons
                    HStack(spacing: 5) {
                        if self.message.dislikedId.count > 0 && !self.viewModel.isDetailOpen {
                            Button(action: {
                                if self.messagePosition == .left {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.viewModel.message = self.message
                                    self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                                        self.hasUserDisliked = dislike
                                    })
                                }
                            }, label: {
                                HStack(spacing: self.message.dislikedId.count > 1 ? 2 : 0) {
                                    Image("dislike")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22, alignment: .center)
                                        .offset(x: self.message.dislikedId.count == 0 ? 4 : 0)
                                        .rotationEffect(Angle(degrees: self.dislikeBtnAnimation ? 0 : 45))

                                    Text(self.message.dislikedId.count > 1 ? "\(self.message.dislikedId.count)" : "")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(self.message.dislikedId.contains(UserDefaults.standard.integer(forKey: "currentUserID")) ? .white : .primary)
                                        .padding(.horizontal, self.message.dislikedId.count > 1 ? 3 : 0)
                                }.padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                            .offset(x: self.messagePosition == .left ? 20 : -20, y: 2)
                            .scaleEffect(self.dislikeBtnAnimation ? 1.0 : 0.15)
                            .animation(.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 0))
                            .onAppear() {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) { self.dislikeBtnAnimation = true }
                            }.onDisappear() {
                                withAnimation(.easeIn(duration: 0.5)) { self.dislikeBtnAnimation = false }
                            }
                        }

                        if self.message.likedId.count > 0 && !self.viewModel.isDetailOpen {
                            Button(action: {
                                if self.messagePosition == .left {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.viewModel.message = self.message
                                    self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                        self.hasUserLiked = like
                                    })
                                }
                            }, label: {
                                HStack(spacing: self.message.likedId.count > 1 ? 2 : 0) {
                                    Image("like")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22, alignment: .center)
                                        .offset(x: self.message.likedId.count == 0 ? 4 : 0)
                                        .rotationEffect(Angle(degrees: self.likeBtnAnimation ? 0 : 45))

                                    Text(self.message.likedId.count > 1 ? "\(self.message.likedId.count)" : "")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(self.message.likedId.contains(UserDefaults.standard.integer(forKey: "currentUserID")) ? .white : .primary)
                                        .padding(.horizontal, self.message.likedId.count > 1 ? 3 : 0)
                                }.padding(.horizontal, 10)
                                .padding(.vertical, 5)
                            }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserLiked, messagePosition: self.$messagePosition))
                            .offset(x: self.messagePosition == .left ? 20 : -20, y: 2)
                            .scaleEffect(self.likeBtnAnimation ? 1.0 : 0.15)
                            .onAppear() {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) { self.likeBtnAnimation = true }
                            }.onDisappear() {
                                withAnimation(.easeIn(duration: 0.5)) { self.likeBtnAnimation = false }
                            }
                        }
                    }.zIndex(self.showInteractions ? 2 : 0)
                    .offset(y: self.isPriorWider ? 0 : -22)
                }
                
                //MARK: Bottom User Info / Message Status Section
                HStack(spacing: 4) {
                    if messagePosition == .right {
                        Spacer()
                        
                        if self.message.isPinned {
                            Image(systemName: "pin.fill")
                                .resizable()
                                .scaledToFit()
                                .rotationEffect(.degrees(45))
                                .frame(width: 14, height: 12, alignment: .center)
                                .offset(y: 5)
                                .foregroundColor(.gray)
                                .opacity(self.hasPrior ? 0 : 1)
                        }
                    }

                    Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right, isGroup: self.auth.selectedConnectyDialog?.type == .group || self.auth.selectedConnectyDialog?.type == .public, fullName: self.fullName))
                        .foregroundColor(self.message.messageState == .error ? .red : .gray)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.leading, messagePosition == .right ? 0 : 20)
                        .padding(.trailing, messagePosition == .right ? 20 : 2)
                        .offset(y: 4)
                        .multilineTextAlignment(messagePosition == .right ? .trailing : .leading)
                        .opacity(self.hasPrior ? 0 : 1)

                    if messagePosition == .left {
                        if self.message.isPinned {
                            Image(systemName: "pin.fill")
                                .resizable()
                                .scaledToFit()
                                .rotationEffect(.degrees(-45))
                                .frame(width: 14, height: 12, alignment: .center)
                                .offset(y: 5)
                                .foregroundColor(.gray)
                                .opacity(self.hasPrior ? 0 : 1)
                        }

                        Spacer()
                    }
                }

                if !self.hasPrior, self.message.messageState != .error {
                    if self.avatar != "" {
                        WebImage(url: URL(string: self.avatar))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom).scaledToFill() }
                            .indicator(.activity)
                            .scaledToFill()
                            .frame(width: Constants.smallAvitarSize, height: Constants.smallAvitarSize, alignment: .bottom)
                            .clipShape(Circle())
                            .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2))
                            .offset(y: 2)
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    } else {
                        ZStack {
                            Circle()
                                .frame(width: Constants.smallAvitarSize, height: Constants.smallAvitarSize, alignment: .center)
                                .foregroundColor(Color("bgColor"))
                                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 2)

                            Text("".firstLeters(text: self.fullName))
                                .font(.system(size: 13))
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2))
                        .offset(y: 2)
                    }
                }
            }.actionSheet(isPresented: self.$deleteActionSheet) {
                ActionSheet(title: Text("Are you sure?"), message: Text("This message will be gone forever"), buttons: [
                    .destructive(Text("Delete Message"), action: {
                        guard let dialog = self.auth.selectedConnectyDialog else { return }

                        self.viewModel.trashMessage(connectyDialog: dialog, messageId: self.message.id, completion: {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.deleteActionSheet.toggle()

                            auth.notificationtext = "Deleted Message"
                            NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                        })
                    }), .cancel()
                ])
            }
            
            //MARK: Interactions Section
            if self.showInteractions {
                ReactionsView(interactionSelected: $interactionSelected, reactions: $reactions, message: self.$message, namespace: self.namespace)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .move(edge: .bottom)).animation(.spring()), removal: AnyTransition.opacity.combined(with: .move(edge: .bottom))))
                    .animation(.spring())
                    .offset(y: -65)
                    .zIndex(2)
            }
        }.onAppear() {
            self.viewModel.getUserAvatar(senderId: self.message.senderID, compleation: { (url, fullName, _) in
                if url == "self" || fullName == "self" {
                    self.avatar = self.auth.profile.results.first?.avatar ?? ""
                    self.fullName = self.auth.profile.results.first?.fullName ?? ""
                } else {
                    self.avatar = url
                    self.fullName = fullName
                }
            })

            self.hasUserLiked = self.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
            self.hasUserDisliked = self.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)

            self.viewModel.fetchReplyCount(message: self.message, completion: { count in
                print("the total reply count is: \(count)")
                self.replyCount = count
            })
        }
    }

    func onChangedInteraction(value: DragGesture.Value) {
        if self.message.messageState != .isTyping && self.message.messageState != .error {
            self.showInteractions = true
            if self.messagePosition == .right && self.reactions.contains(where: { $0 == "pin" || $0 == "unpin" }) {
                self.reactions[1] = self.message.isPinned ? "unpin" : "pin"
            }

            withAnimation(Animation.linear(duration: 0.065)) {
                let y = value.translation.width
                let c = value.startLocation.x

                print("the y value is: \(y) start location: \(c) &&7 noww")
                if message.messageState != .error {
                    if messagePosition == .right && (Int(Constants.screenWidth) / 2 - 50 > self.message.bubbleWidth || c > Constants.screenWidth / 2 - 75) {
                        self.dragLeftInteraction(y: y)
                    } else {
                        if c <= Constants.screenWidth / 2 - 50 {
                            //drag right
                            //left & right bubble
                            if y > 5 && y < 35 { interactionSelected = reactions[0] }
                            if y > 35 && y < 65 { interactionSelected = reactions[1] }
                            if y > 65 && y < 95 { interactionSelected = reactions[2] }
                            if y > 95 && y < 125 && reactions.count >= 4 { interactionSelected = reactions[3] }
                            if y < 5 || y > (reactions.count >= 4 ? 125 : 95) { interactionSelected = "" }
                        } else {
                            self.dragLeftInteraction(y: y)
                        }
                    }
                } else {
                    if y > -100 && y < -5 { interactionSelected = "try again" }
                    if y < -100 || y > -5 { interactionSelected = "" }
                }
            }
        }
    }
    
    func onEndedInteraction(value: DragGesture.Value) {
        if self.message.messageState != .isTyping && self.message.messageState != .error {
            withAnimation(Animation.linear) { self.showInteractions = false }
            
            if interactionSelected == "like" {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.viewModel.message = self.message
                self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                    withAnimation(Animation.easeOut(duration: 0.5).delay(0.8)) {
                        self.hasUserLiked = like
                    }
                })
            } else if interactionSelected == "dislike" {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.viewModel.message = self.message
                self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                    withAnimation(Animation.easeOut(duration: 0.5).delay(0.8)) {
                        self.hasUserDisliked = dislike
                    }
                })
            } else if interactionSelected == "copy" {
                self.copyMessage()
            } else if interactionSelected == "reply" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.openReplyDetailView()
            } else if interactionSelected == "edit" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.viewModel.editMessage()
            } else if interactionSelected == "trash" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.deleteActionSheet.toggle()
            } else if interactionSelected == "try again" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.tryAgain()
            } else if interactionSelected == "pin" || interactionSelected == "unpin" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.pinMessage()
            } else if interactionSelected == "save" {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.saveImage()
            }
            
            self.interactionSelected = ""
        }
    }
    
    func dragLeftInteraction(y: CGFloat) {
        //drag left
        if messagePosition == .left {
            //left bubble
            if y > -125 && y < -95 { interactionSelected = reactions[0] }
            if y > -95 && y < -65 { interactionSelected = reactions[1] }
            if y > -65 && y < -35 { interactionSelected = reactions[2] }
            if y > -35 && y < -5 { interactionSelected = reactions[3] }
            if y < -125 || y > -5 { interactionSelected = "" }
        } else {
            //right bubble
            if y > -95 && y < -65 { interactionSelected = reactions[0] }
            if y > -65 && y < -35 { interactionSelected = reactions[1] }
            if y > -35 && y < -5 { interactionSelected = reactions[2] }
            if y < -95 || y > -5 { interactionSelected = "" }
        }
    }
    
    func copyMessage() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if self.message.longitude != 0 && self.message.latitude != 0 {
            let copyText = "longitude: " + "\(self.message.longitude)" + "\n" + "latitude: " + "\(self.message.latitude)"

            UIPasteboard.general.setValue(copyText, forPasteboardType: kUTTypePlainText as String)
        } else {
            UIPasteboard.general.setValue(self.message.text, forPasteboardType: kUTTypePlainText as String)
        }

        auth.notificationtext = "Successfully copied message"
        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
    }

    func tryAgain() {
        print("try again action")
    }
    
    func openReplyDetailView() {
        guard self.message.messageState != .isTyping && self.message.messageState != .error else { return }
   
        print("trying to open details")
        if self.message.imageType == "video/mov" {
            self.player.pause()
            self.viewModel.player = self.player
        }

        self.viewModel.message = self.message
        self.viewModel.isDetailOpen = true
    }

    func pinMessage() {
        print("the pinning message id is: \(self.message.id.description)")
        self.viewModel.pinMessage(message: self.message, completion: { added in
            if !added {
                changeDialogRealmData.shared.removeDialogPin(messageId: self.message.id, dialogID: self.message.dialogID)
                self.reactions[1] = "pin"
                auth.notificationtext = "Removed pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            } else {
                changeDialogRealmData.shared.addDialogPin(messageId: self.message.id, dialogID: self.message.dialogID)
                self.reactions[1] = "unpin"
                auth.notificationtext = "Successfully pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            }
        })
    }
    
    func saveImage() {
        if self.message.imageType == "video/mov" {
            do {
                let result = try storage?.entry(forKey: self.message.image)
                //let videoUrl = URL(string: result?.filePath ?? "")

                if let videoData = result?.object {
                    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]

                    let dataPath = paths.appending("/saveCameraRoll/saveChatrVideoToCameraRoll.mp4")

                    try videoData.write(to: URL(fileURLWithPath: dataPath))

                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: dataPath))
                    }) { (success, error) in
                        if error != nil {
                            DispatchQueue.main.async {
                                auth.notificationtext = "Error saving video"
                                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        } else {
                            DispatchQueue.main.async {
                                auth.notificationtext = "Successfully saved video"
                                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                }
            } catch { }
        } else {
            if let imageData = SDImageCache.shared.imageFromMemoryCache(forKey: self.message.image)?.pngData() {
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: imageData, options: nil)
                }) { (success, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            auth.notificationtext = "Error saving image"
                            NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    } else {
                        DispatchQueue.main.async {
                            auth.notificationtext = "Successfully saved image"
                            NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        }
    }
    
    func observeInteractions() {
        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id)
        let profileID = self.auth.profile.results.first?.id ?? 0

        msg.observe(.childAdded, with: { snapAdded in
            let typeLike = snapAdded.key

            for child in snapAdded.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.shared.updateMessageLikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                    print("liked added: contain: \(self.message.likedId.contains(profileID)) && my id: \(profileID)")
                } else if typeLike == "dislikes" {
                    changeMessageRealmData.shared.updateMessageDislikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
        
        msg.observe(.childRemoved, with: { snapRemoved in
            let typeLike = snapRemoved.key
            
            for child in snapRemoved.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.shared.updateMessageLikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                } else if typeLike == "dislikes" {
                    changeMessageRealmData.shared.updateMessageDislikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
    }
}
