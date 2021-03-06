//
//  BubbleDetailView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import MapKit
import Firebase

struct BubbleDetailView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    @StateObject var imagePicker = KeyboardCardViewModel()
    var namespace: Namespace.ID
    @State var delayView: Bool = false
    @State var avatar: String = ""
    @State var lastOnline: Date = Date()
    @State var fullName: String = ""
    @State var subText: String = ""
    @State var height: CGFloat = 50
    @State var cardDrag = CGSize.zero
    @State var keyboardChange: CGFloat = CGFloat.zero
    @State var mainReplyText: String = ""
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State var messagePosition: messagePosition = .unknown
    @State var replies: [messageReplyStruct] = []
    let keyboard = KeyboardObserver()

    var body: some View {
        VStack(spacing: 0) {
            if self.keyboardChange == 0 && self.replies.count == 0 { Spacer() }

            //MARK: Content Section
            ZStack() {
                VStack() {
                    //Top Header
                    HStack(alignment: .center, spacing: 10) {
                        WebImage(url: URL(string: self.avatar))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 34, height: 34, alignment: .bottom).scaledToFill() }
                            .indicator(.activity)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 35, height: 35, alignment: .center)
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)

                        VStack(alignment: .leading) {
                            Text(self.fullName)
                                .foregroundColor(.primary)
                                .font(.none)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text("last online \(self.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation {
                                self.viewModel.isDetailOpen = false
                            }
                        }) {
                            Image("closeButton")
                                .resizable()
                                .frame(width: 30, height: 30, alignment: .center)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                        }
                    }.padding(.horizontal).padding(.top, 10)

                    //Message Content View
                    if self.viewModel.message.image != "" {
                        //Attachment
                        if self.viewModel.message.imageType == "image/gif" && self.viewModel.message.messageState != .deleted {
                            AnimatedImage(url: URL(string: self.viewModel.message.image))
                                .resizable()
                                .placeholder {
                                    VStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .padding(.bottom, 5)
                                        Text("loading GIF...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }//.frame(maxHeight: Constants.screenHeight * 0.85, alignment: .center)
                                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeOut(duration: 0.35)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.25))))
                                .aspectRatio(contentMode: .fit)
                                .pinchToZoom()
                                .fixedSize(horizontal: false, vertical: true)
                                .matchedGeometryEffect(id: self.viewModel.message.id.description + "gif", in: namespace)
                                .zIndex(4)
                        } else if self.viewModel.message.imageType == "image/png" && self.viewModel.message.messageState != .deleted {
                            WebImage(url: URL(string: self.viewModel.message.image))
                                .resizable()
                                .placeholder {
                                    VStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .padding(.bottom, 5)
                                        Text("loading image...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }//.frame(maxHeight: Constants.screenHeight * 0.85, alignment: .center)
                                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                .aspectRatio(contentMode: .fit)
                                .pinchToZoom()
                                .fixedSize(horizontal: false, vertical: true)
                                .matchedGeometryEffect(id: self.viewModel.message.id.description + "png", in: namespace)
                                .zIndex(4)
                        } else if self.viewModel.message.imageType == "video/mov" && self.viewModel.message.messageState != .deleted {

                        }
                    } else if self.viewModel.message.contactID != 0 {
                        //contact
                    } else if self.viewModel.message.longitude != 0 && self.viewModel.message.latitude != 0 {
                        //location
                        Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.viewModel.message.latitude, longitude: self.viewModel.message.longitude))]) { marker in
                            MapPin(coordinate: marker.coordinate)
                        }.frame(minHeight: 200, maxHeight: CGFloat(Constants.screenHeight * 0.6))
                        .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .matchedGeometryEffect(id: self.viewModel.message.id.description + "map", in: namespace)
                        .onAppear() {
                            self.region.center.latitude = self.viewModel.message.latitude
                            self.region.center.longitude = self.viewModel.message.longitude
                        }
                    } else {
                        //Text
                    }

                    //Footer Section
                    VStack() {
                        //MARK: Interaction Btns
                        HStack(spacing: 10) {
                            if self.viewModel.message.messageState != .error {
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", completion: { like in
                                            self.viewModel.isDetailOpen = true
                                            self.hasUserLiked = like
                                        })
                                    }
                                }, label: {
                                    HStack {
                                        Image("like")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.viewModel.message.likedId.count)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 3)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserLiked, messagePosition: self.$messagePosition))
                                
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", completion: { dislike in
                                            self.viewModel.isDetailOpen = true
                                            self.hasUserDisliked = dislike
                                        })
                                    }
                                }, label: {
                                    HStack {
                                        Image("dislike")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.viewModel.message.dislikedId.count)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 3)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                                
                                Spacer()
                                Menu {
                                    Button(action: {
                                        print("more button")
                                    }) {
                                        Label("Add", systemImage: "plus.circle")
                                    }

                                    Button(action: {
                                        print("more button")
                                    }) {
                                        Label("Edit", systemImage: "pencil.circle")
                                    }
                                    
                                    Button(action: {
                                        print("more button")
                                    }) {
                                        Label("Delete", systemImage: "minus.circle")
                                            .foregroundColor(.red)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "ellipsis")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 25, alignment: .center)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }.buttonStyle(ClickButtonStyle())
                            } else {
                                Button(action: {
                                    print("try again btn")
                                }, label: {
                                    HStack {
                                        Text("try again")
                                            .foregroundColor(.red)
                                            .fontWeight(.medium)
                                            .frame(height: 35)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(ClickButtonStyle())
                            }
                        }.padding(.horizontal, 10)

                        HStack {
                            Text("sent " + self.viewModel.dateFormatTimeExtended(date: self.viewModel.message.date))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()
                            if self.auth.selectedConnectyDialog?.type == .group || self.auth.selectedConnectyDialog?.type == .public {
                                Text("\(self.viewModel.message.readIDs.count) seen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }.padding(.horizontal, 15)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                }
            }
            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color("bgColor")))
            //.padding(.top, UIDevice.current.hasNotch ? 40 : 20)
            .padding(.horizontal, 10)
            .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0))
            .offset(y: self.cardDrag.height + 7)
            .offset(y: self.height > 175 ? -height : 0)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 12)
            .zIndex(3)
            .rotation3DEffect(.degrees(-Double(self.cardDrag.height > 20 ? ((self.cardDrag.height - 20) / 8 > 8 ? 8 : (self.cardDrag.height - 20) / 8) : 0)), axis: (x: 1, y: 0, z: 0))
            .simultaneousGesture(DragGesture().onChanged { value in
                if self.viewModel.message.longitude == 0 && self.viewModel.message.latitude == 0 && self.viewModel.isDetailOpen {
                    self.cardDrag.height = value.translation.height / 2
                    if self.keyboardChange != 0 {
                        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                    }
                }
            }.onEnded { valueEnd in
                if self.viewModel.message.longitude == 0 && self.viewModel.message.latitude == 0 && self.viewModel.isDetailOpen {
                    if self.cardDrag.height > 60 {
                        self.cardDrag = .zero
                        withAnimation {
                            self.viewModel.isDetailOpen = false
                        }
                        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    } else {
                        self.cardDrag = .zero
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            })
//            .actionSheet(isPresented: $openMoreOptions) {
//                ActionSheet(title: Text("Options:"), message: nil, buttons: [
//                    .default(Text("Copy")) {
//                        print("")
//                    },
//                    .destructive(Text(self.dialogModel.dialogType == "private" ? "Delete Dialog" : (self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? "Destroy Group" : "Leave Group")), action: {
//                        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.dialogModel.id)
//
//                        self.isOpen = false
//                        self.openActionSheet = false
//                        UserDefaults.standard.set(false, forKey: "localOpen")
//
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            if self.dialogModel.dialogType == "private" || self.dialogModel.dialogType == "group" {
//                                changeDialogRealmData.shared.deletePrivateConnectyDialog(dialogID: self.dialogModel.id, isOwner: self.dialogModel.owner == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false)
//                            } else if self.dialogModel.dialogType == "public" {
//                                changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: self.dialogModel.id)
//                            }
//                        }
//                    }),
//                    .cancel()
//                ])
//            }

            //MARK: Reply Section
            VStack(alignment: .center, spacing: 0) {
                if self.replies.isEmpty {
                    Text("no replies")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 40)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(alignment: .leading) {
                            ForEach(self.replies.indices) { reply in
                                MessageReplyCell(reply: self.replies[reply])
                                    .padding(.top, reply == 0 ? 20 : 0)
                                    .transition(AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2)), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                            }.animation(.easeOut(duration: 0.4))
                        }.padding(.horizontal, 30)
                    }
                    .frame(maxHeight: (Constants.screenHeight / 7.5) + (self.cardDrag.height < 0 ? -self.cardDrag.height : 0))
                    .opacity(Double((300 - self.cardDrag.height) / 300))
                    .offset(y: -2)
                }

                ResizableTextField(imagePicker: self.imagePicker, height: self.$height, text: self.$mainReplyText, isMessageView: false)
                    .environmentObject(self.auth)
                    .frame(height: self.height < 175 ? self.height : 175)
                    .padding(.horizontal, 30)
                    .background(
                        ZStack() {
                            RoundedRectangle(cornerRadius: 20).stroke(Color("lightGray"), lineWidth: 2).padding(.horizontal)
                            HStack {
                                Text("type reply")
                                    .font(.system(size: 18))
                                    .padding(.vertical, 10)
                                    .padding(.leading, 35)
                                    .offset(y: -1)
                                    .foregroundColor(self.mainReplyText.count == 0 ? Color("lightGray") : .clear)
                                Spacer()
                            }
                        }
                    ).overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.viewModel.sendReply(text: self.mainReplyText, name: self.fullName, completion: {
                                        self.mainReplyText = ""
                                        self.height = 0
                                    })
                                }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                        .padding(.trailing, 20)
                                        .foregroundColor(self.mainReplyText.count == 0 ? Color("lightGray") : .blue)
                                }
                            }.offset(y: -4)
                        }
                    )
            }.frame(maxWidth: .infinity)
            .offset(y: self.cardDrag.height > 0 ? self.cardDrag.height / 4 : 0)
            .padding(.bottom, self.keyboardChange != 0 ? (self.keyboardChange - (UIDevice.current.hasNotch ? 50 : 30)) : (UIDevice.current.hasNotch ? 50 : 30))
            .opacity(Double((200 - self.cardDrag.height) / 200))
            .zIndex(2)
        }.frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .bottom)
        .edgesIgnoringSafeArea(.all)
        .background(BlurView(style: .systemUltraThinMaterial).opacity(Double((300 - self.cardDrag.height) / 300)))
        .onAppear() {
            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
            self.hasUserLiked = self.viewModel.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
            self.hasUserDisliked = self.viewModel.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)
            self.messagePosition = UInt(self.viewModel.message.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left

            self.viewModel.getUserAvatar(senderId: self.viewModel.message.senderID, compleation: { (url, fullName, lastOnline) in
                if url == "self" || fullName == "self" || lastOnline == Date() {
                    self.avatar = self.auth.profile.results.first?.avatar ?? ""
                    self.lastOnline = self.auth.profile.results.first?.lastOnline ?? Date()
                    self.fullName = self.auth.profile.results.first?.fullName ?? ""
                } else {
                    self.avatar = url
                    self.lastOnline = lastOnline
                    self.fullName = fullName
                }
                self.delayView = true
            })
            
            self.observeInteractions()
            self.observeReplies()
        
            keyboard.observe { (event) in
                guard self.viewModel.isDetailOpen else { return }

                let keyboardFrameEnd = event.keyboardFrameEnd
                
                switch event.type {
                case .willShow:
                    UIView.animate(withDuration: event.duration, delay: 0.0, options: [event.options], animations: {
                        self.keyboardChange = keyboardFrameEnd.height - 10
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
    
    func observeInteractions() {
        let msg = Database.database().reference().child("Dialogs").child(self.viewModel.message.dialogID).child(self.viewModel.message.id)
        let profileID = self.auth.profile.results.first?.id ?? 0

        msg.observe(.childAdded, with: { snapAdded in
            let typeLike = snapAdded.key

            for child in snapAdded.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.shared.updateMessageLikeAdded(messageID: self.viewModel.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.viewModel.message.likedId.contains(profileID)
                    print("liked added: contain: \(self.viewModel.message.likedId.contains(profileID)) && my id: \(profileID)")
                } else if typeLike == "dislikes" {
                    changeMessageRealmData.shared.updateMessageDislikeAdded(messageID: self.viewModel.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.viewModel.message.dislikedId.contains(profileID)
                }
            }
        })
        
        msg.observe(.childRemoved, with: { snapRemoved in
            let typeLike = snapRemoved.key
            
            for child in snapRemoved.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    changeMessageRealmData.shared.updateMessageLikeRemoved(messageID: self.viewModel.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.viewModel.message.likedId.contains(profileID)
                } else if typeLike == "dislikes" {
                    changeMessageRealmData.shared.updateMessageDislikeRemoved(messageID: self.viewModel.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.viewModel.message.dislikedId.contains(profileID)
                }
            }
        })
    }
    
    func observeReplies() {
        let msg = Database.database().reference().child("Dialogs").child(self.viewModel.message.dialogID).child(self.viewModel.message.id).child("replies")

        msg.observe(.childAdded, with: { snapAdded in
            guard let dict = snapAdded.value as? [String: Any] else { return }

            if let timeStamp = dict["timestamp"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
                if let timestampDate = dateFormatter.date(from: timeStamp) {
                    let reply = messageReplyStruct(id: snapAdded.key, fromId: dict["fromId"] as? String ?? "", text: dict["text"] as? String ?? "", date: timestampDate)

                    withAnimation(Animation.easeOut(duration: 0.25)) {
                        self.replies.insert(reply, at: 0)
                    }
                }
            }
        })
        
        msg.observe(.childRemoved, with: { snapRemoved in
//            if let removeIndex = self.replies.firstIndex(where: self.replies.filter({ $0.id == snapRemoved.key }).first? ?? messageReplyStruct()) {
//                self.replies.remove(at: removeIndex)
//            }
        })
    }
}
