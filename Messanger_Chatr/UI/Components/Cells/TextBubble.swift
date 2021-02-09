//
//  TextBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import SDWebImageSwiftUI
import ConnectyCube
import Firebase
import RealmSwift
import WKView

struct TextBubble: View {
    @EnvironmentObject var auth: AuthModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    @State var avatar: String = ""
    @State private var typingOpacity: CGFloat = 1.0
    @State var showInteractions: Bool = false
    @State var moveUpAnimation: Bool = false
    @State var interactionSelected: String = ""
    @State var reactions: [String] = []
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    var hasPrior: Bool = true
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .topTrailing : .topLeading) {
            ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
                    ZStack {
                        if self.message.messageState != .isTyping || self.message.messageState == .deleted {
                            if self.message.text.containsEmoji && self.message.text.count <= 4 {
                                Text(self.message.text)
                                    .font(.system(size: 66))
                                    .offset(x: self.messagePosition == .right ? -10 : 10, y: -5)
                                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                            } else {
                                ZStack(alignment: self.messagePosition == .left ? .topTrailing : .topLeading) {
                                    LinkedText(self.message.text, messageRight: self.messagePosition == .right)
                                        .scaleEffect(self.showInteractions ? 1.1 : 1.0)
                                        .onTapGesture(count: 2) {
                                            if self.messagePosition == .left {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                likeMessage()
                                            }
                                        }.gesture(DragGesture(minimumDistance: 0).onChanged(onChanged(value:)).onEnded(onEnded(value:)))
                                        .onChange(of: self.showInteractions) { _ in
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        }.onAppear() {
                                            self.loadFirebase()
                                            if self.messagePosition == .right {
                                                self.reactions.append("trash")
                                                self.reactions.append("edit")
                                                self.reactions.append("copy")
                                                self.reactions.append("reply")
                                            } else {
                                                self.reactions.append("like")
                                                self.reactions.append("dislike")
                                                self.reactions.append("reply")
                                                self.reactions.append("copy")
                                            }
                                        }

                                    HStack(spacing: 5) {
                                        if self.message.dislikedId.count > 0 {
                                            Button(action: {
                                                if self.messagePosition == .left {
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                    self.dislikeMessage()
                                                }
                                            }, label: {
                                                HStack(spacing: 2) {
                                                    Image("dislike")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 22, height: 22, alignment: .center)
                                                        .offset(x: self.message.dislikedId.count == 0 ? 4 : 0)

                                                    Text(self.message.dislikedId.count > 1 ? "\(self.message.dislikedId.count)" : "")
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                        .padding(.horizontal, self.message.dislikedId.count > 1 ? 3 : 0)
                                                }.padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                    
                                            }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                                            .offset(x: self.messagePosition == .left ? 20 : -20, y: -20)
                                        }

                                        if self.message.likedId.count > 0 {
                                            Button(action: {
                                                if self.messagePosition == .left {
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                    self.likeMessage()
                                                }
                                            }, label: {
                                                HStack(spacing: 2) {
                                                    Image("like")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 22, height: 22, alignment: .center)
                                                        .offset(x: self.message.likedId.count == 0 ? 4 : 0)

                                                    Text(self.message.likedId.count > 1 ? "\(self.message.likedId.count)" : "")
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.primary)
                                                        .padding(.horizontal, self.message.likedId.count > 1 ? 3 : 0)
                                                }.padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                            }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserLiked, messagePosition: self.$messagePosition))
                                            .offset(x: self.messagePosition == .left ? 20 : -20, y: -20)
                                        }
                                    }
                                }
                            }
                        } else if self.message.messageState == .isTyping {
                            ZStack {
                                Capsule()
                                    .frame(width: 65, height: 45, alignment: .center)
                                    .foregroundColor(Color("buttonColor"))
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)

                                HStack(spacing: 6) {
                                    ForEach(0..<3) { type in
                                        Circle()
                                            .frame(width: 10, height: 10, alignment: .center)
                                            .foregroundColor(.secondary)
                                            .opacity(Double(self.typingOpacity))
                                            .animation(Animation.easeInOut(duration: 0.66).repeatForever(autoreverses: true).delay(Double(type + 1) * 0.22))
                                            .onAppear() {
                                                withAnimation(Animation.easeInOut(duration: 0.66).repeatForever(autoreverses: true)) {
                                                    self.typingOpacity = 0.20
                                                }
                                            }
                                    }
                                }.padding(.horizontal, 15)
                                .padding(.vertical, 7.5)
                            }
                        }
                    }.padding(.bottom, self.hasPrior ? 0 : 15)
                    .padding(.top, self.message.likedId.count != 0 || self.message.dislikedId.count != 0 ? 20 : 0)
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.45)), removal: AnyTransition.identity))
                
                HStack {
                    if messagePosition == .right { Spacer() }
                    
                    Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right))
                        .foregroundColor(self.hasPrior && self.message.messageState == .error ? .red : .gray)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal)
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
                    .opacity(self.hasPrior ? 0 : 1)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
            }

            if self.showInteractions {
                ReactionsView(interactionSelected: $interactionSelected, reactions: $reactions)
                    .offset(y: moveUpAnimation ? -60 : -45)
                    .zIndex(2)
                    .onAppear() {
                        self.moveUpAnimation = true
                    }.onDisappear() {
                        self.moveUpAnimation = false
                    }
            }
        }.onAppear() {
            if self.message.senderID == UserDefaults.standard.integer(forKey: "currentUserID") {
                self.avatar = self.auth.profile.results.first?.avatar ?? ""
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                        self.avatar = foundContact.avatar
                    } else {
                        Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            if let firstUser = users.first {
                                self.avatar = PersistenceManager().getCubeProfileImage(usersID: firstUser) ?? ""
                            }
                        })
                    }
                } catch {
                    
                }
            }
            
            self.hasUserLiked = self.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
            self.hasUserDisliked = self.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)
        }
    }
        
    func onChanged(value: DragGesture.Value){
        withAnimation(.easeIn) { showInteractions = true }
        
        // Simple Logic....
        withAnimation(Animation.linear(duration: 0.065)) {
            let x = value.location.x

            if self.messagePosition == .left {
                if x > 20 && x < 80 { interactionSelected = reactions[0] }
                if x > 80 && x < 140 { interactionSelected = reactions[1] }
                if x > 140 && x < 180 { interactionSelected = reactions[2] }
                if x > 180 && x < 240 { interactionSelected = reactions[3] }
                if x < 20 || x > 240 { interactionSelected = "" }
            } else {
                if x > 230 && x < 290 { interactionSelected = reactions[3] }
                if x > 170 && x < 230 { interactionSelected = reactions[2] }
                if x > 110 && x < 170 { interactionSelected = reactions[1] }
                if x > 50 && x < 110 { interactionSelected = reactions[0] }
                if x < 50 || x > 290 { interactionSelected = "" }
            }
            
        }
    }
    
    func onEnded(value: DragGesture.Value){
        withAnimation(Animation.linear){
            showInteractions = false
        }
        
        if interactionSelected == "like" {
            likeMessage()
        } else if interactionSelected == "dislike" {
            dislikeMessage()
        } else if interactionSelected == "copy" {
            copyMessage()
        } else if interactionSelected == "reply" {
            replyMessage()
        } else if interactionSelected == "edit" {
            editMessage()
        } else if interactionSelected == "trash" {
            trashMessage()
        }
    }

    func loadFirebase() {
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
        
    func likeMessage() {
        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id).child("likes")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(self.auth.profile.results.first?.id ?? 0)").exists() {
                self.hasUserLiked = false
                msg.child("\(self.auth.profile.results.first?.id ?? 0)").removeValue()
            } else {
                self.hasUserLiked = true
                msg.updateChildValues(["\(self.auth.profile.results.first?.id ?? 0)" : "\(Date())"])
            }
        })
    }
    
    func dislikeMessage() {
        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id).child("dislikes")

        msg.observeSingleEvent(of: .value, with: { snapshot in            
            if snapshot.childSnapshot(forPath: "\(self.auth.profile.results.first?.id ?? 0)").exists() {
                self.hasUserDisliked = false
                msg.child("\(self.auth.profile.results.first?.id ?? 0)").removeValue()
            } else {
                self.hasUserDisliked = false
                msg.updateChildValues(["\(self.auth.profile.results.first?.id ?? 0)" : "\(Date())"])
            }
        })
    }
    
    func copyMessage() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIPasteboard.general.setValue(self.message.text,
                    forPasteboardType: kUTTypePlainText as String)
        auth.notificationtext = "Successfully copied message"
        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
    }
    
    func replyMessage() {
        print("reply message")
    }
    
    func editMessage() {
        print("edit message")
    }
    
    func trashMessage() {
        self.auth.selectedConnectyDialog?.removeMessage(withID: self.message.id) { (error) in
            if error != nil {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            } else {
                changeMessageRealmData.updateMessageState(messageID: self.message.id, messageState: .deleted)
                auth.notificationtext = "Deleted Message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            }
        }
    }
}
