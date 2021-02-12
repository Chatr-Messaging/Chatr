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
    @State var hasPrior: Bool = true
    @State var subText: String = ""
    @State var avatar: String = ""
    
    ///Interaction variables:
    @State var showInteractions: Bool = false
    @State var moveUpAnimation: Bool = false
    @State var interactionSelected: String = ""
    @State var reactions: [String] = []
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false

    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .topTrailing : .topLeading) {
            ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
               //MARK: Main content section:
                if self.message.messageState == .deleted {
                    ZStack {
                        Text("deleted")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .lineLimit(nil)
                    }.padding(.horizontal, 15)
                    .background(Color("deadViewBG"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                } else {
                    ZStack(alignment: self.messagePosition == .left ? .topTrailing : .topLeading) {
                        ZStack {
                            VStack(spacing: 0) {
                                if self.message.image != "" {
                                    //AttachmentBubble(viewModel: self.viewModel, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                                        //.environmentObject(self.auth)
                                } else if self.message.imageType == "video" {
                                    Text("Video here")
                                } else if self.message.contactID != 0 {
                                    //ContactBubble(viewModel: self.viewModel, chatContact: self.$newDialogFromSharedContact, message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                                        //.environmentObject(self.auth)
                                } else if self.message.longitude != 0 && self.message.latitude != 0 {
                                    LocationBubble(message: self.message, messagePosition: messagePosition, hasPrior: self.hasPrior)
                                } else {
                                    TextBubble(message: self.message, messagePosition: messagePosition)
                                }
                            }
                        }.padding(.bottom, self.hasPrior ? 0 : 15)
                        .padding(.top, self.message.likedId.count != 0 || self.message.dislikedId.count != 0 ? 22 : 0)
                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.45)), removal: AnyTransition.identity))
                        .scaleEffect(self.showInteractions ? 1.1 : 1.0)
                        .onTapGesture(count: 2) {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if self.messagePosition == .left && self.message.messageState != .deleted  {
                                self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, messageId: self.message.id, dialogId: self.message.dialogID, completion: { like in
                                    self.hasUserLiked = like
                                })
                            }
                        }.onLongPressGesture(minimumDuration: 1.0) {
                            withAnimation(Animation.linear){ showInteractions = false }
                        }.gesture(DragGesture(minimumDistance: 10).onChanged(onChangedInteraction(value:)).onEnded(onEndedInteraction(value:)))
                        .onChange(of: self.showInteractions) { _ in
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }.onAppear() {
                            self.observeInteractions()
                            if self.messagePosition == .right {
                                self.reactions.append("trash")
                                self.reactions.append("copy")
                                self.reactions.append("edit")
                            } else {
                                self.reactions.append("like")
                                self.reactions.append("dislike")
                                self.reactions.append("reply")
                                self.reactions.append("copy")
                            }
                        }
                        
                        //MARK: Interaction Lables / Buttons
                        HStack(spacing: 5) {
                            if self.message.dislikedId.count > 0 {
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, messageId: self.message.id, dialogId: self.message.dialogID, completion: { dislike in
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

                                        Text(self.message.dislikedId.count > 1 && self.hasUserDisliked ? "\(self.message.dislikedId.count)" : "")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, self.message.dislikedId.count > 1 ? 3 : 0)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                        
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                                .offset(x: self.messagePosition == .left ? 20 : -20, y: 2)
                            }

                            if self.message.likedId.count > 0 {
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, messageId: self.message.id, dialogId: self.message.dialogID, completion: { like in
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

                                        Text(self.message.likedId.count > 1 && self.hasUserLiked ? "\(self.message.likedId.count)" : "")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, self.message.likedId.count > 1 ? 3 : 0)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserLiked, messagePosition: self.$messagePosition))
                                .offset(x: self.messagePosition == .left ? 20 : -20, y: 2)
                            }
                        }
                    }
                }
                
                //MARK: Bottomm User Info / Message Status Section
                if !self.hasPrior {
                    HStack(spacing: 4) {
                        if messagePosition == .right { Spacer() }
                        
                        Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right))
                            .foregroundColor(self.message.messageState == .error ? .red : .gray)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 22)
                            .multilineTextAlignment(messagePosition == .right ? .trailing : .leading)
                            .opacity(self.hasPrior && self.message.messageState != .error ? 0 : 1)

                        if messagePosition == .left { Spacer() }
                    }

                    WebImage(url: URL(string: self.avatar))
                        .resizable()
                        .placeholder{ Image("empty-profile").resizable().frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom).scaledToFill() }
                        .indicator(.activity)
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom)
                        .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
                }
            }
            
            //MARK: Interactions Section
            if self.showInteractions {
                ReactionsView(interactionSelected: $interactionSelected, reactions: $reactions)
                    .offset(y: moveUpAnimation ? -65 : -45)
                    .zIndex(2)
                    .onAppear() {
                        self.moveUpAnimation = true
                    }.onDisappear() {
                        self.moveUpAnimation = false
                    }
            }
        }.onAppear() {
            self.viewModel.getUserAvatar(senderId: self.message.senderID, compleation: { url in
                if url == "self" {
                    self.avatar = self.auth.profile.results.first?.avatar ?? ""
                } else { self.avatar = url }
            })

            self.hasUserLiked = self.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
            self.hasUserDisliked = self.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)
        }
    }
    
    func onChangedInteraction(value: DragGesture.Value) {
        withAnimation(.easeIn) { showInteractions = true }
        withAnimation(Animation.linear(duration: 0.065)) {
            let x = value.location.x
            
            //if self.messagePosition == .left {
            if x > 20 && x < 80 { interactionSelected = reactions[0] }
            if x > 80 && x < 140 { interactionSelected = reactions[1] }
            if x > 140 && x < 180 { interactionSelected = reactions[2] }
            if x > 180 && x < 240 && reactions.count >= 4 { interactionSelected = reactions[3] }
            if x < 20 || x > 240 { interactionSelected = "" }
//            } else {
//                if x > Constants.screenWidth - 160 && x < Constants.screenWidth - 100 { interactionSelected = reactions[3] }
//                if x > Constants.screenWidth - 280 && x < Constants.screenWidth - 220 { interactionSelected = reactions[2] }
//                if x > Constants.screenWidth - 340 && x < Constants.screenWidth - 280 { interactionSelected = reactions[1] }
//                if x > Constants.screenWidth - 390 && x < Constants.screenWidth - 340 { interactionSelected = reactions[0] }
//                if x < 50 || x > Constants.screenWidth - 50 { interactionSelected = "" }
//            }
        }
    }
    
    func onEndedInteraction(value: DragGesture.Value) {
        withAnimation(Animation.linear){ showInteractions = false }
        
        if interactionSelected == "like" {
            self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, messageId: self.message.id, dialogId: self.message.dialogID, completion: { like in
                self.hasUserLiked = like
            })
        } else if interactionSelected == "dislike" {
            self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, messageId: self.message.id, dialogId: self.message.dialogID, completion: { dislike in
                self.hasUserDisliked = dislike
            })
        } else if interactionSelected == "copy" {
            self.copyMessage()
        } else if interactionSelected == "reply" {
            self.viewModel.replyMessage()
        } else if interactionSelected == "edit" {
            self.viewModel.editMessage()
        } else if interactionSelected == "trash" {
            guard let dialog = self.auth.selectedConnectyDialog else { return }

            self.viewModel.trashMessage(connectyDialog: dialog, messageId: self.message.id, completion: {
                auth.notificationtext = "Deleted Message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            })
        }
    }
    
    func copyMessage() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIPasteboard.general.setValue(self.message.text, forPasteboardType: kUTTypePlainText as String)
        
        auth.notificationtext = "Successfully copied message"
        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
    }

    func observeInteractions() {
        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id)
        let profileID = self.auth.profile.results.first?.id ?? 0

        msg.observe(.childAdded, with: { snapLikeAdded in
            let typeLike = snapLikeAdded.key

            for child in snapLikeAdded.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.updateMessageLikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                    print("liked added: contain: \(self.message.likedId.contains(profileID)) && my id: \(profileID)")
                } else if childSnap.key == "dislikes" {
                    changeMessageRealmData.updateMessageDislikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
        
        msg.observe(.childRemoved, with: { snapLikeRemoved in
            let typeLike = snapLikeRemoved.key
            
            for child in snapLikeRemoved.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.updateMessageLikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                } else if childSnap.key == "dislikes" {
                    changeMessageRealmData.updateMessageDislikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
    }
}
