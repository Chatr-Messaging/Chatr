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
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.7617, longitude: 80.1918),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))

    var body: some View {
        VStack(spacing: 0) {
//            //MARK: Grabber Icon
//            Rectangle()
//                .background(Color("bgColor_light"))
//                .frame(width: 40, height: 5)
//                .cornerRadius(2.5)
//                .padding(.top, 2.5)
//                .opacity(0.1)

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
                                    .onAppear() {
                                        self.region.span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
                                    }
                            }).buttonStyle(ClickMiniButtonStyle())
                            .background(Color.clear)
                        }
                    }
                    
                    //MARK: GIPHY Section
                    HStack {
                        ForEach(self.gifData.indices, id: \.self) { url in
                            HStack(spacing: 10) {
                                ZStack(alignment: .topLeading) {
                                    AnimatedImage(url: URL(string: self.gifData[url]))
                                        .resizable()
                                        .placeholder{ Image(systemName: "photo.on.rectangle.angled") }
                                        .indicator(.activity)
                                        .scaledToFit()
                                        .frame(height: 90)
                                        .frame(minWidth: 65)
                                        .transition(.fade(duration: 0.05))
                                        .cornerRadius(10)
                                    
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
                                            .offset(x: -10, y: -10)
                                    }).background(Color.clear)
                                }
                            }
                        }
                    }
                    .onChange(of: self.gifURL, perform: { giphyURL in
                        self.gifData.append(giphyURL)
                        self.checkAttachments()
                    })
                    
                    //MARK: Photo Section
                    HStack {
                        ForEach(self.imagePicker.selectedPhotos, id: \.self) { img in
                            HStack(spacing: 10) {
                                Image(uiImage: img.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 90)
                                    .frame(minWidth: 70)
                                    .transition(.fade(duration: 0.05))
                                    .cornerRadius(10)
                            }
                        }
                    }

                    //MARK: Video Section
                    HStack {
                        ForEach(self.imagePicker.selectedVideos, id: \.self) { vid in
                            HStack(spacing: 10) {
                                Image(uiImage: vid.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 90)
                                    .frame(minWidth: 70)
                                    .transition(.fade(duration: 0.05))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }.padding(.top, self.hasAttachments ? 10 : 0)
                .padding(.bottom, self.hasAttachments ? 5 : 0)
                .padding(.horizontal)
            }).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
            
            //MARK: Text Field & Send Btn
            HStack(alignment: .bottom, spacing: 5) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation(Animation.easeInOut(duration: 0.3), {
                        self.isKeyboardActionOpen.toggle()
                    })
                }) {
                    Image(systemName: "paperclip")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25, alignment: .center)
                        .foregroundColor(.primary)
                        .padding(8)
                }.buttonStyle(changeBGButtonStyle())
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(self.mainText.count != 0 ? 0.1 : 0.15), radius: self.mainText.count != 0 ? 6 : 4, x: 0, y: self.mainText.count != 0 ? 6 : 2.5)

                ResizableTextField(height: self.$height, text: self.$mainText)
                    .environmentObject(self.auth)
                    .frame(height: self.height < 175 ? self.height : 175)
                    .padding(.leading, 10)
                    .padding(.vertical, 2)
                    .background(
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: self.height < 160 ? 12.5 : 17.5)
                                .foregroundColor(Color("buttonColor"))
                                .padding(.horizontal, 5)
                                .shadow(color: Color.black.opacity(self.mainText.count != 0 ? 0.1 : 0.15), radius: self.mainText.count != 0 ? 6 : 4, x: 0, y: self.mainText.count != 0 ? 6 : 2.5)

                            Text("type message")
                                .font(.system(size: 18))
                                .padding(.vertical, 9)
                                .padding(.horizontal)
                                .foregroundColor(self.mainText.count == 0 && self.isOpen ? Color("lightGray") : .clear)
                        }
                    )
                    .onChange(of: self.isOpen, perform: { value in
                        if value {
                            if let typedText = UserDefaults.standard.string(forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText") {
                                self.mainText = typedText
                            } else { self.mainText = "" }
                        } else {
                            UserDefaults.standard.setValue(self.mainText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                        }
                    })
                
                //MARK: Send Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.isKeyboardActionOpen = false

                    if let selectedDialog = self.auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                        if let connDia = self.auth.selectedConnectyDialog {
                            connDia.sendUserStoppedTyping()
                        }

                        if self.gifData.count > 0 {
                            changeMessageRealmData.sendGIFAttachment(dialog: selectedDialog, attachmentStrings: self.gifData.reversed(), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                        
                            self.gifData.removeAll()
                        }
                        
                        if self.imagePicker.selectedPhotos.count > 0 {
                            var uploadImg: [UIImage] = []
                            
                            for i in self.imagePicker.selectedPhotos {
                                uploadImg.append(i.image)
                            }
                            
                            changeMessageRealmData.sendPhotoAttachment(dialog: selectedDialog, attachmentImages: uploadImg, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                        
                            uploadImg.removeAll()
                            self.imagePicker.selectedPhotos.removeAll()
                        }

                        if self.imagePicker.selectedVideos.count > 0 {
                            //COME BACK AND ADD THE UPLOADING VIDEOS SECTION
                            //changeMessageRealmData.sendPhotoAttachment(dialog: selectedDialog, attachmentImages: self.photoData, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            print("There are selected videos we will remove later...")
                        }
                        
                        if self.enableLocation {
                            changeMessageRealmData.sendLocationMessage(dialog: selectedDialog, longitude: self.region.center.longitude, latitude: self.region.center.latitude, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            self.enableLocation = false
                        }
                        
                        if self.mainText.count > 0 {
                            changeMessageRealmData.sendMessage(dialog: selectedDialog, text: self.mainText, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
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
                        .foregroundColor(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? .white : .secondary)
                        .padding(10)
                }).background(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor")]), startPoint: .top, endPoint: .bottom))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? 0.2 : 0.1), radius: 4, x: 0, y: 3)
                .shadow(color: Color.blue.opacity(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? 0.3 : 0.0), radius: 8, x: 0, y: 6)
                .scaleEffect(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? 1.04 : 1.0)
                .disabled(self.mainText.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedPhotos.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation ? false : true)
            }.padding(.horizontal)
            .padding(.top, 10)

             
            //MARK: Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 24) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if !showImagePicker { UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true) }
                        self.imagePicker.openImagePicker(completion: {
                            self.showImagePicker.toggle()
                        })
                        self.checkAttachments()
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
//                    .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
//                        ImagePicker(image: self.$inputImage)
//                    }
                    
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
                                    changeMessageRealmData.sendContactMessage(dialog: selectedDialog, contactID: self.selectedContacts, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
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
                                        
                }.padding(.top, 15)
                .padding(.bottom, 10)
                .background(Color.clear)
            }
            
            //MARK: Image & Video Asset Picker
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 5) {
                    // Images...
                    ForEach(imagePicker.fetchedPhotos.indices, id: \.self) { photo in
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            imagePicker.extractPreviewData(asset: self.imagePicker.fetchedPhotos[photo].asset, completion: {
                                if self.imagePicker.fetchedPhotos[photo].selected {
                                    if self.imagePicker.fetchedPhotos[photo].asset.mediaType == .video {
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
                .background(Color.clear)
            }.frame(height: showImagePicker ? 200 : 0)
            .padding(.top, 5)
            .opacity(showImagePicker ? 1 : 0)
            .onAppear() {
                self.imagePicker.setUpAuthStatus()
                self.imagePicker.fetchPhotos(completion: {  })
            }
            
            Spacer()
        }.padding(.vertical, 5)
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.photoData.append(inputImage)
        self.checkAttachments()
    }
    
    func checkAttachments() {
        if self.imagePicker.selectedPhotos.count > 0 || self.gifData.count > 0 || self.imagePicker.selectedVideos.count > 0 || self.enableLocation {
            self.hasAttachments = true
        } else {
            self.hasAttachments = false
        }
    }
}

//MARK: Message Text Field
struct ResizableTextField : UIViewRepresentable {
    @EnvironmentObject var auth: AuthModel
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
                .frame(minWidth: 105)
                .cornerRadius(10)
            
            HStack {
                if photo.asset.mediaType == .video{
                    Image(systemName: "video.fill")
                        .font(.headline)
                        .foregroundColor(.white)
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
}
