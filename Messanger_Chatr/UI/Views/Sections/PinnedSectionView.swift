//
//  PinnedSectionView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/2/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI
import Grid
import SDWebImageSwiftUI
import MapKit
import Firebase

struct PinnedSectionView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var showPinDetails: String
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
                Grid(self.dialog.pinMessages.reversed(), id: \.self) { pinId in
                    if let messagez = self.dialog.messages.first(where: { $0.id == pinId }) {
                        ZStack(alignment: .bottomTrailing) {
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
                                        }
                                        .frame(width: 125, height: 98)
                                        .aspectRatio(contentMode: .fit)
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
                                } else if messagez.imageType == "video/mov" {
                                    PinnedVideoCell(videoUrl: messagez.image)
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
                            
                            Menu {
                                Text("sent on \(self.dateFormatTimeExtended(date: messagez.date))")
                                    .fontWeight(.bold)

                                Divider()

                                if let dialog = self.auth.selectedConnectyDialog, let admins = dialog.adminsIDs, (admins.contains(NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID"))) || dialog.userID == UserDefaults.standard.integer(forKey: "currentUserID")), (dialog.type == .group || dialog.type == .public) {
                                    Button(action: {
                                        self.pinMessage(message: messagez)
                                    }) {
                                        Label("Remove Pin", systemImage: "pin")
                                    }
                                }

                                Button(action: {
                                    self.showPinDetails = messagez.id
                                    self.presentationMode.wrappedValue.dismiss()
                                }) {
                                    Label("View Details", systemImage: "magnifyingglass")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16, alignment: .center)
                                    .padding(5)
                                    .foregroundColor(Color.primary)
                                    .background(
                                        Circle()
                                            .foregroundColor(Color("buttonColor_darker").opacity(0.75))
                                    )                                    
                            }.padding(5)
                            .buttonStyle(ClickButtonStyle())
                        }
                    }
                }.cornerRadius(15)
                .frame(height: self.dialog.pinMessages.count == 1 ? 98 : 200, alignment: .center)
                .padding(.leading)
                .animation(.easeInOut)
            }.shadow(color: Color.black.opacity(0.2), radius: 12.5, x: 0, y: 8)
            .padding(.bottom, 10)
            .padding(.trailing)
            .gridStyle(self.style)
        }
        .padding(.bottom)
    }
    
    func pinMessage(message: MessageStruct, completion: @escaping (Bool) -> Void) {
        guard message.dialogID != "" else { return }

        let msg = Database.database().reference().child("Dialogs").child(message.dialogID).child("pinned")

        msg.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.childSnapshot(forPath: "\(message.id)").exists() {
                msg.child("\(message.id)").removeValue()

                completion(false)
            } else {
                msg.updateChildValues(["\(message.id)" : "\(Date())"])

                completion(true)
            }
        })
    }
    
    func pinMessage(message: MessageStruct) {
        self.pinMessage(message: message, completion: { added in
            if !added {
                changeDialogRealmData.shared.removeDialogPin(messageId: message.id, dialogID: message.dialogID)
                auth.notificationtext = "Removed pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            } else {
                changeDialogRealmData.shared.addDialogPin(messageId: message.id, dialogID: message.dialogID)
                auth.notificationtext = "Successfully pined message"
                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
            }
        })
    }
    
    func dateFormatTimeExtended(date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
     
        return dateFormatter.string(from: date)
    }
}
