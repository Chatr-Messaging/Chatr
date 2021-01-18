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

struct KeyboardCardView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm().objects(DialogStruct.self))
    @ObservedObject var viewModel = AdvancedViewModel()
    @Binding var height: CGFloat
    @State var open: Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @Binding var mainText: String
    @Binding var hasAttachments: Bool
    @State var selectedContacts: [Int] = []
    @State var newDialogID: String = ""
    @State var gifData: [String] = []
    @State var photoData: [UIImage] = []
    @State var enableLocation: Bool = false
    @State var presentGIF: Bool = false
    @State var shareContact: Bool = false
    @State var gifURL: String = ""
    @State var showImagePicker: Bool = false
    @State private var inputImage: UIImage? = nil
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 25.7617,
                longitude: 80.1918
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 10,
                longitudeDelta: 10
            )
        )
    var body: some View {
        VStack(spacing: 0) {
            //MARK: Grabber Icon
            Rectangle()
                .background(Color("bgColor_light"))
                .frame(width: 40, height: 5)
                .cornerRadius(2.5)
                .opacity(0.1)
            
            //MARK: Text Field & Send Btn
            HStack(alignment: .bottom) {
                ZStack {
                    ResizableTextField(height: self.$height, text: self.$mainText)
                        .frame(height: self.height < 125 ? self.height : 125)
                        .padding(.leading, 2.5)
                } .background(Color("buttonColor"))
                .cornerRadius(20)
                .onChange(of: self.mainText) { newValue in
                    if self.mainText.count > 0 {
                        self.auth.selectedConnectyDialog?.sendUserIsTyping()
                    } else {
                        self.auth.selectedConnectyDialog?.sendUserStoppedTyping()
                    }
                }
                //.onAppear() {
//                    if let selectedDiaSavedText = self.dialogs.selectedDia(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first?.typedText {
//                        print("the smaed text here: \(selectedDiaSavedText)")
//                        self.mainText = selectedDiaSavedText
//                    }
                //}
                
                ZStack {
                    //MARK: Send Button
                    Button(action: {
                        if let selectedDialog = self.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                            if let connDia = self.auth.selectedConnectyDialog {
                                connDia.sendUserStoppedTyping()
                            }
                            
//                            for i in selectedDialog.occupentsID {
//                                self.occupents.append(NSNumber(value: i))
//                            }
                            if self.gifData.count > 0 {
                                //have gifs
                                changeMessageRealmData.sendGIFAttachment(dialog: selectedDialog, attachmentStrings: self.gifData.reversed(), occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            
                                self.gifData.removeAll()
                                self.hasAttachments = false
                            }
                            
                            if self.photoData.count > 0 {
                                //have gifs
                                changeMessageRealmData.sendPhotoAttachment(dialog: selectedDialog, attachmentImages: self.photoData, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            
                                self.photoData.removeAll()
                                self.hasAttachments = false
                            }
                            
                            if self.enableLocation {
                                changeMessageRealmData.sendLocationMessage(dialog: selectedDialog, longitude: self.region.center.longitude, latitude: self.region.center.latitude, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                self.enableLocation = false
                                self.hasAttachments = false
                            }
                            
                            if self.mainText.count > 0 {
                                changeMessageRealmData.sendMessage(dialog: selectedDialog, text: self.mainText, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                            }
                        }

                        self.mainText = ""
                        self.height = 0
                    }, label: {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(self.mainText.count > 0 || self.gifData.count > 0 || self.photoData.count > 0 || self.enableLocation ? .white : .gray)
                            .padding(10)
                    }).background(self.mainText.count > 0 || self.gifData.count > 0 || self.photoData.count > 0 || self.enableLocation ? LinearGradient(gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom) : LinearGradient(gradient: Gradient(colors: [Color("bgColor_light"), Color("bgColor_light")]), startPoint: .top, endPoint: .bottom))
                    .clipShape(Circle())
                    .shadow(color: Color.blue.opacity(self.mainText.count > 0 || self.gifData.count > 0 || self.photoData.count > 0 || self.enableLocation ? 0.2 : 0.0), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 5)
                    .disabled(self.mainText.count > 0 || self.gifData.count > 0 || self.photoData.count > 0 || self.enableLocation ? false : true)
                }
            }.padding(.horizontal, 5)
            .padding(.leading, 5)
            .padding(.top, 5)
            
            //MARK: Attachments Section
            ScrollView(.horizontal, showsIndicators: true, content: {
                HStack {
                    //MARK: Location Section
                    if self.enableLocation {
                        ZStack(alignment: .topLeading) {
                            Map(coordinateRegion: $region, interactionModes: MapInteractionModes.all, showsUserLocation: true, userTrackingMode: $userTrackingMode)
                                .aspectRatio(contentMode: .fit)
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .cornerRadius(15)
                                .onAppear() {
                                    self.region.span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
                                }
                            
                            Button(action: {
                                print("remove Location")
                                self.enableLocation = false
                                self.hasAttachments = false
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
                    
                    //MARK: GIPHY Section
                    HStack {
                        ForEach(self.gifData.indices, id: \.self) { url in
                            HStack(spacing: 5) {
                                ZStack(alignment: .topLeading) {
                                    AnimatedImage(url: URL(string: self.gifData[url]))
                                        .resizable()
                                        .placeholder{ Image(systemName: "photo.on.rectangle.angled") }
                                        .indicator(.activity)
                                        .aspectRatio(contentMode: .fit)
                                        .scaledToFit()
                                        .frame(height: 90)
                                        //.frame(idealWidth: 90, alignment: .center)
                                        .transition(.fade(duration: 0.05))
                                        .cornerRadius(15)
                                    
                                    Button(action: {
                                        print("remove GIPHY")
                                        self.gifData.remove(at: url)
                                        if self.gifData.count > 0 {
                                            self.hasAttachments = true
                                        } else {
                                            self.hasAttachments = false
                                        }
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
                    }.padding(.bottom, self.hasAttachments ? 7.5 : 0)
                    .onChange(of: self.gifURL, perform: { giphyURL in
                        self.gifData.append(giphyURL)
                        if self.gifData.count > 0 || self.photoData.count > 0 {
                            self.hasAttachments = true
                        } else {
                            self.hasAttachments = false
                        }
                    })
                    
                    //MARK: Photo Section
                    HStack {
                        ForEach(self.photoData.indices, id: \.self) { img in
                            HStack(spacing: 5) {
                                ZStack(alignment: .topLeading) {
                                    Image(uiImage: self.photoData[img])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaledToFit()
                                        .frame(height: 90)
                                        .transition(.fade(duration: 0.05))
                                        .cornerRadius(15)
                                    
                                    Button(action: {
                                        print("remove Photo")
                                        self.photoData.remove(at: img)
                                        if self.photoData.count > 0 || self.gifData.count > 0{
                                            self.hasAttachments = true
                                        } else {
                                            self.hasAttachments = false
                                        }
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
                    }.padding(.bottom, self.hasAttachments ? 7.5 : 0)
                }.padding(.top, 15)
                .padding(.horizontal)
            }).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
            
            //MARK: Action Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 10) {
                    Spacer()
                    Button(action: {
                        print("Photos Btn")
                        self.showImagePicker.toggle()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .circular)
                                .frame(width: Constants.screenWidth / 4.9, height: 60)
                                .foregroundColor(Color("buttonColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 22)
                                .foregroundColor(.primary)
                                .padding(30)
                        }
                        
                    }).buttonStyle(ClickMiniButtonStyle())
                    .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                        ImagePicker(image: self.$inputImage)
                    }

//                    Button(action: {
//                        print("Attachment Btn")
//                        if let selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") {
//                            ChatrApp.messages.getMessageUpdates(dialogID: selectedDialogID, completion: { newMessages in
//                                print("Attachment Btn successfully pulled new messages!")
//                            })
//                        }
//                    }, label: {
//                        Image(systemName: "paperclip")
//                            .resizable()
//                            .frame(width: 24, height: 24)
//                            .foregroundColor(.primary)
//                            .padding(30)
//                    }).buttonStyle(ClickMiniButtonStyle())
//                    .frame(width: Constants.screenWidth / 4.9, height: 60)
//                    .background(Color("buttonColor"))
//                    .cornerRadius(15)
//                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                    
                    Button(action: {
                        self.presentGIF.toggle()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .circular)
                                .frame(width: Constants.screenWidth / 4.9, height: 60)
                                .foregroundColor(Color("buttonColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            
                            Text("GIF")
                                .fontWeight(.bold)
                                .frame(width: 28, height: 22)
                                .foregroundColor(.primary)
                                .padding(30)
                        }
                    }).buttonStyle(ClickMiniButtonStyle())
                    .sheet(isPresented: self.$presentGIF, content: {
                        GIFController(url: self.$gifURL, present: self.$presentGIF)
                    })
                    
                    Button(action: {
                        print("Contact Btn")
                        self.shareContact.toggle()
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .circular)
                                .frame(width: Constants.screenWidth / 4.9, height: 60)
                                .foregroundColor(Color("buttonColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            
                            Image(systemName: "person.2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 22)
                                .foregroundColor(.primary)
                                .padding(30)
                        }
                    }).buttonStyle(ClickMiniButtonStyle())
                    .sheet(isPresented: self.$shareContact, onDismiss: {
                        if self.selectedContacts.count > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if let selectedDialog = self.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first {
                                    changeMessageRealmData.sendContactMessage(dialog: selectedDialog, contactID: self.selectedContacts, occupentID: self.auth.selectedConnectyDialog?.occupantIDs ?? [])
                                }
                            }
                        }
                    }) {
                        NewConversationView(usedAsNew: false, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                    }

                    Button(action: {
                        print("Location Btn")
                        self.hasAttachments.toggle()
                        self.enableLocation.toggle()
                        
                        self.viewModel.checkLocationPermission()
                        if self.viewModel.locationPermission {
                            self.region.center.longitude = self.viewModel.locationManager.location?.coordinate.longitude ?? 0
                            self.region.center.latitude = self.viewModel.locationManager.location?.coordinate.latitude ?? 0
                        } else {
                            self.viewModel.requestLocationPermission()
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .circular)
                                .frame(width: Constants.screenWidth / 4.9, height: 60)
                                .foregroundColor(Color("buttonColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            
                            Image(systemName: self.enableLocation ? "location.fill" : "location")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 22)
                                .foregroundColor(self.enableLocation ? .blue : .primary)
                                .shadow(color: Color.black.opacity(self.enableLocation ? 0.2 : 0.0), radius: 5, x: 0, y: 5)
                                .padding(30)
                                .cornerRadius(15)
                        }
                    }).buttonStyle(ClickMiniButtonStyle())
                                        
                    Spacer()
                }.padding(.bottom, 40)
                //.padding(.top, self.hasAttachments ? 5 : 10)
                .background(Color.clear)
                Spacer()
            }
        }.padding(.vertical, 5)
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        self.photoData.append(inputImage)
        if self.photoData.count > 0 || self.gifData.count > 0{
            self.hasAttachments = true
        } else {
            self.hasAttachments = false
        }
    }
}

//MARK: Message Text Field
struct ResizableTextField : UIViewRepresentable {
    @Binding var height: CGFloat
    @Binding var text: String
    @State var emptyPlaceholder: Bool = false
    
    func makeCoordinator() -> Coordinator {
        return ResizableTextField.Coordinator(parent1: self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = true
        view.isScrollEnabled = true
        view.text = self.text
        view.font = .systemFont(ofSize: 18)
        view.textColor = UIColor(named: "textColor")
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            self.height = uiView.contentSize.height
//            if let typedText = self.dialogs.selectedDia(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first?.typedText {
//                self.text = typedText
//            } else {
//                self.text = ""
//            }
            uiView.text = self.text
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent : ResizableTextField
        
        init(parent1: ResizableTextField) {
            parent = parent1
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if self.parent.text == "" {
                //textView.text = nil
                textView.textColor = UIColor(named: "textColor")
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if self.parent.text == "" && self.parent.emptyPlaceholder == false {
                //"write somehting to ~NAME~" as placholder option
                textView.text = "type message"
                textView.textColor = .gray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.height = textView.contentSize.height
                self.parent.text = textView.text
            }
        }
    }
}
