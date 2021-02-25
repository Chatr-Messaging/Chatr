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

struct ContainerBubble: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var viewModel: ChatMessageViewModel
    @Binding var newDialogFromSharedContact: Int
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = true
    @State var subText: String = ""
    @State var avatar: String = ""
    @State var fullName: String = ""

    ///Interaction variables:
    @State var showInteractions: Bool = false
    @State var likeBtnAnimation: Bool = false
    @State var dislikeBtnAnimation: Bool = false
    @State var interactionSelected: String = ""
    @State var reactions: [String] = []
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State private var deleteActionSheet: Bool = false

    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .topTrailing : .topLeading) {
            ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
               //MARK: Main content section:
                ZStack(alignment: self.messagePosition == .left ? .topTrailing : .topLeading) {
                    ZStack(alignment: self.messagePosition == .left ? .bottomTrailing : .bottomLeading) {
                        if self.message.image != "" {
                            AttachmentBubble(viewModel: self.viewModel, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                                .environmentObject(self.auth)
                        } else if self.message.contactID != 0 {
                            ContactBubble(viewModel: self.viewModel, chatContact: self.$newDialogFromSharedContact, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                                .environmentObject(self.auth)
                        } else if self.message.longitude != 0 && self.message.latitude != 0 {
                            LocationBubble(message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                        } else {
                            TextBubble(message: self.message, messagePosition: messagePosition)
                                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.spring()), removal: AnyTransition.identity))
                        }
                        
                        if self.message.messageState == .error {
                            Image(systemName: "exclamationmark.icloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22, alignment: .center)
                                .foregroundColor(.red)
                                .offset(x: messagePosition == .right ? -30 : 30)
                                .padding(.bottom, 10)
                        }
                    }.padding(.bottom, self.hasPrior ? 0 : 10)
                    .padding(.top, self.message.likedId.count != 0 || self.message.dislikedId.count != 0 ? 22 : 0)
                    .scaleEffect(self.showInteractions ? 1.1 : 1.0)
                    .onTapGesture(count: 2) {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if self.messagePosition == .left && self.message.messageState != .deleted  {
                            self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                self.hasUserLiked = like
                            })
                        }
                    }.gesture(DragGesture(minimumDistance: 0).onChanged(onChangedInteraction(value:)).onEnded(onEndedInteraction(value:)))
                    .onChange(of: self.showInteractions) { _ in
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    }.onAppear() {
                        self.observeInteractions()
                        if self.messagePosition == .right {
                            self.reactions.append("edit")
                            self.reactions.append("copy")
                            self.reactions.append("trash")
                        } else {
                            self.reactions.append("like")
                            self.reactions.append("dislike")
                            self.reactions.append("reply")
                            self.reactions.append("copy")
                        }
                    }.zIndex(self.showInteractions ? 1 : 0)
                    
                    //MARK: Interaction Lables / Buttons
                    HStack(spacing: 5) {
                        if self.message.dislikedId.count > 0 {
                            Button(action: {
                                if self.messagePosition == .left {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                                        self.hasUserDisliked = dislike
                                    })
                                }
                            }, label: {
                                HStack(spacing: self.message.dislikedId.count > 1 && self.hasUserDisliked ? 2 : 0) {
                                    Image("dislike")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22, alignment: .center)
                                        .offset(x: self.message.dislikedId.count == 0 ? 4 : 0)
                                        .rotationEffect(Angle(degrees: self.dislikeBtnAnimation ? 0 : 45))

                                    Text(self.message.dislikedId.count > 1 && self.hasUserDisliked ? "\(self.message.dislikedId.count)" : "")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
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

                        if self.message.likedId.count > 0 {
                            Button(action: {
                                if self.messagePosition == .left {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                        self.hasUserLiked = like
                                    })
                                }
                            }, label: {
                                HStack(spacing: self.message.dislikedId.count > 1 && self.hasUserDisliked ? 2 : 0) {
                                    Image("like")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22, alignment: .center)
                                        .offset(x: self.message.likedId.count == 0 ? 4 : 0)
                                        .rotationEffect(Angle(degrees: self.likeBtnAnimation ? 0 : 45))

                                    Text(self.message.likedId.count > 1 && self.hasUserLiked ? "\(self.message.likedId.count)" : "")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
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
                }
                
                //MARK: Bottomm User Info / Message Status Section
                HStack(spacing: 4) {
                    //if messagePosition == .right { Spacer() }

                    Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right, isGroup: self.auth.selectedConnectyDialog?.type == .group || self.auth.selectedConnectyDialog?.type == .public, fullName: self.fullName))
                        .foregroundColor(self.message.messageState == .error ? .red : .gray)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 18)
                        .offset(y: 4)
                        .multilineTextAlignment(messagePosition == .right ? .trailing : .leading)
                        .opacity(self.hasPrior ? 0 : 1)

                    //if messagePosition == .left { Spacer() }
                }

                WebImage(url: URL(string: self.avatar))
                    .resizable()
                    .placeholder{ Image("empty-profile").resizable().frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom).scaledToFill() }
                    .indicator(.activity)
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom)
                    .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2))
                    .offset(y: 2)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
                    .opacity(self.hasPrior && self.message.messageState != .error ? 0 : 1)
            }.actionSheet(isPresented: self.$deleteActionSheet) {
                ActionSheet(title: Text("Are you sure?"), message: Text("The message will be gone forever."), buttons: [
                    .default(Text("Select More")) {
                        print("select more btn...")
                    }, .destructive(Text("Delete Message"), action: {
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
                ReactionsView(interactionSelected: $interactionSelected, reactions: $reactions, message: self.$message)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.combined(with: .move(edge: .bottom)).animation(.spring()), removal: AnyTransition.opacity.combined(with: .move(edge: .bottom))))
                    .animation(.spring())
                    .offset(y: -65)
                    .zIndex(2)
                    .padding(.horizontal)
            }
        }.onAppear() {
            self.viewModel.getUserAvatar(senderId: self.message.senderID, compleation: { (url, fullName) in
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
        }
    }
    
    func onChangedInteraction(value: DragGesture.Value) {
        self.showInteractions = true
        withAnimation(Animation.linear(duration: 0.065)) {
            let y = value.translation.width
            let c = value.startLocation.x

            print("the y value is: \(y) start location: \(c)")
            if message.messageState != .error {
                if c <= Constants.screenWidth / 2 - 50 {
                    if y > 5 && y < 35 { interactionSelected = reactions[0] }
                    if y > 35 && y < 65 { interactionSelected = reactions[1] }
                    if y > 65 && y < 95 { interactionSelected = reactions[2] }
                    if y > 95 && y < 125 && reactions.count >= 4 { interactionSelected = reactions[3] }
                    if y < 5 || y > (reactions.count >= 4 ? 125 : 95) { interactionSelected = "" }
                } else {
                    if messagePosition == .left {
                        if y > -125 && y < -95 { interactionSelected = reactions[0] }
                        if y > -95 && y < -65 { interactionSelected = reactions[1] }
                        if y > -65 && y < -35 { interactionSelected = reactions[2] }
                        if y > -35 && y < -5 { interactionSelected = reactions[3] }
                        if y < -125 || y > -5 { interactionSelected = "" }
                    } else {
                        if y > -95 && y < -65 { interactionSelected = reactions[0] }
                        if y > -65 && y < -35 { interactionSelected = reactions[1] }
                        if y > -35 && y < -5 { interactionSelected = reactions[2] }
                        if y < -95 || y > -5 { interactionSelected = "" }
                    }
                }
            } else {
                if y > -100 && y < -5 { interactionSelected = "try again" }
                if y < -100 || y > -5 { interactionSelected = "" }
            }
        }
    }
    
    func onEndedInteraction(value: DragGesture.Value) {
        withAnimation(Animation.linear) { showInteractions = false }
        
        if interactionSelected == "like" {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                withAnimation(Animation.easeOut(duration: 0.5).delay(0.8)) {
                    self.hasUserLiked = like
                }
            })
        } else if interactionSelected == "dislike" {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                withAnimation(Animation.easeOut(duration: 0.5).delay(0.8)) {
                    self.hasUserDisliked = dislike
                } 
            })
        } else if interactionSelected == "copy" {
            self.copyMessage()
        } else if interactionSelected == "reply" {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.viewModel.replyMessage()
        } else if interactionSelected == "edit" {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.viewModel.editMessage()
        } else if interactionSelected == "trash" {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.deleteActionSheet.toggle()
        } else if interactionSelected == "try again" {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            self.tryAgain()
        }
    }
    
    func copyMessage() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIPasteboard.general.setValue(self.message.text, forPasteboardType: kUTTypePlainText as String)
        
        auth.notificationtext = "Successfully copied message"
        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
    }

    func tryAgain() {
        print("try again action")
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
