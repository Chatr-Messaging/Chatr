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
import Firebase

struct KeyboardCardView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var audio = VoiceViewModel()
    @ObservedObject var imagePicker: KeyboardCardViewModel
    @Binding var height: CGFloat
    @Binding var isOpen: Bool
    @State var open: Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @Binding var mainText: String
    @Binding var hasAttachments: Bool
    @Binding var showImagePicker: Bool
    @Binding var isKeyboardActionOpen: Bool
    @State var selectedContacts: [Int] = []
    @State var newDialogID: String = ""
    @State var gifData: [GIFMediaAsset] = []
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
    @State var gifRatio: CGFloat = 0.0
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
    let transition = AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.3)))
    //Share variables

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            if UserDefaults.standard.bool(forKey: "disabledMessaging") && UserDefaults.standard.string(forKey: "visitingDialogId") ?? "" == "" {
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
                
                //MARK: Text Field & Send Btn
                HStack(alignment: .bottom, spacing: 0) {
                    if !self.isRecordingAudio {
                        VStack(spacing: 0) {
                            
                            //MARK: Attachments Section
                            if self.hasAttachments {
                                ReversedScrollView(.horizontal) {
                                    HStack(spacing: 8) {
                                        //MARK: Location Section
                                        if self.enableLocation {
                                            ZStack(alignment: .topLeading) {
                                                Button(action: {
                                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                    withAnimation(.easeOut(duration: 0.25)) {
                                                        self.enableLocation = false
                                                    }
                                                }, label: {
                                                    Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode)
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 130, height: 90)
                                                        .cornerRadius(10)
                                                        .padding(.top, 10)
                                                }).buttonStyle(ClickMiniButtonStyle())
                                                .background(Color.clear)
                                                .transition(AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .top).animation(.easeOut(duration: 0.2)), removal: AnyTransition.move(edge: .top).combined(with: .opacity).animation(.easeOut(duration: 0.2))))
                                            }.onAppear() {
                                                self.region.span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
                                            }
                                        }
                                        
                                        //MARK: GIPHY Section
                                        if !self.gifData.isEmpty {
                                            HStack {
                                                ForEach(self.gifData.indices, id: \.self) { gifIndex in
                                                    ZStack(alignment: .topTrailing) {
                                                        AnimatedImage(url: URL(string: self.gifData[gifIndex].url))
                                                            .resizable()
                                                            .indicator(.activity)
                                                            .frame(width: self.gifData[gifIndex].mediaRatio * 90, height: 90)
                                                            .scaledToFit()
                                                            .background(Image(systemName: "photo.on.rectangle.angled"))
                                                            .cornerRadius(10)
                                                            .padding(.leading, 10)
                                                            .padding(.top, 10)
                                                        
                                                        Button(action: {
                                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                            self.gifData.remove(at: gifIndex)
                                                            self.checkAttachments()
                                                        }, label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 24, height: 24, alignment: .center)
                                                                .foregroundColor(.primary)
                                                                .padding(.vertical)
                                                                .padding(.trailing, 5)
                                                        }).background(Color.clear)
                                                    }.transition(.asymmetric(insertion: AnyTransition.move(edge: .top).animation(.spring()), removal: AnyTransition.move(edge: .top).combined(with: .opacity).animation(.easeOut(duration: 0.2))))
                                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                                            }
                                        }

                                        //MARK: Pasted Photo Section
                                        if !self.imagePicker.pastedImages.isEmpty {
                                            HStack {
                                                ForEach(self.imagePicker.pastedImages.indices, id: \.self) { index in
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: self.imagePicker.pastedImages[index])
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(height: 90)
                                                            .frame(minWidth: 70, maxWidth: Constants.screenWidth * 0.4)
                                                            .transition(.fade(duration: 0.05))
                                                            .cornerRadius(10)
                                                            .padding(.leading, 10)
                                                            .padding(.top, 10)

                                                        Button(action: {
                                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                            self.imagePicker.pastedImages.remove(at: index)
                                                            self.checkAttachments()
                                                        }, label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 24, height: 24, alignment: .center)
                                                                .foregroundColor(.primary)
                                                                .padding(.vertical)
                                                                .padding(.trailing, 5)
                                                        }).background(Color.clear)
                                                    }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.2))))
                                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                                            }
                                        }

                                        //MARK: Photo Section
                                        if !self.imagePicker.selectedPhotos.isEmpty {
                                            HStack {
                                                ForEach(self.imagePicker.selectedPhotos.indices, id: \.self) { img in
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: self.imagePicker.selectedPhotos[img].image)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: CGFloat(90 / (self.imagePicker.selectedPhotos[img].mediaRatio ?? 1.0)), height: 90)
                                                            .overlay(
                                                                ZStack(alignment: .center) {
                                                                    BlurView(style: .systemUltraThinMaterial).animation(.easeInOut)

                                                                    Circle()
                                                                        .trim(from: 0, to: 1)
                                                                        .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                                        .frame(width: 20, height: 20)
                                                                        .padding(4)
                                                                        .animation(.easeInOut)

                                                                    Circle()
                                                                        .trim(from: 0, to: self.imagePicker.selectedPhotos[img].progress)
                                                                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                                        .frame(width: 20, height: 20)
                                                                        .rotationEffect(.init(degrees: -90))
                                                                        .padding(4)
                                                                        .animation(.easeOut)
                                                            }.opacity(self.imagePicker.selectedPhotos[img].progress >= 1.0 || self.imagePicker.selectedPhotos[img].progress <= 0.0 ? 0 : 1)
                                                            )
                                                            .cornerRadius(14)
                                                            .padding(.leading, 10)
                                                            .padding(.top, 10)

                                                        Button(action: {
                                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                            self.imagePicker.selectedPhotos.remove(at: img)
                                                            self.checkAttachments()
                                                        }, label: {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .frame(width: 24, height: 24, alignment: .center)
                                                                .foregroundColor(.primary)
                                                                .padding(.vertical)
                                                                .padding(.trailing, 5)
                                                        }).background(Color.clear)
                                                        .opacity(self.imagePicker.selectedPhotos[img].canSend ? 0 : 1)
                                                    }.id(self.imagePicker.selectedPhotos[img].id)
                                                        .transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.2))))
                                                }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                                            }
                                        }

                                        //MARK: Video Section
                                        HStack {
                                            ForEach(self.imagePicker.selectedVideos.indices, id: \.self) { vid in
                                                ZStack(alignment: .topTrailing) {
                                                    ZStack(alignment: .bottomLeading) {
                                                        Image(uiImage: self.imagePicker.selectedVideos[vid].image)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: CGFloat(90 / (self.imagePicker.selectedVideos[vid].mediaRatio ?? 1.0)), height: 90)
                                                            .overlay(
                                                                ZStack(alignment: .center) {
                                                                    BlurView(style: .systemUltraThinMaterial).animation(.easeInOut)

                                                                    Circle()
                                                                        .trim(from: 0, to: 1)
                                                                        .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                                        .frame(width: 20, height: 20)
                                                                        .padding(4)
                                                                        .animation(.easeInOut)

                                                                    Circle()
                                                                        .trim(from: 0, to: self.imagePicker.selectedVideos[vid].progress)
                                                                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                                        .frame(width: 20, height: 20)
                                                                        .rotationEffect(.init(degrees: -90))
                                                                        .padding(4)
                                                                        .animation(.easeOut)
                                                            }.opacity(self.imagePicker.selectedVideos[vid].progress >= 1.0 || self.imagePicker.selectedVideos[vid].progress <= 0.0 ? 0 : 1)
                                                            )
                                                            .cornerRadius(14)
                                                        
                                                        HStack {
                                                            Image(systemName: "video.fill")
                                                                .font(.subheadline)
                                                                .foregroundColor(.white)

                //                                                Text("\(self.formatVideoDuration(second: self.imagePicker.selectedVideos[vid].asset?.duration ?? CMTime(seconds: 0.0, preferredTimescale: 100)))")
                //                                                    .font(.caption)
                //                                                    .fontWeight(.regular)
                //                                                    .foregroundColor(.white)
                                                        }.padding(5)
                                                        .background(BlurView(style: .systemThinMaterialDark).cornerRadius(5))
                                                        .offset(x: 5, y: -5)
                                                    }.padding(.leading, 10)
                                                    .padding(.top, 10)

                                                    Button(action: {
                                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                        self.imagePicker.selectedVideos.remove(at: vid)
                                                        self.checkAttachments()
                                                    }, label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 24, height: 24, alignment: .center)
                                                            .foregroundColor(.primary)
                                                            .padding(.vertical)
                                                            .padding(.trailing, 5)
                                                    }).background(Color.clear)
                                                    .opacity(self.imagePicker.selectedVideos[vid].canSend ? 0 : 1)
                                                }.id(self.imagePicker.selectedVideos[vid].id)
                                                .transition(transition)
                                            }.animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
                                        }
                                    }
                                    .padding(.vertical, !self.imagePicker.selectedVideos.isEmpty || !self.imagePicker.selectedPhotos.isEmpty ? 5 : 0)
                                    .padding(.horizontal)
                                }
                                .frame(height: 110)
                                .padding(.trailing, 10)
                                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 6)
                                .transition(transition)
                            }

                            HStack(alignment: .bottom, spacing: 0) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation(Animation.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0), {
                                        self.isKeyboardActionOpen.toggle()
                                    })
                                }) {
                                    Image(systemName: self.isKeyboardActionOpen ? "xmark" : "paperclip")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: self.isKeyboardActionOpen ? 18 : 25, height: self.isKeyboardActionOpen ? 18 : 25, alignment: .center)
                                        .font(Font.title.weight(.regular))
                                        .foregroundColor(.secondary)
                                        .padding(self.isKeyboardActionOpen ? 12.5 : 8)
                                }
                                .padding(.horizontal, 2)
                                .buttonStyle(changeBGPaperclipButtonStyle())
                                .cornerRadius(self.height < 160 ? 25 : 17.5)

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
                            }
                        }.background(
                            ZStack(alignment: .bottomLeading) {
                                RoundedRectangle(cornerRadius: self.height < 160 ? 25 : 17.5)
                                    .foregroundColor(Color.clear)
                                    //.opacity(0)
                                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color("lightGray"), lineWidth: 1.75))
                                    .padding(.trailing, 7.5)
                                    //.shadow(color: Color.black.opacity(self.mainText.count != 0 ? 0.1 : 0.15), radius: self.mainText.count != 0 ? 6 : 4, x: 0, y: self.mainText.count != 0 ? 6 : 2.5)

                                Text("type message")
                                    .font(.system(size: 18))
                                    .padding(.vertical, 10)
                                    .padding(.leading, 45)
                                    .foregroundColor(self.mainText.count == 0 && self.isOpen ? Color.secondary : .clear)
                            }
                        )
                    } else {
                        //Audio Recording Section
                        KeyboardAudioView(viewModel: self.audio, isRecordingAudio: self.$isRecordingAudio, hasAudioToSend: self.$hasAudioToSend)
                    }
                    
                    //MARK: Send Button
                    Button(action: {
                        guard self.contentAvailable, let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first else {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            return
                        }

                        DispatchQueue.main.async {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation {
                                self.isKeyboardActionOpen = false
                                self.showImagePicker = false
                            }
                            
                            if let connDia = self.auth.selectedConnectyDialog {
                                connDia.sendUserStoppedTyping()
                            }

                            if !self.audio.recordingsList.isEmpty {
                                self.auth.messages.sendAudioAttachment(dialog: selectedDialog, audioURL: self.audio.recordingsList.first?.fileURL ?? URL(fileURLWithPath: ""), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                self.audio.deleteAudioFile()

                                return
                            }

                            if !self.gifData.isEmpty {
                                self.auth.messages.sendGIFAttachment(dialog: selectedDialog, GIFAssets: self.gifData.reversed(), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])

                                withAnimation {
                                    self.gifData.removeAll()
                                }
                            }
                            
                            if !self.imagePicker.selectedPhotos.isEmpty || !self.imagePicker.pastedImages.isEmpty {
                                DispatchQueue.main.async {
                                    for i in self.imagePicker.selectedPhotos {
                                        self.imagePicker.sendPhotoMessage(attachment: i, auth: self.auth, completion: { self.checkAttachments() })
                                    }
                                }
                            }

                            if self.imagePicker.selectedVideos.count > 0 {
                                self.imagePicker.sendVideoMessage(auth: self.auth)
                            }
                            
                            if self.enableLocation {
                                self.auth.messages.sendLocationMessage(dialog: selectedDialog, longitude: self.region.center.longitude, latitude: self.region.center.latitude, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                self.enableLocation = false
                            }
                            
                            if self.mainText.count > 0 {
                                self.auth.messages.sendMessage(dialog: selectedDialog, text: self.mainText, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            }
                            
                            self.checkAttachments()
                            withAnimation {
                                self.mainText = ""
                                self.height = 38
                            }
                            UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                        }
                    }, label: {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 22, height: 22)
                            .foregroundColor(self.contentAvailable ? .white : .secondary)
                            .padding(10)
                            .offset(x: -1)
                            .background(self.contentAvailable ? LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color.clear, Color.clear]), startPoint: .top, endPoint: .bottom))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(self.contentAvailable ? 0.15 : 0.0), radius: 4, x: 0, y: 3)
                            .shadow(color: Color.blue.opacity(self.contentAvailable ? 0.25 : 0.0), radius: 10, x: 0, y: 6)
                            .scaleEffect(self.contentAvailable ? 1.06 : 1.0)
                            .animation(Animation.interactiveSpring())
                    }).buttonStyle(interactionSendButtonStyle())
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .onChange(of: self.contentAvailable, perform: { value in
                    guard self.hasAttachments else { return }

                    self.hasAttachments = value
                })

                //MARK: Action Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: 25) {
                        Button(action: {
                            let status = PHPhotoLibrary.authorizationStatus()

                            if status == .authorized {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.showImagePicker.toggle()
                            } else {
                                PHPhotoLibrary.requestAuthorization({ statusz in
                                    if statusz == .authorized{
                                      DispatchQueue.main.async {
                                          self.showImagePicker.toggle()
                                      }
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                })
                            }
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
                        .sheet(isPresented: self.$showImagePicker) {
                            PHAssetPickerSheet(isPresented: self.$showImagePicker, onMediaPicked: { resultsz in
                                let identifiers = resultsz.compactMap(\.assetIdentifier)
                                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

                                fetchResult.enumerateObjects { [self] (asset, index, _) in
                                    print("rannn ayyy yooooooo")
                                    self.imagePicker.extractPreviewData(asset: asset, auth: self.auth, completion: {
                                        self.checkAttachments()
                                    })
                                }
                            })
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
                            guard gifURL != "", self.gifRatio != 0.0, !self.gifData.contains(where: { $0.url == self.gifURL }) else { return }
                            print("the adding gif url is: \(gifURL.description) and ratio: \(self.gifRatio)")

                            self.gifData.append(GIFMediaAsset(url: self.gifURL, mediaRatio: self.gifRatio))
                            self.checkAttachments()
                            self.gifURL = ""
                            self.gifRatio = 0.0
                        }) {
                            GIFController(url: self.$gifURL, present: self.$presentGIF, ratio: self.$gifRatio)
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
                                        self.auth.messages.sendContactMessage(dialog: selectedDialog, contactID: self.selectedContacts, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
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

                            DispatchQueue.main.async {
                                self.imagePicker.checkLocationPermission()
                                if self.imagePicker.locationPermission {
                                    self.region.center.longitude = self.imagePicker.locationManager.location?.coordinate.longitude ?? 0
                                    self.region.center.latitude = self.imagePicker.locationManager.location?.coordinate.latitude ?? 0
                                    
                                    withAnimation {
                                        self.enableLocation.toggle()
                                    }
                                    self.checkAttachments()
                                } else {
                                    self.imagePicker.requestLocationPermission()
                                }
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
                    Request.subscribeToPublicDialog(withID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", successBlock: { dialogz in
                        self.auth.dialogs.toggleFirebaseMemberCount(dialogId: dialogz.id ?? "", isJoining: true, totalCount: Int(dialogz.occupantsCount), onSuccess: { _ in
                            self.auth.dialogs.insertDialogs([dialogz], completion: {
                                self.auth.dialogs.updateDialogDelete(isDelete: false, dialogID: dialogz.id ?? "")
                                self.auth.dialogs.addPublicMemberCountRealmDialog(count: Int(dialogz.occupantsCount), dialogId: dialogz.id ?? "")
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation {
                                    self.isVisiting = ""
                                }
                                UserDefaults.standard.set("", forKey: "visitingDialogId")
                                self.auth.notificationtext = "Joined channel"
                                NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                            })
                        }, onError: { err in
                            print("there is an error visiting the member count: \(String(describing: err))")
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
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
        .cornerRadius(25)
        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color("blurBorder"), lineWidth: 2.5))
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if value {
                    observePublicMembersType()
                    checkAttachments()
                    if let typedText = UserDefaults.standard.string(forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText") {
                        self.mainText = typedText
                    } else { self.mainText = "" }
                } else {
                    UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                    UserDefaults.standard.set(false, forKey: "disabledMessaging")
                    self.mainText = ""
                }
            }
        })
        .onAppear() {
            UserDefaults.standard.set(false, forKey: "disabledMessaging")
            observePublicMembersType()
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
        withAnimation {
            self.hasAttachments = !self.imagePicker.selectedPhotos.isEmpty || !self.imagePicker.selectedVideos.isEmpty || !self.gifData.isEmpty || self.enableLocation || !self.imagePicker.pastedImages.isEmpty
        }
    }
    
    func formatVideoDuration(second: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: second) ?? "0:00"
    }
    
    func observePublicMembersType() {
        guard let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first, selectedDialog.dialogType == "public", !selectedDialog.adminID.contains(where: { $0 == UserDefaults.standard.integer(forKey: "currentUserID") }), selectedDialog.owner != UserDefaults.standard.integer(forKey: "currentUserID") else {
            self.auth.dialogs.updateDialogMembersType(canType: false, dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
            UserDefaults.standard.set(false, forKey: "disabledMessaging")

            return
        }
        
        let dia = Database.database().reference().child("Marketplace/public_dialogs").child(selectedDialog.id)
        
        dia.observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
            if let dict = snapshot.value as? [String: Any] {
                self.auth.dialogs.updateDialogMembersType(canType: dict["canMembersType"] as? Bool ?? false, dialogID: selectedDialog.id)
                UserDefaults.standard.set(!(dict["canMembersType"] as? Bool ?? false), forKey: "disabledMessaging")
            }
        })
    }
        
}

//MARK: Message Text Field
struct ResizableTextField : UIViewRepresentable {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var imagePicker: KeyboardCardViewModel
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
                        if let dia = self.parent.auth.selectedConnectyDialog {
                            if dia.isJoined() {
                                dia.sendUserStoppedTyping()
                            } else {
                                dia.sendUserStoppedTypingWithoutJoin()
                            }
                        }
                            
                    } else if !self.hasTyped {
                        self.hasTyped = true
                        
                        if let dia = self.parent.auth.selectedConnectyDialog {
                            if dia.isJoined() {
                                dia.sendUserIsTyping()
                            } else {
                                dia.sendUserIsTypingWithoutJoin()
                            }
                        }
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
            guard self.parent.isMessageView ?? true else {
                    return true
                }

                let pasteboard = UIPasteboard.general

                guard pasteboard.hasImages, text == pasteboard.string, let images = pasteboard.images else {
                    return true
                }

                for image in images {
                    withAnimation {
                        let newMedia = KeyboardMediaAsset(image: image)
                        self.parent.imagePicker.selectedPhotos.append(newMedia)
                        self.parent.imagePicker.imageData.append(image)
                        self.parent.imagePicker.uploadSelectedImage(media: newMedia, auth: self.parent.auth)
                    }
                }

                return false
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
//                if photo.asset.mediaType == .video {
//                    HStack {
//                        Image(systemName: "video.fill")
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//
//                        Text("\(self.formatVideoDuration(second: photo.asset.duration))")
//                            .font(.caption)
//                            .fontWeight(.regular)
//                            .foregroundColor(.white)
//                    }.padding(5)
//                    .background(BlurView(style: .systemThinMaterialDark).cornerRadius(5))
//                }
                
                Spacer()
//
//                Image(systemName: photo.selected ? "checkmark.circle.fill" : "circle")
//                    .resizable()
//                    .scaledToFit()
//                    .font(Font.title.weight(.medium))
//                    .foregroundColor(photo.selected ? .blue : .white)
//                    .frame(width: 22, height: 22, alignment: .center)
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
