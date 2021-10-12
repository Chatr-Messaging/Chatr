//
//  BubbleDetailView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI
import SDWebImageSwiftUI
import MapKit
import Firebase
import MobileCoreServices
import ConnectyCube
import RealmSwift
import Photos
import MapKit

struct BubbleDetailView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    @ObservedObject var imagePicker = KeyboardCardViewModel()
    var namespace: Namespace.ID
    @Binding var newDialogFromSharedContact: Int
    @Binding var isDetailOpen: Bool
    @Binding var message: MessageStruct
    @State var subText: String = ""
    @State var height: CGFloat = 50
    @State var cardDrag = CGSize.zero
    @State var keyboardChange: CGFloat = CGFloat.zero
    @State var mainReplyText: String = ""
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State var showContact: Bool = false
    @State var showContentActions: Bool = false
    @State var repliesOpen: Bool = false
    @State var replyScrollOffset: CGFloat = CGFloat.zero
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State var messagePosition: messagePosition = .unknown
    @State var replies: [messageReplyStruct] = []
    let keyboard = KeyboardObserver()

    var body: some View {
        VStack(spacing: 0) {
            //MARK: Content Section
            ZStack() {
                VStack() {
                    //Top Header
                    HStack(alignment: .center, spacing: 10) {
                        WebImage(url: URL(string: viewModel.contact.avatar))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 34, height: 34, alignment: .bottom).scaledToFill() }
                            .indicator(.activity)
                            .scaledToFill()
                            .frame(width: 35, height: 35, alignment: .center)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)

                        VStack(alignment: .leading, spacing: 2.5) {
                            Text(viewModel.contact.fullName)
                                .foregroundColor(.primary)
                                .font(.none)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            HStack(alignment: .center) {
                                if self.message.isPinned {
                                    Image(systemName: "pin.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .rotationEffect(.degrees(-45))
                                        .frame(width: 14, height: 14, alignment: .center)
                                        .offset(y: 2)
                                        .foregroundColor(.secondary)
                                }

                                Text("sent " + self.viewModel.dateFormatTimeExtended(date: self.message.date))
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation {
                                self.showContentActions = false
                            }
                            
                            if self.message.imageType == "video/mov" {
                                self.viewModel.player.pause()
                            } else if self.message.imageType == "audio/m4a" {
                                self.viewModel.audio.audioPlayer.pause()
                                self.viewModel.audio.isPlayingAudio = false
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                withAnimation {
                                    self.isDetailOpen = false
                                }
                            }
                        }) {
                            Image("closeButton")
                                .resizable()
                                .frame(width: 30, height: 30, alignment: .center)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(showContentActions ? (!self.repliesOpen ? Double((200 - self.cardDrag.height) / 200) : 1) : 0)
                    .offset(y: showContentActions ? (!self.repliesOpen ? (self.cardDrag.height > 0 ? self.cardDrag.height / 4 : 0) : 0) : 60)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.showContact.toggle()
                    }

                    //Message Content View
                    if self.message.image != "" {
                        //Attachment
                        if self.message.imageType == "image/gif" && self.message.messageState != .deleted {
                            AnimatedImage(url: URL(string: self.message.image))
                                .resizable()
                                .frame(width: Constants.screenWidth, height: Constants.screenWidth / (self.message.mediaRatio != 0.0 ? self.message.mediaRatio : 1.0))
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(showContentActions ? (!self.repliesOpen ? (self.cardDrag.height > 0 ? self.cardDrag.height / 8 : 0) : 0) : 15)
                                .pinchToZoom()
                                .fixedSize(horizontal: false, vertical: true)
                                .matchedGeometryEffect(id: self.message.id.description + "gif", in: namespace)
                                .background(VStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .padding(.bottom, 5)
                                    Text("loading GIF...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                })
                                .zIndex(4)
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
                                }//.frame(maxHeight: Constants.screenHeight * 0.85, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(showContentActions ? (!self.repliesOpen ? (self.cardDrag.height > 0 ? self.cardDrag.height / 8 : 0) : 0) : 15)
                                .frame(maxHeight: Constants.screenHeight * 0.6)
                                .pinchToZoom()
                                .fixedSize(horizontal: false, vertical: true)
                                .matchedGeometryEffect(id: self.message.id.description + "png", in: namespace)
                                .zIndex(4)
                        } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {
                            ZStack(alignment: .center) {
                                DetailVideoPlayer(viewModel: self.viewModel)
                                    //.frame(maxWidth: CGFloat(Constants.screenWidth - 20), alignment: .center)
                                    //.frame(width: CGFloat(Constants.screenWidth - 20))
                                    //frame(height: CGFloat(self.message.mediaRatio * (Constants.screenWidth - 20)))
                                    .cornerRadius(showContentActions ? (!self.repliesOpen ? (self.cardDrag.height > 0 ? self.cardDrag.height / 8 : 0) : 0) : 15)
                                    .matchedGeometryEffect(id: self.message.id.description + "mov", in: namespace)
                                    .pinchToZoom()
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        withAnimation {
                                            self.viewModel.playVideoo.toggle()
                                        }
                                        self.viewModel.playVideoo ? self.viewModel.playVideo() : self.viewModel.pause()
                                    }
                                
                                //Big Play Button
                                if !self.viewModel.playVideoo {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        withAnimation {
                                            self.viewModel.playVideoo.toggle()
                                        }
                                        self.viewModel.playVideoo ? self.viewModel.playVideo() : self.viewModel.pause()
                                    }) {
                                        ZStack {
                                            BlurView(style: .systemUltraThinMaterialDark)
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())

                                            Image(systemName: self.viewModel.playVideoo ? "pause.fill" : "play.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25, alignment: .center)
                                                .offset(x: 2.5)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
                                                .padding(.all)
                                        }
                                    }.padding(.vertical, 35)
                                    .transition(.asymmetric(insertion: AnyTransition.scale.animation(.spring(response: 0.2, dampingFraction: 0.65, blendDuration: 0)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.14))))
                                    .zIndex(1)
                                }
                            }
                        } else if self.message.imageType == "audio/m4a" && self.message.messageState != .deleted {
                            //audio
                            AudioDetailView(viewModel: self.viewModel, message: self.message, namespace: self.namespace)
                                .frame(width: Constants.screenWidth * 0.8, height: 180)
                        }
                    } else if self.message.contactID != 0 {
                        //contact
                    } else if self.message.longitude != 0 && self.message.latitude != 0 {
                        //location
                        Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                            MapPin(coordinate: marker.coordinate)
                        }.frame(height: CGFloat(Constants.screenHeight * (self.replies.count == 0 ? 0.58 : self.replies.count == 1 ? 0.53 : 0.43)))
                        .cornerRadius(showContentActions ? (!self.repliesOpen ? (self.cardDrag.height > 0 ? self.cardDrag.height / 8 : 0) : 0) : 15)
                        .matchedGeometryEffect(id: self.message.id.description + "map", in: namespace)
                        .onAppear() {
                            self.region.center.latitude = self.message.latitude
                            self.region.center.longitude = self.message.longitude
                        }
                    } else {
                        //Text
                        if self.message.text.containsEmoji && self.message.text.count <= 4 {
                            Text(self.message.text)
                                .font(.system(size: 66))
                                .padding(.vertical, 15)
                                .offset(x: self.messagePosition == .right ? -10 : 10, y: -5)
                                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                                .matchedGeometryEffect(id: self.message.id.description + "text", in: namespace)
                        } else {
                            LinkedText(self.message.text, messageRight: self.messagePosition == .right, messageState: self.message.messageState)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 40)
                                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 1.5))
                                .matchedGeometryEffect(id: self.message.id.description + "text", in: namespace)
                        }
                    }

                    //Footer Section
                    VStack() {
                        //MARK: Video Player Controls
                        if self.message.image != "" && self.message.imageType == "video/mov" && self.message.messageState != .deleted{
                            HStack(spacing: 10) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation {
                                        self.viewModel.playVideoo.toggle()
                                    }
                                    self.viewModel.playVideoo ? self.viewModel.playVideo() : self.viewModel.pause()
                                }, label: {
                                    Image(systemName: self.viewModel.playVideoo ? "pause.fill" : "play.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22, alignment: .center)
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 2.5)
                                })
                            
                                Text(self.viewModel.videoTimeText)
                                    .font(.none)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                CustomProgressBar(viewModel: self.viewModel)
                            }.padding(.horizontal)
                        }

                        //MARK: Interaction Btns
                        HStack(spacing: 10) {
                            if self.message.messageState != .error {
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.viewModel.likeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { like in
                                            self.viewModel.isDetailOpen = true
                                            self.hasUserLiked = like
                                        })
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }, label: {
                                    HStack {
                                        Image("like")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.message.likedId.count)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(self.hasUserLiked ? .white : .primary)
                                            .padding(.horizontal, 3)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserLiked, messagePosition: self.$messagePosition))
                                
                                Button(action: {
                                    if self.messagePosition == .left {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        self.viewModel.dislikeMessage(from: self.auth.profile.results.last?.id ?? 0, name: self.auth.profile.results.last?.fullName ?? "A user", message: self.message, completion: { dislike in
                                            self.viewModel.isDetailOpen = true
                                            self.hasUserDisliked = dislike
                                        })
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }, label: {
                                    HStack {
                                        Image("dislike")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)

                                        Text("\(self.message.dislikedId.count)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(self.hasUserDisliked ? .white : .primary)
                                            .padding(.horizontal, 3)
                                    }.padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                }).buttonStyle(interactionButtonStyle(isHighlighted: self.$hasUserDisliked, messagePosition: self.$messagePosition))
                                
                                Spacer()
                                
                                //openMapForPlace button
                                if self.message.longitude != 0 && self.message.latitude != 0 {
                                    Button(action: {
                                        self.openMapForPlace(longitude: self.message.longitude, latitude: self.message.latitude)
                                    }, label: {
                                        Text("open  maps")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 15)
                                            .padding(.vertical, 5)
                                    }).buttonStyle(interactionDefaultButtonStyle())
                                }

                                if self.auth.selectedConnectyDialog?.type == .group || self.auth.selectedConnectyDialog?.type == .public {
                                    Text("\(self.message.readIDs.count) seen")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Menu {
                                    if self.message.messageState != .error {
                                        Button(action: {
                                            if messagePosition == .right {
                                                if let dialog = self.auth.selectedConnectyDialog {
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                    self.viewModel.trashMessage(connectyDialog: dialog, messageId: self.message.id , completion: {
                                                        self.viewModel.isDetailOpen = false
                                                    })
                                                }
                                            } else {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            }
                                        }) {
                                            Label(messagePosition == .right ? "Delete Message" : "Report Message", systemImage: messagePosition == .right ? "trash" : "exclamationmark.triangle")
                                                .foregroundColor(.red)
                                        }

                                        if self.message.imageType == "image/gif" || self.message.imageType == "image/png" {
                                            Button(action: {
                                                self.saveImage()
                                            }) {
                                                Label(self.message.imageType == "image/gif" ? "Save GIF" : "Save Image", systemImage: "square.and.arrow.down")
                                            }
                                        }

                                        if let dialog = self.auth.selectedConnectyDialog, let admins = dialog.adminsIDs, (admins.contains(NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID"))) || dialog.userID == UserDefaults.standard.integer(forKey: "currentUserID")), (dialog.type == .group || dialog.type == .public) {
                                            Button(action: {
                                                self.pinMessage()
                                            }) {
                                                Label(!self.message.isPinned ? "Pin" : "Unpin", systemImage: "pin")
                                            }
                                        }

                                        if self.message.contactID == 0 && self.message.longitude == 0 && self.message.latitude == 0 && self.message.imageType == "" {
                                            Button(action: {
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                                UIPasteboard.general.setValue(self.message.text, forPasteboardType: kUTTypePlainText as String)

                                                self.auth.notificationtext = "Copied message"
                                                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                                            }) {
                                                Label("Copy Text", systemImage: "doc.on.doc")
                                            }
                                        }

                                        if self.message.longitude != 0 && self.message.latitude != 0 {
                                            Button(action: {
                                                let copyText = "longitude: " + "\(self.message.longitude)" + "\n" + "latitude: " + "\(self.message.latitude)"

                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                                UIPasteboard.general.setValue(copyText, forPasteboardType: kUTTypePlainText as String)

                                                self.auth.notificationtext = "Copied message"
                                                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                                            }) {
                                                Label("Copy Location", systemImage: "doc.on.doc")
                                            }
                                        }
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
                                    //print("try again btn")
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
                    }
                    .opacity(showContentActions ? Double((200 - self.cardDrag.height) / 200) : 0)
                    .offset(y: showContentActions ? (self.cardDrag.height > 0 ? -(self.cardDrag.height / 4) : 0) : -60)
                    .padding(.bottom, 10)
                }
            }
            .frame(maxWidth: Constants.screenWidth - 20, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(Color("bgColor"))
                    .opacity(showContentActions ? Double((200 - self.cardDrag.height) / 200) : 0)
                    .scaleEffect(y: showContentActions ? (self.cardDrag.height > 0 ? 1 - (self.cardDrag.height / 1000) : 1) : 0.8)
            )
            .padding(.top, UIDevice.current.hasNotch ? 40 : 20)
            .padding(.top, self.repliesOpen ? -(Constants.screenHeight / 4) : 0)
            .padding(.horizontal, 10)
            .animation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0))
            .offset(y: self.cardDrag.height + 7)
            .offset(y: -self.replyScrollOffset)
            .offset(y: self.height > 175 ? -height : 0)
            .offset(y: -self.keyboardChange)
            .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 12)
            .zIndex(3)
            .rotation3DEffect(.degrees(!self.repliesOpen ? -Double(self.cardDrag.height > 20 ? ((self.cardDrag.height - 20) / 8 > 8 ? 8 : (self.cardDrag.height - 20) / 8) : 0) : 0), axis: (x: 1, y: 0, z: 0))
            .simultaneousGesture(DragGesture().onChanged { value in
                guard self.message.longitude == 0 && self.message.latitude == 0 && self.isDetailOpen else {
                    return
                }

                if self.viewModel.playVideoo {
                    withAnimation {
                        self.viewModel.playVideoo = false
                    }
                    self.viewModel.pause()
                }
                self.cardDrag.height = value.translation.height / 2
                if !self.repliesOpen && self.replies.count > 0 && value.translation.height < -105 {
                    withAnimation {
                        self.repliesOpen = true
                    }
                } else if self.repliesOpen && value.translation.height > 80 {
                    withAnimation {
                        self.repliesOpen = false
                    }
                }

                if self.keyboardChange != 0 {
                    UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                }
                
            }.onEnded { valueEnd in
                guard self.message.longitude == 0 && self.message.latitude == 0 && self.isDetailOpen else {
                    return
                }
                
                if self.cardDrag.height > 60 && !self.repliesOpen {
                    self.cardDrag = .zero
                    withAnimation {
                        self.isDetailOpen = false
                    }
                    UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    self.cardDrag = .zero
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            })

            //MARK: Reply Section
            VStack(alignment: self.replies.count == 0 ? .center : .leading, spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: self.replies.count == 0 ? .center : .leading) {
                        if self.replies.count > 0 {
                            HStack(alignment: .bottom) {
                                Text("Replies (\(self.replies.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.top, 25)
                                
                                Spacer()
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation {
                                        self.repliesOpen.toggle()
                                    }
                                }) {
                                    Text(self.repliesOpen ? "show less" : "show more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if self.showContentActions {
                            Text("empty replies")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, self.replies.isEmpty ? 40 : 0)
                                .opacity(self.replies.isEmpty ? 1 : 0)
                        }

                        ForEach(self.replies.indices, id:\.self) { reply in
                            MessageReplyCell(viewModel: self.viewModel, reply: self.replies[reply])
                                .environmentObject(self.auth)
                                .padding(.top, reply == 0 ? 5 : 0)
                                .id(self.replies[reply].id)
                                .transition(AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2)), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                        }.animation(.easeOut(duration: 0.4))
                    }.padding(.horizontal, 30)
                    .resignKeyboardOnDragGesture()
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self,
                            value: -$0.frame(in: .named("replyScroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        if $0 < 0 {
                            self.replyScrollOffset = $0
                            if self.repliesOpen && $0 < -55 {
                                withAnimation {
                                    self.repliesOpen = false
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                }
                            }
                        } else if !self.repliesOpen && self.replies.count > 0 && $0 > 55 {
                            withAnimation {
                                self.repliesOpen = true
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                        }
                    }
                }.frame(maxHeight: self.replies.count > 0 ? (self.replies.count >= 3 && self.repliesOpen ? Constants.screenHeight : Constants.screenHeight * 0.35) : (self.message.imageType != "" ? Constants.screenHeight * 0.2 : Constants.screenHeight * 0.28))
                .coordinateSpace(name: "replyScroll")
                .opacity(!self.repliesOpen ? Double((300 - self.cardDrag.height) / 300) : 1)
                .offset(y: showContentActions ? (self.cardDrag.height > 0 ? self.cardDrag.height / 4 : 0) : 0)
                .offset(y: -2)

                ResizableTextField(imagePicker: self.imagePicker, height: self.$height, text: self.$mainReplyText, isMessageView: false)
                    .environmentObject(self.auth)
                    .frame(height: self.height < 175 ? self.height : 175)
                    .padding(.horizontal, 30)
                    .padding(.trailing, 22.5)
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
                                    self.viewModel.sendReply(text: self.mainReplyText, name: self.auth.profile.results.last?.fullName ?? "A user", messagez: self.message, completion: {
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
            }//.frame(maxWidth: .infinity)
            .offset(y: -self.keyboardChange)
            .padding(.bottom, UIDevice.current.hasNotch ? 50 : 30)
            //.padding(.bottom, self.keyboardChange != 0 ? (self.keyboardChange - (UIDevice.current.hasNotch ? 50 : 30)) : (UIDevice.current.hasNotch ? 50 : 30))
            .opacity(!self.repliesOpen ? Double((200 - self.cardDrag.height) / 200) : 1)
            .zIndex(2)
        }.frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .bottom)
        .edgesIgnoringSafeArea(.all)
        .background(BlurView(style: .systemUltraThinMaterial).opacity(!self.repliesOpen ? Double((300 - self.cardDrag.height) / 300) : 1))
        .sheet(isPresented: self.$showContact, onDismiss: {
            //if self.chatContact != 0 && self.chatContact != self.message.senderID {
               //print("need to open Chat view!!111 \(newDialogFromSharedContact)")
            //}
        }) {
            NavigationView {
                VisitContactView(fromDialogCell: true, newMessage: self.$newDialogFromSharedContact, dismissView: self.$showContact, viewState: .fromRequests, contactRelationship: self.viewModel.contactRelationship, contact: self.viewModel.contact)
                    .environmentObject(self.auth)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                self.hasUserLiked = self.message.likedId.contains(self.auth.profile.results.first?.id ?? 0)
                self.hasUserDisliked = self.message.dislikedId.contains(self.auth.profile.results.first?.id ?? 0)
                self.messagePosition = UInt(self.message.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? .right : .left

                self.viewModel.message = self.message
                self.viewModel.fetchUser()
                self.observeInteractions()
                self.observeReplies()
                self.observeKeyboard()

                self.showContentActions = true
            }
        }
    }
    
    func observeInteractions() {
        guard self.message.dialogID != "", self.message.id != "" else {
            return
        }

        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id)
        let profileID = self.auth.profile.results.first?.id ?? 0

        msg.observe(.childAdded, with: { snapAdded in
            let typeLike = snapAdded.key

            for child in snapAdded.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    self.auth.messages.updateMessageLikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                } else if typeLike == "dislikes" {
                    self.auth.messages.updateMessageDislikeAdded(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
        
        msg.observe(.childRemoved, with: { snapRemoved in
            let typeLike = snapRemoved.key
            
            for child in snapRemoved.children {
                let childSnap = child as! DataSnapshot
                if typeLike == "likes" {
                    self.auth.messages.updateMessageLikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserLiked = self.message.likedId.contains(profileID)
                } else if typeLike == "dislikes" {
                    self.auth.messages.updateMessageDislikeRemoved(messageID: self.message.id, userID: Int(childSnap.key) ?? 0)
                    self.hasUserDisliked = self.message.dislikedId.contains(profileID)
                }
            }
        })
    }
    
    func observeReplies() {
        guard self.message.dialogID != "", self.message.id != "" else {
            return
        }

        let msg = Database.database().reference().child("Dialogs").child(self.message.dialogID).child(self.message.id).child("replies")

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
            if let index: Int = self.replies.firstIndex(where: { $0.id == snapRemoved.key }) {
                self.replies.remove(at: index)
            }
        })
    }
    
    func observeKeyboard() {
        keyboard.observe { (event) in
            guard self.viewModel.isDetailOpen else { return }

            let keyboardFrameEnd = event.keyboardFrameEnd
            
            switch event.type {
            case .willShow:
                UIView.animate(withDuration: event.duration, delay: 0.0, options: [event.options], animations: {
                    self.keyboardChange = keyboardFrameEnd.height * 0.70 - 10
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

    func pinMessage() {
        self.viewModel.pinMessage(message: self.message, completion: { added in
            if !added {
                self.auth.dialogs.removeDialogPin(messageId: self.message.id, dialogID: self.message.dialogID)
                auth.notificationtext = "Removed pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            } else {
                self.auth.dialogs.addDialogPin(messageId: self.message.id, dialogID: self.message.dialogID)
                auth.notificationtext = "Pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            }
        })
    }
    
    func saveImage() {
        if let imageData = SDImageCache.shared.imageFromMemoryCache(forKey: self.message.image)?.pngData() {
            //use image
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
            }) { (success, error) in
                if error == nil {
                    DispatchQueue.main.async {
                        auth.notificationtext = "Saved image"
                        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    func openMapForPlace(longitude: Double, latitude: Double) {
        let regionDistance: CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)

        mapItem.name = self.viewModel.contact.fullName + "'s Chatr Location"
        mapItem.openInMaps(launchOptions: options)
    }

    func getTotalDurationString() -> String {
        let m = Int(self.viewModel.totalDuration / 60)
        let s = Int(self.viewModel.totalDuration.truncatingRemainder(dividingBy: 60))

        return String(format: "%d:%02d", arguments: [m, s])
    }

    func getSliderValue() -> Float {
        
        return Float(self.viewModel.player.currentTime().seconds / (self.viewModel.player.currentItem?.duration.seconds)!)
    }
}
