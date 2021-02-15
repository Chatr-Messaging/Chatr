//
//  LocationBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/29/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import MapKit
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift
import Firebase

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
    @State var isOpen: Bool = false
    @State var showInteractions: Bool = false
    @State var moveUpAnimation: Bool = false
    @State var interactionSelected: String = ""
    @State var reactions: [String] = []
    @State var hasUserLiked: Bool = false
    @State var hasUserDisliked: Bool = false
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .topTrailing : .topLeading) {
            ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
                if self.message.messageState != .deleted {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.isOpen.toggle()
                    }) {
                        Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                            MapPin(coordinate: marker.coordinate)
                        }.frame(height: CGFloat(Constants.screenWidth * 0.6))
                        .cornerRadius(20)
                        .padding(.leading, self.messagePosition == .right ? 35 : 0)
                        .padding(.trailing, self.messagePosition == .right ? 0 : 35)
                        .padding(.bottom, self.hasPrior ? 0 : 15)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                        .animation(nil)
                        //.disabled(!self.isOpen ? true : false)
                        .onAppear() {
                            self.region.center.latitude = self.message.latitude
                            self.region.center.longitude = self.message.longitude
                        }
                    }.buttonStyle(ClickMiniButtonStyle())
                    .scaleEffect(self.showInteractions ? 1.1 : 1.0)
                }
            }
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
