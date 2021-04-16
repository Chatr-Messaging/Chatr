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
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    var namespace: Namespace.ID

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            withAnimation {
                self.viewModel.message = self.message
                self.viewModel.isDetailOpen = true
            }
        }) {
            Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: self.message.latitude, longitude: self.message.longitude))]) { marker in
                MapPin(coordinate: marker.coordinate)
            }
        }.frame(width: CGFloat(Constants.screenWidth * 0.7), height: CGFloat(Constants.screenWidth * 0.5))
        .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
        .cornerRadius(20)
        //.padding(.leading, self.messagePosition == .right ? CGFloat(Constants.screenHeight * 0.1) : 0)
        //.padding(.trailing, self.messagePosition == .right ? 0 : CGFloat(Constants.screenHeight * 0.1))
        .padding(.bottom, self.hasPrior ? 0 : 4)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
        .matchedGeometryEffect(id: message.id + "map", in: namespace)
        .buttonStyle(ClickMiniButtonStyle())
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5))
        .simultaneousGesture(DragGesture(minimumDistance: self.viewModel.isDetailOpen ? 0 : 500))
        .onAppear() {
            self.region.center.latitude = self.message.latitude
            self.region.center.longitude = self.message.longitude
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
