//
//  KeyboardCard.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/2/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Photos
import MapKit
import UIKit
import RealmSwift
import ConnectyCube
import SDWebImageSwiftUI
import AVKit

struct KeyboardCardView: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var imagePicker = KeyboardCardViewModel()
    @ObservedObject var audio = VoiceViewModel()
    @Binding var height: CGFloat
    @Binding var isOpen: Bool
    @State var open: Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @Binding var mainText: String
    @Binding var hasAttachments: Bool
    @Binding var showImagePicker: Bool
    @Binding var isKeyboardActionOpen: Bool
    @State var selectedContacts: [Int] = []
    @State var newDialogID: String = ""
    @State var gifData: [String] = []
    @State var photoData: [UIImage] = []
    @State var videoData: [AVAsset] = []
    @State var enableLocation: Bool = false
    @State var presentGIF: Bool = false
    @State var shareContact: Bool = false
    @State var isRecordingAudio: Bool = false
    @State var hasAudioToSend: Bool = false
    //@State var isMoreOpen: Bool = false
    @State var isShareChannelOpen: Bool = false
    @State var isVisiting: String = UserDefaults.standard.string(forKey: "visitingDialogId") ?? ""
    @State var gifURL: String = ""
    @State private var inputImage: UIImage? = nil
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    let keyboard = KeyboardObserver()
    var contentAvailable: Bool {
        if self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation || self.imagePicker.pastedImages.count > 0 || (self.hasAudioToSend && self.isRecordingAudio) {
            return true
        } else {
            return false
        }
    }
    let transition = AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2)))
    //Share variables

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if UserDefaults.standard.bool(forKey: "disabledMessaging") {
                HStack(spacing: 5) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.isShareChannelOpen.toggle()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16, alignment: .center)
                                .foregroundColor(.blue)
                            
                            Text("Share Channel")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.blue)
                        }.frame(width: Constants.screenWidth * 0.60 - 86, height: 36, alignment: .center)
                        .background(Color("buttonColor"))
                        .cornerRadius(8)
                    }.buttonStyle(ClickButtonStyle())
                    .padding(.bottom, 4)
                    .sheet(isPresented: self.$isShareChannelOpen, onDismiss: {
                        print("printz dismiss share dia")
                    }) {
                        NavigationView() {
                            ShareProfileView(dimissView: self.$isShareChannelOpen, contactID: 0, dialogID: self.auth.selectedConnectyDialog?.id, contactFullName: self.auth.selectedConnectyDialog?.name ?? "", contactAvatar: self.auth.selectedConnectyDialog?.photo ?? "", isPublicDialog: true, totalMembers: 0).environmentObject(self.auth)
                                .navigationTitle("Share Channel")
                                .navigationBarItems(leading:
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                withAnimation {
                                                    self.isShareChannelOpen.toggle()
                                                }
                                            }) {
                                                Text("Done")
                                                    .foregroundColor(.primary)
                                                    .fontWeight(.medium)
                                            })
                        }
                    }

//                    Button(action: {
//                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
//                        self.isMoreOpen.toggle()
//                    }) {
//                        ZStack {
//                            Image(systemName: "ellipsis")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 16, height: 16, alignment: .center)
//                                .foregroundColor(.primary)
//                        }.frame(width: 36, height: 36, alignment: .center)
//                        .background(Color("buttonColor"))
//                        .cornerRadius(8)
//                        //.overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.45), lineWidth: 1))
//                    }.buttonStyle(ClickButtonStyle())
//                    .padding(.bottom, 4)
//                    .actionSheet(isPresented: $isMoreOpen) {
//                        ActionSheet(title: Text("Options:"), message: nil, buttons: [
//                                .default(Text("View Details")) {
//                                },
//                                .cancel()
//                            ])
//                    }
                }.padding(.top, 10)
            } else if self.isVisiting.isEmpty {
                //MARK: Attachments Section
                ScrollView(.horizontal, showsIndicators: false, content: {
                    HStack(spacing: 8) {
                        //MARK: Location Section
                        if self.enableLocation {
                            ZStack(alignment: .topLeading) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation {
                                        self.enableLocation = false
                                        self.checkAttachments()
                                    }
                                }, label: {
                                    Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode)
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 130, height: 90)
                                        .cornerRadius(10)
                                }).buttonStyle(ClickMiniButtonStyle())
                                .background(Color.clear)
                                .transition(AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2)), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                            }.onAppear() {
                                self.region.span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
                            }
                        }
                        
                        //MARK: GIPHY Section
                        if !self.gifData.isEmpty {
                            HStack {
                                ForEach(self.gifData.indices, id: \.self) { url in
                                    ZStack(alignment: .topLeading) {
                                        AnimatedImage(url: URL(string: self.gifData[url]))
                                            .resizable()
                                            .placeholder{ Image(systemName: "photo.on.rectangle.angled") }
                                            .indicator(.activity)
                                            .scaledToFill()
                                            .frame(height: 90)
                                            .frame(minWidth: 65, maxWidth: Constants.screenWidth * 0.4)
                                            .cornerRadius(10)
                                            .padding(.leading, 10)
                                            .padding(.top, 10)
                                        
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            withAnimation {
                                                self.gifData.remove(at: url)
                                                self.checkAttachments()
                                            }
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24, alignment: .center)
                                                .foregroundColor(.primary)
                                        }).background(Color.clear)
                                    }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                            }
                        }

                        //MARK: Pasted Photo Section
                        if !self.imagePicker.pastedImages.isEmpty {
                            HStack {
                                ForEach(self.imagePicker.pastedImages.indices, id: \.self) { index in
                                    ZStack(alignment: .topLeading) {
                                        Image(uiImage: self.imagePicker.pastedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 90)
                                            .frame(minWidth: 70, maxWidth: Constants.screenWidth * 0.4)
                                            .transition(.fade(duration: 0.05))
                                            .cornerRadius(10)
                                            .padding(.leading, 10)
                                            .padding(.top, 10)
                                            .onAppear {
                                                self.checkAttachments()
                                            }

                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            withAnimation {
                                                self.imagePicker.pastedImages.remove(at: index)
                                                self.checkAttachments()
                                            }
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24, alignment: .center)
                                                .foregroundColor(.primary)
                                        }).background(Color.clear)
                                    }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                            }
                        }

                        //MARK: Photo Section
                        if !self.imagePicker.selectedPhotos.isEmpty {
                            HStack {
                                ForEach(self.imagePicker.selectedPhotos.indices, id: \.self) { img in
                                    ZStack(alignment: .topLeading) {
                                        Image(uiImage: self.imagePicker.selectedPhotos[img].image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 90)
                                            .frame(minWidth: 70, maxWidth: Constants.screenWidth * 0.4)
                                            .cornerRadius(10)
                                            .padding(.leading, 10)
                                            .padding(.top, 10)

                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            if let deselectIndex = self.imagePicker.fetchedPhotos.firstIndex(where: { $0.asset == self.imagePicker.selectedPhotos[img].asset }) {
                                                self.imagePicker.fetchedPhotos[deselectIndex].selected = false
                                            }
                                            withAnimation {
                                                self.imagePicker.selectedPhotos.remove(at: img)
                                                self.checkAttachments()
                                            }
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24, alignment: .center)
                                                .foregroundColor(.primary)
                                        }).background(Color.clear)
                                    }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                            }
                        }

                        //MARK: Video Section
                        if !self.imagePicker.selectedVideos.isEmpty {
                            HStack {
                                ForEach(self.imagePicker.selectedVideos.indices, id: \.self) { vid in
                                    ZStack(alignment: .topLeading) {
                                        ZStack(alignment: .bottomLeading) {
                                            Image(uiImage: self.imagePicker.selectedVideos[vid].image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 90)
                                                .frame(minWidth: 85, maxWidth: Constants.screenWidth * 0.4)
                                                .cornerRadius(10)
                                            
                                            HStack {
                                                Image(systemName: "video.fill")
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)

                                                Text("\(self.formatVideoDuration(second: self.imagePicker.selectedVideos[vid].asset.duration))")
                                                    .font(.caption)
                                                    .fontWeight(.regular)
                                                    .foregroundColor(.white)
                                            }.padding(5)
                                            .background(BlurView(style: .systemThinMaterialDark).cornerRadius(5))
                                            .offset(x: 5, y: -5)
                                        }.padding(.leading, 10)
                                        .padding(.top, 10)

                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            if let deselectIndex = self.imagePicker.fetchedPhotos.firstIndex(where: { $0.asset == self.imagePicker.selectedVideos[vid].asset }) {
                                                self.imagePicker.fetchedPhotos[deselectIndex].selected = false
                                            }
                                            withAnimation {
                                                self.imagePicker.selectedVideos.remove(at: vid)
                                                self.checkAttachments()
                                            }
                                        }, label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24, alignment: .center)
                                                .foregroundColor(.primary)
                                        }).background(Color.clear)
                                    }.transition(transition)
                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                            }
                        }
                    }.padding(.vertical, self.hasAttachments ? 5 : 0)
                    .padding(.horizontal)
                }).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                .transition(transition)
                
                //MARK: Text Field & Send Btn
                HStack(alignment: .bottom, spacing: 0) {
                    if !self.isRecordingAudio {
                        HStack(alignment: .bottom, spacing: 0) {
                            Button(action: {
                                withAnimation(Animation.interactiveSpring(), {
                                    self.isKeyboardActionOpen.toggle()
                                })
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }) {
                                Image(systemName: self.isKeyboardActionOpen ? "xmark" : "paperclip")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: self.isKeyboardActionOpen ? 16 : 25, height: self.isKeyboardActionOpen ? 18 : 25, alignment: .center)
                                    .font(Font.title.weight(.regular))
                                    .foregroundColor(.secondary)
                                    .padding(self.isKeyboardActionOpen ? 12.5 : 8)
                                    .padding(.horizontal, 2)
                            }.buttonStyle(changeBGPaperclipButtonStyle())
                            .cornerRadius(self.height < 160 ? 12.5 : 17.5)

                            ResizableTextField(imagePicker: self.imagePicker, height: self.$height, text: self.$mainText)
                                .environmentObject(self.auth)
                                .frame(height: self.height < 175 ? self.height : 175)
                                .padding(.trailing, 7.5)
                                .offset(x: -5, y: -1)

                            if self.mainText.count == 0 && !self.enableLocation && self.gifData.isEmpty && self.imagePicker.pastedImages.isEmpty && self.imagePicker.selectedVideos.isEmpty && self.imagePicker.selectedPhotos.isEmpty {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation(Animation.easeInOut(duration: 0.25)) {
                                        self.isKeyboardActionOpen = false
                                        self.isRecordingAudio = true
                                    }
                                }) {
                                    Image(systemName: "mic.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 22.5, alignment: .center)
                                        .font(Font.title.weight(.regular))
                                        .foregroundColor(.secondary)
                                        .padding(10)
                                        .padding(.horizontal, 2.5)
                                }
                                .buttonStyle(changeBGPaperclipButtonStyle())
                                .cornerRadius(12.5)
                                .padding(.trailing, 6.5)
                            }
                        }.background(
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: self.height < 160 ? 12.5 : 17.5)
                                    .foregroundColor(Color("buttonColor"))
                                    .padding(.trailing, 7.5)
                                    .shadow(color: Color.black.opacity(self.mainText.count != 0 ? 0.1 : 0.15), radius: self.mainText.count != 0 ? 6 : 4, x: 0, y: self.mainText.count != 0 ? 6 : 2.5)

                                Text("type message")
                                    .font(.system(size: 18))
                                    .padding(.vertical, 10)
                                    .padding(.leading, 45)
                                    .foregroundColor(self.mainText.count == 0 && self.isOpen ? Color("lightGray") : .clear)
                            }
                        )
                    } else {
                        //Audio Recording Section
                        KeyboardAudioView(viewModel: self.audio, isRecordingAudio: self.$isRecordingAudio, hasAudioToSend: self.$hasAudioToSend)
                    }
                    
                    //MARK: Send Button
                    Button(action: {
                        guard self.contentAvailable else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            return
                        }

                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.isKeyboardActionOpen = false
                        self.showImagePicker = false

                        if let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                            if let connDia = self.auth.selectedConnectyDialog {
                                connDia.sendUserStoppedTyping()
                            }

                            if !self.audio.recordingsList.isEmpty {
                                changeMessageRealmData.shared.sendAudioAttachment(dialog: selectedDialog, audioURL: self.audio.recordingsList.first?.fileURL ?? URL(fileURLWithPath: ""), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                self.audio.deleteAudioFile()

                                return
                            }

                            if self.gifData.count > 0 {
                                changeMessageRealmData.shared.sendGIFAttachment(dialog: selectedDialog, attachmentStrings: self.gifData.reversed(), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])

                                withAnimation {
                                    self.gifData.removeAll()
                                }
                            }
                            
                            if self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.pastedImages.count > 0 {
                                var uploadImg: [UIImage] = []
                                
                                for i in self.imagePicker.selectedPhotos {
                                    uploadImg.append(i.image)
                                }

                                for pastedImage in self.imagePicker.pastedImages {
                                    uploadImg.append(pastedImage)
                                }
                                
                                changeMessageRealmData.shared.sendPhotoAttachment(dialog: selectedDialog, attachmentImages: uploadImg, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            
                                uploadImg.removeAll()
                                withAnimation {
                                    self.imagePicker.selectedPhotos.removeAll()
                                    self.imagePicker.pastedImages.removeAll()
                                }
                            }

                            if self.imagePicker.selectedVideos.count > 0 {
                                var uploadVid: [PHAsset] = []

                                for i in self.imagePicker.selectedVideos {
                                    uploadVid.append(i.asset)
                                }

                                changeMessageRealmData.shared.sendVideoAttachment(dialog: selectedDialog, attachmentVideos: uploadVid, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                
                                uploadVid.removeAll()
                                withAnimation {
                                    self.imagePicker.selectedVideos.removeAll()
                                }
                            }
                            
                            if self.enableLocation {
                                changeMessageRealmData.shared.sendLocationMessage(dialog: selectedDialog, longitude: self.region.center.longitude, latitude: self.region.center.latitude, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                self.enableLocation = false
                            }
                            
                            if self.mainText.count > 0 {
                                changeMessageRealmData.shared.sendMessage(dialog: selectedDialog, text: self.mainText, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            }

                            withAnimation {
                                self.checkAttachments()
                            }
                        }

                        self.mainText = ""
                        self.height = 38
                        UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                    }, label: {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(self.contentAvailable ? .white : .secondary)
                            .padding(10)
                            .background(self.contentAvailable ? LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor")]), startPoint: .top, endPoint: .bottom))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(self.contentAvailable ? 0.15 : 0.1), radius: 4, x: 0, y: 3)
                            .shadow(color: Color.blue.opacity(self.contentAvailable ? 0.25 : 0.0), radius: 10, x: 0, y: 6)
                            .scaleEffect(self.contentAvailable ? 1.06 : 1.0)
                            .animation(Animation.interactiveSpring())
                    }).buttonStyle(interactionSendButtonStyle())
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)

                //MARK: Action Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 25) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.showImagePicker.toggle()
                        }, label: {
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 24)
                                .foregroundColor(showImagePicker ? .blue : .primary)
                                .font(Font.title.weight(.medium))
                                .padding(.horizontal, 25)
                                .padding(.vertical)
                        }).frame(width: Constants.screenWidth / 5.5, height: 65)
                        .buttonStyle(keyboardButtonStyle())
                        .padding(.leading)
                        .sheet(isPresented: self.$showImagePicker, onDismiss: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33) {
                                self.checkAttachments()
                            }
                        }) {
                            PHAssetPickerSheet(isPresented: self.$showImagePicker, hasAttachments: self.$hasAttachments, imagePicker: self.imagePicker)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.presentGIF.toggle()
                        }, label: {
                            Text("GIF")
                                .fontWeight(.bold)
                                .frame(width: 28, height: 24)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 25)
                                .padding(.vertical)
                        }).frame(width: Constants.screenWidth / 5.5, height: 65)
                        .buttonStyle(keyboardButtonStyle())
                        .sheet(isPresented: self.$presentGIF, onDismiss: {
                            guard gifURL != "", !self.gifData.contains(self.gifURL) else { return }

                            self.gifData.append(gifURL)
                            self.checkAttachments()
                        }) {
                            GIFController(url: self.$gifURL, present: self.$presentGIF)
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.shareContact.toggle()
                        }, label: {
                            Image(systemName: "person.2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 24)
                                .foregroundColor(.primary)
                                .font(Font.title.weight(.bold))
                                .padding(.horizontal, 25)
                                .padding(.vertical)
                        }).frame(width: Constants.screenWidth / 5.5, height: 65)
                        .buttonStyle(keyboardButtonStyle())
                        .sheet(isPresented: self.$shareContact, onDismiss: {
                            if self.selectedContacts.count > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    if let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                                        changeMessageRealmData.shared.sendContactMessage(dialog: selectedDialog, contactID: self.selectedContacts, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                        withAnimation {
                                            self.selectedContacts.removeAll()
                                            self.isKeyboardActionOpen = false
                                        }
                                    }
                                }
                            }
                        }) {
                            NewConversationView(usedAsNew: false, forwardContact: true, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                        }

                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation {
                                self.hasAttachments.toggle()
                                self.enableLocation.toggle()
                                self.checkAttachments()
                            }

                            self.imagePicker.checkLocationPermission()
                            if self.imagePicker.locationPermission {
                                self.region.center.longitude = self.imagePicker.locationManager.location?.coordinate.longitude ?? 0
                                self.region.center.latitude = self.imagePicker.locationManager.location?.coordinate.latitude ?? 0
                            } else {
                                self.imagePicker.requestLocationPermission()
                            }
                        }, label: {
                            Image(systemName: self.enableLocation ? "location.fill" : "location")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 24)
                                .foregroundColor(self.enableLocation ? .blue : .primary)
                                .font(Font.title.weight(.medium))
                                .padding(.horizontal, 24)
                                .padding(.vertical)
                        }).frame(width: Constants.screenWidth / 5.5, height: 65)
                        .buttonStyle(keyboardButtonStyle())
                        .padding(.trailing)
                    }.padding(.vertical, 15)
                }.shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
                
                /*
                //MARK: Image & Video Asset Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 5) {
                        ForEach(imagePicker.fetchedPhotos.indices, id: \.self) { photo in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                imagePicker.extractPreviewData(asset: self.imagePicker.fetchedPhotos[photo].asset, completion: {
                                    if self.imagePicker.fetchedPhotos[photo].selected {
                                        if self.imagePicker.fetchedPhotos[photo].asset.mediaType == .video {
                                            
                                            //Video Section:
                                            for i in self.imagePicker.selectedVideos {
                                                if i.asset == self.imagePicker.fetchedPhotos[photo].asset {
                                                    self.imagePicker.selectedVideos.removeAll(where: { $0 == i })
                                                    self.imagePicker.fetchedPhotos[photo].selected.toggle()
                                                    self.checkAttachments()
                                                    
                                                    break
                                                }
                                                
                                                if self.imagePicker.selectedVideos.last == i && self.imagePicker.fetchedPhotos[photo].selected {
                                                    self.imagePicker.fetchedPhotos[photo].selected = false
                                                }
                                            }
                                        } else if self.imagePicker.fetchedPhotos[photo].asset.mediaType == .image {
                                            
                                            //Photos Section:
                                            for i in self.imagePicker.selectedPhotos {
                                                if i.asset == self.imagePicker.fetchedPhotos[photo].asset {
                                                    self.imagePicker.selectedPhotos.removeAll(where: { $0 == i })
                                                    self.imagePicker.fetchedPhotos[photo].selected.toggle()
                                                    self.checkAttachments()
                                                    
                                                    break
                                                }
                                                
                                                if self.imagePicker.selectedPhotos.last == i && self.imagePicker.fetchedPhotos[photo].selected {
                                                    self.imagePicker.fetchedPhotos[photo].selected = false
                                                }
                                            }
                                        }
                                    } else {
                                        if self.imagePicker.fetchedPhotos[photo].asset.mediaType == .video {
                                            self.imagePicker.selectedVideos.append(self.imagePicker.fetchedPhotos[photo])
                                        } else if self.imagePicker.fetchedPhotos[photo].asset.mediaType == .image {
                                            self.imagePicker.selectedPhotos.append(self.imagePicker.fetchedPhotos[photo])
                                        }

                                        self.imagePicker.fetchedPhotos[photo].selected.toggle()
                                    }
                                    
                                    self.checkAttachments()
                                    if self.hasAttachments && self.showImagePicker {
                                        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                                    }
                                })
                            }, label: {
                                ThumbnailView(photo: self.imagePicker.fetchedPhotos[photo])
                            }).buttonStyle(ClickMiniButtonStyle())
                        }
                        
                        // More Or Give Access Button...
                        if imagePicker.library_status == .denied || imagePicker.library_status == .limited {
                            VStack(spacing: 15) {
                                Text(imagePicker.library_status == .denied ? "Allow Access For Photos" : "Select More Photos" )
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                                }, label: {
                                    Text(imagePicker.library_status == .denied ? "Allow Access" : "Select More")
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                })
                            }.frame(width: 175)
                        }
                    }.padding()
                }.frame(height: showImagePicker ? 200 : 0)
                .background(Color.clear)
                .opacity(showImagePicker ? 1 : 0)
                */
            } else {
                Button(action: {
                    print("join ehhh")
                    withAnimation {
                        self.isVisiting = ""
                    }
                    UserDefaults.standard.set("", forKey: "visitingDialogId")
                }, label: {
                    Text("Join Channel")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.blue)
                        .frame(width: 140, height: 30, alignment: .center)
                        .background(Color("buttonColor_darker").opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 10)
                })
            }

            Spacer()
        }.frame(width: Constants.screenWidth)
        .background(BlurView(style: .systemUltraThinMaterial)) //Color("bgColor")
        .cornerRadius(22)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color("blurBorder"), lineWidth: 2.5))
        .padding(.vertical, 2.5)
        .onChange(of: UserDefaults.standard.string(forKey: "visitingDialogId"), perform: { value in
            if value == "" {
                withAnimation {
                    self.isVisiting = ""
                }
            } else {
                withAnimation {
                    self.isVisiting = value ?? ""
                }
            }
        })
        .onChange(of: UserDefaults.standard.bool(forKey: "localOpen"), perform: { value in
            if value {
                if let typedText = UserDefaults.standard.string(forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText") {
                    self.mainText = typedText
                } else { self.mainText = "" }
            } else {
                UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
            }
        })
        .onAppear() {
            keyboard.observe { (event) in
                switch event.type {
                case .willShow:
                    if self.hasAttachments && self.showImagePicker {
                        UIView.animate(withDuration: event.duration, delay: 0.0, options: [event.options], animations: {
                            self.showImagePicker = false
                        }, completion: nil)
                    }
                    
                case .willHide:
                    guard presentGIF, showImagePicker else { return }
                    self.isKeyboardActionOpen = false

                default:
                    break
                }
            }
        }
    }
    
    func checkAttachments() {
        self.hasAttachments = self.imagePicker.selectedPhotos.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation || self.imagePicker.pastedImages.count > 0
    }
    
    func formatVideoDuration(second: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: second) ?? "0:00"
    }
}

//MARK: Message Text Field
struct ResizableTextField : UIViewRepresentable {
    @EnvironmentObject var auth: AuthModel
    @StateObject var imagePicker: KeyboardCardViewModel
    @Binding var height: CGFloat
    @Binding var text: String
    var isMessageView: Bool?
    
    func makeCoordinator() -> Coordinator {
        return ResizableTextField.Coordinator(parent1: self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = true
        view.isScrollEnabled = true
        view.text = self.text
        view.keyboardDismissMode = .interactive
        view.font = .systemFont(ofSize: 18)
        view.textColor = UIColor(named: "textColor")
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            self.height = uiView.contentSize.height
        }
        uiView.text = self.text
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent : ResizableTextField
        var hasTyped: Bool = false
        
        init(parent1: ResizableTextField) {
            parent = parent1
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.hasTyped = false
                if self.parent.text == "" {
                    textView.text = nil
                }
                
                if self.parent.isMessageView ?? true {
                    if textView.text.count != 0 {
                        self.parent.auth.selectedConnectyDialog?.sendUserIsTyping()
                    }
                }
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if self.parent.isMessageView ?? true {
                self.parent.auth.selectedConnectyDialog?.sendUserStoppedTyping()

                if self.parent.isMessageView ?? false {
                    UserDefaults.standard.setValue(textView.text, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                }
            }
        }
                        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                if self.parent.isMessageView ?? true {
                    if textView.text.count == 0 {
                        self.hasTyped = false
                        self.parent.auth.selectedConnectyDialog?.sendUserStoppedTyping()
                    } else if !self.hasTyped {
                        self.hasTyped = true
                        self.parent.auth.selectedConnectyDialog?.sendUserIsTyping()
                    }
                }

                self.parent.text = textView.text
                self.parent.height = textView.contentSize.height
                if self.parent.text == "" {
                    textView.text = nil
                }
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if self.parent.isMessageView ?? true {
                let pasteboard = UIPasteboard.general
                
                if text == pasteboard.string && pasteboard.hasImages {
                    if let images = pasteboard.images {
                        for image in images {
                            withAnimation {
                                self.parent.imagePicker.pastedImages.append(image)
                            }
                        }
                    }
                    
                    return false
                }

                return true
            } else {
                return true
            }
        }
    }
}

struct ThumbnailView: View {
    var photo: KeyboardMediaAsset
    
    var body: some View{
        ZStack(alignment: .bottom, content: {
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .frame(minWidth: 105, maxWidth: Constants.screenWidth * 0.8)
                .cornerRadius(10)
            
            HStack {
                if photo.asset.mediaType == .video {
                    HStack {
                        Image(systemName: "video.fill")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("\(self.formatVideoDuration(second: photo.asset.duration))")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.white)
                    }.padding(5)
                    .background(BlurView(style: .systemThinMaterialDark).cornerRadius(5))
                }
                
                Spacer()
                
                Image(systemName: photo.selected ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .scaledToFit()
                    .font(Font.title.weight(.medium))
                    .foregroundColor(photo.selected ? .blue : .white)
                    .frame(width: 22, height: 22, alignment: .center)
            }.padding(.horizontal, 10)
            .padding(.bottom, 5)
        })
    }
    
    func formatVideoDuration(second: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: second) ?? "0:00"
    }
}
