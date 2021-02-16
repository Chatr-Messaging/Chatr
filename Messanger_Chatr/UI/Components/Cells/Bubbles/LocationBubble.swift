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
    var hasPrior: Bool = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State var isOpen: Bool = false
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))

    var body: some View {
        ZStack {
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
                    .onAppear() {
                        self.region.center.latitude = self.message.latitude
                        self.region.center.longitude = self.message.longitude
                    }
                }.buttonStyle(ClickMiniButtonStyle())
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5))
            }
        }.simultaneousGesture(DragGesture(minimumDistance: self.isOpen ? 0 : 500))
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
