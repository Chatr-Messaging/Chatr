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
import SDWebImageSwiftUI
import AVKit

struct KeyboardCardView: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var imagePicker = KeyboardCardViewModel()
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
    @State var gifURL: String = ""
    @State private var inputImage: UIImage? = nil
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918), span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    var contentAvailable: Bool {
        if self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation || self.imagePicker.pastedImages.count > 0 {
            return true
        } else {
            return false
        }
    }
    let transition = AnyTransition.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2)))

    var body: some View {
        VStack(spacing: 0) {

            //MARK: Attachments Section
            ScrollView(.horizontal, showsIndicators: false, content: {
                HStack(spacing: 8) {
                    //MARK: Location Section
                    if self.enableLocation {
                        ZStack(alignment: .topLeading) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.enableLocation = false
                                self.checkAttachments()
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
                                        self.gifData.remove(at: url)
                                        self.checkAttachments()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24, alignment: .center)
                                            .foregroundColor(.primary)
                                    }).background(Color.clear)
                                }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                            }
                        }.onChange(of: self.gifURL, perform: { giphyURL in
                            self.gifData.append(giphyURL)
                            self.checkAttachments()
                        })
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
                                        self.imagePicker.pastedImages.remove(at: index)
                                        self.checkAttachments()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24, alignment: .center)
                                            .foregroundColor(.primary)
                                    }).background(Color.clear)
                                }.transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).animation(.spring()), removal: AnyTransition.move(edge: .bottom).animation(.easeOut(duration: 0.2))))
                            }
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
                                        self.imagePicker.selectedPhotos.remove(at: img)
                                        self.checkAttachments()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24, alignment: .center)
                                            .foregroundColor(.primary)
                                    }).background(Color.clear)
                                }.transition(transition)
                            }
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
                                            .frame(minWidth: 100, maxWidth: Constants.screenWidth * 0.4)
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
                                        self.imagePicker.selectedVideos.remove(at: vid)
                                        self.checkAttachments()
                                    }, label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24, alignment: .center)
                                            .foregroundColor(.primary)
                                    }).background(Color.clear)
                                }.transition(transition)
                            }
                        }
                    }
                }.padding(.vertical, self.hasAttachments ? 5 : 0)
                .padding(.horizontal)
                .animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
            }).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
            .transition(transition)
            
            //MARK: Text Field & Send Btn
            HStack(alignment: .bottom, spacing: 0) {
                HStack(alignment: .bottom, spacing: 0) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        withAnimation(Animation.linear(duration: 0.2), {
                            self.isKeyboardActionOpen.toggle()
                            if self.showImagePicker == true { self.showImagePicker = false }
                        })
                    }) {
                        HStack(spacing: 0) {
                            Image(systemName: self.isKeyboardActionOpen ? "xmark" : "paperclip")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: self.isKeyboardActionOpen ? 18 : 25, height: self.isKeyboardActionOpen ? 18 : 25, alignment: .center)
                                .font(Font.title.weight(.medium))
                                .foregroundColor(.secondary)
                                .padding(self.isKeyboardActionOpen ? 11.5 : 8)

                            Divider().frame(height: 25)
                        }
                    }.buttonStyle(changeBGPaperclipButtonStyle())
                    .cornerRadius(self.height < 160 ? 12.5 : 17.5)
                    .padding(.trailing, 5)

                    ResizableTextField(imagePicker: self.imagePicker, height: self.$height, text: self.$mainText)
                        .environmentObject(self.auth)
                        .padding(.vertical, 2)
                        .frame(height: self.height < 175 ? self.height : 175)
                        .onChange(of: self.isOpen, perform: { value in
                            if value {
                                if let typedText = UserDefaults.standard.string(forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText") {
                                    self.mainText = typedText
                                } else { self.mainText = "" }
                            } else {
                                UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                            }
                        })
                }.background(
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: self.height < 160 ? 12.5 : 17.5)
                            .foregroundColor(Color("buttonColor"))
                            .padding(.trailing, 8)
                            .shadow(color: Color.black.opacity(self.mainText.count != 0 ? 0.1 : 0.15), radius: self.mainText.count != 0 ? 6 : 4, x: 0, y: self.mainText.count != 0 ? 6 : 2.5)

                        Text("type message")
                            .font(.system(size: 18))
                            .padding(.vertical, 10)
                            .padding(.leading, 52)
                            .foregroundColor(self.mainText.count == 0 && self.isOpen ? Color("lightGray") : .clear)
                    }
                )
                
                //MARK: Send Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.isKeyboardActionOpen = false

                    if let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                        if let connDia = self.auth.selectedConnectyDialog {
                            connDia.sendUserStoppedTyping()
                        }

                        if self.gifData.count > 0 {
                            changeMessageRealmData.shared.sendGIFAttachment(dialog: selectedDialog, attachmentStrings: self.gifData.reversed(), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                        
                            self.gifData.removeAll()
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
                            self.imagePicker.selectedPhotos.removeAll()
                            self.imagePicker.pastedImages.removeAll()
                        }

                        if self.imagePicker.selectedVideos.count > 0 {
                            //COME BACK AND ADD THE UPLOADING VIDEOS SECTION
                            //changeMessageRealmData.shared.sendPhotoAttachment(dialog: selectedDialog, attachmentImages: self.photoData, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            print("There are selected videos we will remove later...")
                        }
                        
                        if self.enableLocation {
                            changeMessageRealmData.shared.sendLocationMessage(dialog: selectedDialog, longitude: self.region.center.longitude, latitude: self.region.center.latitude, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            self.enableLocation = false
                        }
                        
                        if self.mainText.count > 0 {
                            changeMessageRealmData.shared.sendMessage(dialog: selectedDialog, text: self.mainText, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                        }

                        self.checkAttachments()
                    }

                    self.mainText = ""
                    self.height = 0
                    UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                }, label: {
                    Image(systemName: "paperplane.fill")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(self.contentAvailable ? .white : .secondary)
                        .padding(10)
                }).background(self.contentAvailable ? LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor")]), startPoint: .top, endPoint: .bottom))
                .overlay(Circle().strokeBorder(Color("interactionBtnBorderUnselected").opacity(0.5), lineWidth: 1.5))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(self.contentAvailable  ? 0.2 : 0.1), radius: 4, x: 0, y: 3)
                .shadow(color: Color.blue.opacity(self.contentAvailable ? 0.3 : 0.0), radius: 8, x: 0, y: 6)
                .scaleEffect(self.contentAvailable ? 1.04 : 1.0)
                .disabled(self.contentAvailable ? false : true)
            }.padding(.horizontal)
            .padding(.top, 10)

            //MARK: Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 25) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.imagePicker.openImagePicker(completion: {
                            self.showImagePicker.toggle()
                        })
                        self.checkAttachments()
                        if self.hasAttachments && self.showImagePicker {
                            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
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
                    .padding(.leading)
                    .buttonStyle(keyboardButtonStyle())
                    
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
                                }
                            }
                        }
                    }) {
                        NewConversationView(usedAsNew: false, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                    }

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.hasAttachments.toggle()
                        self.enableLocation.toggle()
                        self.checkAttachments()

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
            .onAppear() {
                self.imagePicker.setUpAuthStatus()
                self.imagePicker.fetchPhotos(completion: {  })
            }
            
            Spacer()
        }.padding(.vertical, 2.5)
        .animation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0))
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.photoData.append(inputImage)
        self.checkAttachments()
    }
    
    func checkAttachments() {
        if self.imagePicker.selectedPhotos.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation || self.imagePicker.pastedImages.count > 0 {
            self.hasAttachments = true
        } else {
            self.hasAttachments = false
        }
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
            uiView.text = self.text
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent : ResizableTextField
        var hasTyped: Bool = false
        
        init(parent1: ResizableTextField) {
            parent = parent1
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.hasTyped = false
            if self.parent.text == "" {
                textView.text = nil
            }
            if textView.text.count != 0 {
                self.parent.auth.selectedConnectyDialog?.sendUserIsTyping()
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            self.parent.auth.selectedConnectyDialog?.sendUserStoppedTyping()
            UserDefaults.standard.setValue(textView.text, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
        }
                        
        func textViewDidChange(_ textView: UITextView) {
            if textView.text.count == 0 {
                self.hasTyped = false
                self.parent.auth.selectedConnectyDialog?.sendUserStoppedTyping()
            } else if !self.hasTyped {
                self.hasTyped = true
                self.parent.auth.selectedConnectyDialog?.sendUserIsTyping()
            }
            
            DispatchQueue.main.async {
                self.parent.height = textView.contentSize.height
                self.parent.text = textView.text
                if self.parent.text == "" {
                    textView.text = nil
                }
            }
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
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
