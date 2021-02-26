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

struct BubbleDetailView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    var namespace: Namespace.ID
    @State var message: MessageStruct = MessageStruct()
    @State var delayView: Bool = false
    @State var avatar: String = ""
    @State var fullName: String = ""
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    var body: some View {
        ZStack(alignment: .center) {
            BlurView(style: .systemUltraThinMaterial)
                .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)

            VStack {
                //MARK: Main Content Section
                HStack {
                    Text("\(self.viewModel.dateFormatTimeExtended(date: message.date))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    
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
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2.5)
                    }
                }.padding(.horizontal)
                .padding(.bottom, 5)
                
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
                            }.frame(maxHeight: Constants.screenHeight * 0.65, alignment: .center)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeOut(duration: 0.35)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.25))))
                            .aspectRatio(contentMode: .fit)
                            .clipShape(CustomGIFShape())
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
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
                            .frame(maxHeight: Constants.screenHeight * 0.65, alignment: .center)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .aspectRatio(contentMode: .fit)
                            .clipShape(CustomGIFShape())
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                            .matchedGeometryEffect(id: self.viewModel.selectedMessageId + "png", in: namespace)
                    } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {

                    }
                } else if self.message.contactID != 0 {
                    //contact
                } else if self.message.longitude != 0 && self.message.latitude != 0 {
                    //location
                    Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                        MapPin(coordinate: marker.coordinate)
                    }.frame(height: CGFloat(Constants.screenHeight * 0.7))
                    .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                    .matchedGeometryEffect(id: message.id.description + "map", in: namespace)
                    .onAppear() {
                        self.region.center.latitude = self.message.latitude
                        self.region.center.longitude = self.message.longitude
                    }
                } else {
                    //Text
                }
                
                //MARK: User Info Section
                WebImage(url: URL(string: self.avatar))
                    .resizable()
                    .placeholder{ Image("empty-profile").resizable().frame(width: 34, height: 34, alignment: .bottom).scaledToFill() }
                    .indicator(.activity)
                    .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 34, height: 34, alignment: .bottom)
                    .offset(y: 2)
                    .matchedGeometryEffect(id: message.id.description + "avatar", in: namespace)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
            }
        }.onAppear() {
            //DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            print("the selected message id is: \(self.viewModel.selectedMessageId)")
                self.message = self.viewModel.fetchMessage(messageId: self.viewModel.selectedMessageId)
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
            //}
        }.onDisappear() {
            self.viewModel.selectedMessageId = ""
        }
    }
}
