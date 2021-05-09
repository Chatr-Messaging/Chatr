//
//  PinnedSectionView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/2/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Grid
import SDWebImageSwiftUI
import MapKit

struct PinnedSectionView: View {
    @State var dialog: DialogStruct = DialogStruct()
    @State var style = StaggeredGridStyle(.horizontal, tracks: .fixed(98), spacing: 2.5)
    @Namespace var namespace
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var userTrackingMode: MapUserTrackingMode = .follow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PINNED:")
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.bottom, 2.5)

            ScrollView(style.axes) {
                Grid(self.dialog.pinMessages, id: \.self) { pinId in
                    if let messagez = self.dialog.messages.first(where: { $0.id == pinId }) {
                        if messagez.image != "" {
                            //Attachment
                            if messagez.imageType == "image/gif" {
                                //GIF
                                AnimatedImage(url: URL(string: messagez.image))
                                    .resizable()
                                    .placeholder {
                                        VStack {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .padding(.bottom, 5)

                                            Text("loading GIF...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }.aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 98)
                            } else if messagez.imageType == "image/png" {
                                //Image
                                WebImage(url: URL(string: messagez.image))
                                    .resizable()
                                    .placeholder {
                                        VStack {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .padding(.bottom, 5)
                                            Text("loading image...")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }.padding(.vertical)
                                    }.aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 98)
                            }
                        } else if messagez.contactID != 0 {
                            //Contact
                        } else if messagez.longitude != 0 && messagez.latitude != 0 {
                            //Location
                            Map(coordinateRegion: $region, interactionModes: MapInteractionModes.zoom, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [MyAnnotationItem(coordinate: CLLocationCoordinate2D(latitude: messagez.latitude, longitude: messagez.longitude))]) { marker in
                                MapPin(coordinate: marker.coordinate)
                            }.frame(width: 160, height: 98)
                            .onAppear() {
                                self.region.center.latitude = messagez.latitude
                                self.region.center.longitude = messagez.longitude
                            }
                        } else {
                            TextBubble(message: messagez, messagePosition: .right, namespace: self.namespace, isPinned: true)
                                .frame(width: CGFloat(messagez.bubbleWidth + 10), height: 98)
                                .padding(.horizontal)
                                .background(Color("buttonColor").opacity(0.5))
                        }
                    }
                }.cornerRadius(15)
                .frame(height: 200, alignment: .center)
                .padding(.leading)
                .animation(.easeInOut)
            }.shadow(color: Color.black.opacity(0.2), radius: 12.5, x: 0, y: 8)
            .padding(.bottom, 10)
            .padding(.trailing)
            .gridStyle(self.style)
        }
        .padding(.bottom)
    }
}
