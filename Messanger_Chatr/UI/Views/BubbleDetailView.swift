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
    @State var message: MessageStruct = MessageStruct()
    @State var delayView: Bool = false
    @State var avatar: String = ""
    @State var fullName: String = ""
    @State var subText: String = ""
    @State var height: CGFloat = 175
    @State var mainReplyText: String = ""
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State var messagePosition: messagePosition = .unknown

    var body: some View {
        VStack {
            Spacer()

            //MARK: Content Section
            ZStack(alignment: .bottom) {
                //MARK: Background Card

//                }.frame(height: 80)
//                .transition(.asymmetric(insertion: AnyTransition.move(edge: .top).animation(.easeOut(duration: 0.35)), removal: AnyTransition.move(edge: .top).animation(.easeOut(duration: 0.25))))
//                .background(Color("bgColor").opacity(0.7))
//                .cornerRadius(20)
//                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("bgColor"), lineWidth: 1).blur(radius: 1))
//                .padding(.horizontal, 35)
//                .offset(y: 65)
//                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)

                //MARK: Message Content Section
                VStack {
                    HStack {
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
                                .matchedGeometryEffect(id: message.id.description + "avatar", in: namespace)

                            VStack(alignment: .leading) {
                                Text(self.fullName)
                                    .foregroundColor(self.message.messageState == .error ? .red : .primary)
                                    .font(.none)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Text("last seen 2hrs ago")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
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
                    }.padding(.horizontal)
                    
                    if self.message.image != "" {
                        //Attachment
                        if self.message.imageType == "image/gif" && self.message.messageState != .deleted {
                            AnimatedImage(url: URL(string: self.message.image))
                                .resizable()
                                .placeholder {
                                    VStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .padding(.bottom, 5)
                                        Text("loading GIF...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }.frame(maxHeight: Constants.screenHeight * 0.6, alignment: .center)
                                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeOut(duration: 0.35)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.25))))
                                .aspectRatio(contentMode: .fit)
                                //.clipShape(CustomGIFShape())
                                //.shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                                .matchedGeometryEffect(id: self.viewModel.selectedMessageId + "gif", in: namespace)
                        } else if self.message.imageType == "image/png" && self.message.messageState != .deleted {
                            WebImage(url: URL(string: self.message.image))
                                .resizable()
                                .placeholder {
                                    VStack {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .padding(.bottom, 5)
                                        Text("loading image...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxHeight: Constants.screenHeight * 0.6, alignment: .center)
                                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                .aspectRatio(contentMode: .fit)
                                //.clipShape(CustomGIFShape())
                                //.shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                                .matchedGeometryEffect(id: self.viewModel.selectedMessageId + "png", in: namespace)
                        } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {

                        }
                    } else if self.message.contactID != 0 {
                        //contact
                    } else if self.message.longitude != 0 && self.message.latitude != 0 {
                        //location
                        Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                            MapPin(coordinate: marker.coordinate)
                        }.frame(minHeight: 200, maxHeight: CGFloat(Constants.screenHeight * 0.6))
                        .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        //.cornerRadius(20)
                        //.padding(.horizontal)
                        //.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                        .matchedGeometryEffect(id: message.id.description + "map", in: namespace)
                        .onAppear() {
                            self.region.center.latitude = self.message.latitude
                            self.region.center.longitude = self.message.longitude
                        }
                    } else {
                        //Text
                    }
                    
                    VStack() {
                        //MARK: Interaction Btns
                        HStack(spacing: 10) {
                            if self.message.messageState != .error {
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                            self.hasUserLiked = like
                                        })
                                    }
                                }, label: {
                                    HStack {
                                        Image("like")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.message.likedId.count)")
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
                                        self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                                            self.hasUserDisliked = dislike
                                        })
                                    }
                                }, label: {
                                    HStack {
                                        Image("dislike")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.message.dislikedId.count)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 3)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                                
                                Spacer()
                                Button(action: {
                                    print("more button")
                                }, label: {
                                    HStack {
                                        Image(systemName: "ellipsis")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25, alignment: .center)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(ClickButtonStyle())
                            } else {
                                Button(action: {
                                    print("try again btn")
                                }, label: {
                                    HStack {
                                        Text("try again")
                                            .foregroundColor(.red)
                                            .fontWeight(.medium)
                                            .frame(height: 50)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(ClickButtonStyle())
                            }
                        }.padding(.horizontal, 10)
                        .offset(y: -2.5)
                        
                        HStack {
                            Text(self.viewModel.dateFormatTimeExtended(date: message.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .matchedGeometryEffect(id: message.id.description + "subtext", in: namespace)
                            
                            Spacer()
                            if self.auth.selectedConnectyDialog?.type == .group || self.auth.selectedConnectyDialog?.type == .public {
                                Text("\(self.message.readIDs.count) seen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }.padding(.horizontal, 15)
                    }
                }.padding(.vertical, 10)
            }.background(RoundedRectangle(cornerRadius: 20).foregroundColor(Color("bgColor")))
            .padding(.vertical, UIDevice.current.hasNotch ? 40 : 20)
            .padding(.horizontal)
            .animation(.easeOut)
            .offset(y: self.height < 175 ? -height : 0)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 12)

            Spacer()
            //MARK: Reply Section
            ZStack(alignment: .bottom) {
                ResizableTextField(imagePicker: self.imagePicker, height: self.$height, text: self.$mainReplyText)
                    .environmentObject(self.auth)
                    .frame(height: self.height < 175 ? self.height : 175)
                    .padding(.horizontal, 30)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color("lightGray"), lineWidth: 2).padding(.horizontal))
                    .background(
                        HStack {
                            Text("type reply")
                                .font(.system(size: 18))
                                .padding(.vertical, 10)
                                .padding(.leading, 35)
                                .offset(y: -1)
                                .foregroundColor(self.mainReplyText.count == 0 ? Color("lightGray") : .clear)
                            Spacer()
                        }
                    ).overlay(
                        HStack(alignment: .bottom) {
                            Spacer()
                            Button(action: {
                                print("send reply")
                            }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .padding(.trailing, 20)
                                    .foregroundColor(self.mainReplyText.count == 0 ? Color("lightGray") : .blue)
                            }
                        }.frame(height: self.height < 175 ? self.height : 175)
                    )
                    .padding(.bottom, UIDevice.current.hasNotch ? 40 : 20)
            }
        }.frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
        .background(BlurView(style: .systemUltraThinMaterial))
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("the selected message id is: \(self.viewModel.selectedMessageId)")

                self.message = self.viewModel.fetchMessage(messageId: self.viewModel.selectedMessageId)
                self.hasUserLiked = self.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
                self.hasUserDisliked = self.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)
                self.messagePosition = UInt(self.message.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left

                self.viewModel.getUserAvatar(senderId: self.message.senderID, compleation: { (url, fullName) in
                    if url == "self" || fullName == "self" {
                        self.avatar = self.auth.profile.results.first?.avatar ?? ""
                        self.fullName = self.auth.profile.results.first?.fullName ?? ""
                    } else {
                        self.avatar = url
                        self.fullName = fullName
                    }
                    self.delayView = true
                })
                
                self.observeInteractions()
            }
        }.onDisappear() {
            self.viewModel.selectedMessageId = ""
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
