//
//  LocationBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/29/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MapKit
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct MyAnnotationItem: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct LocationBubble: View {
    @EnvironmentObject var auth: AuthModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    var hasPrior: Bool = false
    @State var avatar: String = ""
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 25.7617,
                longitude: 80.1918
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.05,
                longitudeDelta: 0.05
            )
        )
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
            if self.message.messageState != .deleted {
                Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                    MapPin(coordinate: marker.coordinate)
                }.frame(height: CGFloat(Constants.screenWidth * 0.4))
                .cornerRadius(20)
                .padding(.leading, self.messagePosition == .right ? 35 : 0)
                .padding(.trailing, self.messagePosition == .right ? 0 : 35)
                .padding(.bottom, self.hasPrior ? 0 : 15)
                //.aspectRatio(contentMode: .fill)
                //.clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                //.contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                .animation(nil)
                //.offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                .onAppear() {
                    self.region.center.latitude = self.message.latitude
                    self.region.center.longitude = self.message.longitude
                }
                .contextMenu {
                    VStack {
                        if messagePosition == .right {
                            if self.message.messageState != .deleted {
                                Button(action: {
                                    print("Delete Map")
                                    self.auth.selectedConnectyDialog?.removeMessage(withID: self.message.id) { (error) in
                                        if error != nil {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        } else {
                                            changeMessageRealmData.updateMessageState(messageID: self.message.id, messageState: .deleted)
                                        }
                                    }
                                }) { HStack {
                                    Image(systemName: "trash")
                                    Text("Delete")
                                        .foregroundColor(.red) }
                                }
                            }
                        }
                        Button(action: {
                            print("Forward Map")
                        }) { HStack {
                            Image(systemName: "arrowshape.turn.up.left")
                            Text("Forward Map") }
                        }
                        Button(action: {
                            print("Open in maps")
                            self.openMapForPlace()
                        }) { HStack {
                            Image(systemName: "arrowshape.turn.up.left")
                            Text("Open in Maps") }
                        }
                    }
                }
            } else if self.message.messageState == .deleted {
                ZStack {
                    Text("deleted")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(self.message.messageState != .deleted ? messagePosition == .right ? .white : .primary : .secondary)
                        .padding(.vertical, 8)
                        .lineLimit(nil)
                }.padding(.horizontal, 15)
                .padding(.bottom, self.hasPrior ? 0 : 15)
                .background(self.messagePosition == .right && self.message.messageState != .deleted ? LinearGradient(
                    gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                    startPoint: .top, endPoint: .bottom) : LinearGradient(
                        gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: self.messagePosition == .right && self.message.messageState != .deleted ? Color.blue.opacity(0.2) : Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                
            }
            
            HStack {
                if messagePosition == .right { Spacer() }
                
                Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right))
                    .foregroundColor(self.message.messageState == .error ? .red : .gray)
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
        }.onAppear() {
            print("the image type is: \(self.message.imageType)")
            if self.message.senderID == UserDefaults.standard.integer(forKey: "currentUserID") {
                //get profile image
                self.avatar = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.avatar ?? ""
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                        self.avatar = foundContact.avatar
                    } else {
                        Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            self.avatar = PersistenceManager().getCubeProfileImage(usersID: users.first!) ?? ""
                        })
                    }
                } catch {
                    
                }
            }
        }
    }
    
    func openMapForPlace() {
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(self.message.latitude, self.message.longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Chatr Location"
        mapItem.openInMaps(launchOptions: options)
    }
}
