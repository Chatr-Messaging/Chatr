//
//  CameraView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/29/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct CameraView: View {
    var contact = ContactStruct()
    @Binding var cameraState: QuickSnapViewingState
    @Binding var cameraFocus: CGPoint
    @Binding var selectedQuickSnapContact: ContactStruct
    @State private var inputImage: UIImage?
    @State var didTapCapture: Bool = false
    @State var isCameraFront: Bool = false
    @State var isAddNewUserOpen: Bool = false
    @State var loadSending: Bool = false
    @State var loadAni: Bool = false
    @State var savedTakenImg: Bool = false
    @Binding var selectedContacts: [Int]
    @State var showImagePicker: Bool = false
    @State private var inputCameraRollImage: UIImage? = nil
    @State var newDialogID: String = ""
    
    var body: some View {
        VStack {
            ZStack {
                if self.inputImage == nil {
                    //MARK: CAMERA CAPTURE VIEW

                    CameraViewController(image: self.$inputImage, cameraState: self.$cameraState, didTapCapture: self.$didTapCapture, isCameraUsingFront: self.$isCameraFront, cameraFocusPoint: self.$cameraFocus)
                        .edgesIgnoringSafeArea(.bottom)
                    
                    VStack {
                        HStack {
                            if self.contact.avatar != "" {
                                ZStack {
                                    Circle()
                                        .foregroundColor(.white)
                                        .frame(width: Constants.smallAvitarSize + 2, height: Constants.smallAvitarSize + 2, alignment: .center)
                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                    
                                    WebImage(url: URL(string: contact.avatar))
                                        .resizable()
                                        .placeholder{ Image(systemName: "person.fill") }
                                        .indicator(.activity)
                                        .transition(.fade(duration: 0.25))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .foregroundColor(Color("bgColor"))
                                        .frame(width: Constants.smallAvitarSize, height: Constants.smallAvitarSize, alignment: .center)
                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                }
                            }

                            if self.contact.fullName != "No Name" {
                                Text(contact.fullName)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                    .onAppear() {
                                        if self.selectedContacts.count == 0 {
                                            self.selectedContacts.append(self.contact.id)
                                        }
                                    }
                            }

                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.cameraState = .closed
                            }) {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: Constants.microBtnSize, height: Constants.microBtnSize, alignment: .center)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                    .padding()
                            }.buttonStyle(ClickButtonStyle())
                        }.padding(.all)
                        .padding(.top)
                        
                        Spacer()
                        
                        ZStack {
                            CapturePhotoButton().onTapGesture {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.didTapCapture = true
                                //self.cameraState = .takenPic
                            }
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.isCameraFront.toggle()
                            }) {
                                Image(systemName: "arrow.2.circlepath")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30, alignment: .center)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 0)
                                    .rotationEffect(self.isCameraFront ? .degrees(180) : .degrees(360))
                                    .animation(.easeInOut(duration: 0.35))
                                    .padding(10)
                            }.buttonStyle(ClickButtonStyle())
                            .offset(x: 120)
                            .padding()
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.showImagePicker.toggle()
                            }) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30, alignment: .center)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 0)
                                    .animation(.easeInOut(duration: 0.35))
                                    .padding(10)
                            }.buttonStyle(ClickButtonStyle())
                            .offset(x: -120)
                            .padding()
                            .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                                ImagePicker(image: self.$inputCameraRollImage)
                            }
                            
                        }.padding(.bottom, 55)
                    }
                } else {
                    //MARK: EDIT & REVIEW PHOTO
                    ZStack {
                        Image(uiImage: self.inputImage ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                            .onAppear() {
                                self.cameraState = .takenPic
                                print("taken pic?? \(self.cameraState)")
                            }
                        
                        VStack(alignment: .trailing) {
                            HStack {
//                                Spacer()
//                                ZStack {
//                                    Circle()
//                                        .foregroundColor(.white)
//                                        .frame(width: Constants.smallAvitarSize + 2, height: Constants.smallAvitarSize + 2, alignment: .center)
//                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
//
//                                    WebImage(url: URL(string: contact.avatar))
//                                        .resizable()
//                                        .placeholder{ Image(systemName: "person.fill") }
//                                        .indicator(.activity)
//                                        .transition(.fade(duration: 0.25))
//                                        .scaledToFill()
//                                        .clipShape(Circle())
//                                        .foregroundColor(Color("bgColor"))
//                                        .frame(width: Constants.smallAvitarSize, height: Constants.smallAvitarSize, alignment: .center)
//                                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
//                                }
//                                VStack(alignment: .leading) {
//                                    if self.contact.fullName != "No Name" {
//                                        Text(contact.fullName)
//                                            .font(.body)
//                                            .fontWeight(.semibold)
//                                            .foregroundColor(.white)
//                                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
//
//                                        if self.selectedContacts.count > 1 {
//                                            Text("and \(self.selectedContacts.count - 1) more...")
//                                                .font(.caption)
//                                                .fontWeight(.regular)
//                                                .foregroundColor(.white)
//                                                .opacity(0.8)
//                                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
//                                        }
//                                    }
//                                }.padding(.top, 35)
                                Spacer()
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.savedTakenImg = false
                                    self.selectedContacts.removeAll()
                                    self.cameraState = .closed
                                    self.inputImage = nil
                                }) {
                                    Image(systemName: "xmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: Constants.microBtnSize, height: Constants.microBtnSize, alignment: .center)
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                        .padding(.all)
                                }.buttonStyle(ClickButtonStyle())
                                .padding(.all)
                                .padding(.top, 20)
                            }
                            Spacer()
                            HStack() {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.savedTakenImg = false
                                    self.cameraState = .camera
                                    self.inputImage = nil
                                }) {
                                    VStack(alignment: .center) {
                                        Image(systemName: "camera.viewfinder")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30, alignment: .center)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                            .offset(y: 2)
                                        
                                        Text("Retake")
                                            .font(.caption)
                                            .fontWeight(.none)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                    }
                                }.buttonStyle(ClickButtonStyle())
                                .padding(.trailing, 20)
                                .opacity(self.loadSending ? 0 : 1)
                                .disabled(self.loadSending)
                                
                                Button(action: {
                                    if let saveImg = self.inputImage {
                                        if !self.savedTakenImg {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            let imageSaver = ImageSaver()
                                            imageSaver.writeToPhotoAlbum(image: saveImg)
                                            self.savedTakenImg = true
                                        } else {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }) {
                                    VStack(alignment: .center) {
                                        Image(systemName: self.savedTakenImg ? "checkmark" : "tray.and.arrow.down")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 26, height: 30, alignment: .center)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                            .offset(y: 2)
                                        
                                        Text(self.savedTakenImg ? "Saved" : "Save")
                                            .font(.caption)
                                            .fontWeight(.none)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                    }
                                }.buttonStyle(ClickButtonStyle())
                                .opacity(self.loadSending ? 0 : 1)
                                .disabled(self.loadSending)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.isAddNewUserOpen = true
                                    print("add contact")
                                }) {
                                    VStack(alignment: .center) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 33, height: 30, alignment: .center)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                            .offset(y: 1)
                                        
                                        Text("Add")
                                            .font(.caption)
                                            .fontWeight(.none)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 0)
                                            .offset(y: -1)
                                    }
                                }.buttonStyle(ClickButtonStyle())
                                .padding(.trailing, 15)
                                .opacity(self.loadSending ? 0 : 1)
                                .disabled(self.loadSending)
                                .sheet(isPresented: self.$isAddNewUserOpen) {
                                    NewConversationView(usedAsNew: false, allowOnlineSearch: false, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                                }
                                
                                if self.loadSending {
                                    VStack {
                                        Circle()
                                            .trim(from: 0, to: 0.8)
                                            .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                            .frame(width: 25, height: 25)
                                            .rotationEffect(.init(degrees: self.loadAni ? 360 : 0))
                                            .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                                            .padding(.horizontal, 45)
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                            .onAppear() {
                                                print("the selected users to send to are: \(self.selectedContacts)")
                                                self.loadAni.toggle()
                                            }
                                        
                                        Text("sending...")
                                            .font(.caption)
                                            .fontWeight(.none)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                            .offset(y: -1)
                                    }.offset(x: 5)
                                } else {
                                    if self.selectedContacts.count != 0 {
                                        ZStack(alignment: .topLeading) {
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                self.loadSending = true
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                    self.sendQuickPic()
                                                    changeContactsRealmData().updateContactHasQuickSnap(userID: self.selectedContacts, hasQuickSnap: true)
                                                }
                                                
                                            }) {
                                                Image(systemName: "paperplane.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 28, height: 30, alignment: .center)
                                                    .foregroundColor(.white)
                                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 4)
                                                    .padding()
                                            }.buttonStyle(ClickButtonStyle())
                                            .frame(width: 50, height: 50, alignment: .center)
                                            .foregroundColor(.clear)
                                            .background(Constants.snapPurpleGradient)
                                            .cornerRadius(15)
                                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 8)
                                            
                                            HStack {
                                                Text(String(self.selectedContacts.count))
                                                    .foregroundColor(.white)
                                                    .fontWeight(.semibold)
                                                    .font(.footnote)
                                                    .padding(.horizontal, 5)
                                            }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("main_blue")).shadow(color: Color("main_blue").opacity(0.50), radius: 5, x: 0, y: 5))
                                            .offset(x: -6, y: -6)
                                        }
                                    }
                                }
                            }.padding(.horizontal)
                        }.padding(.bottom, 55)
                    }.onAppear() {
                        if self.selectedQuickSnapContact.id != 0 && self.selectedContacts.count == 0 {
                            self.selectedContacts.append(self.selectedQuickSnapContact.id)
                        }
                    }
                }
            }//.scaleEffect(self.cameraState != .closed ? 1 : 0, anchor: .center)
            .disabled(self.cameraState != .closed ? false : true)
            .animation(.easeInOut(duration: 0.2))
        }.onDisappear() {
            self.inputImage = nil
        }
    }
    
    private func sendQuickPic() {
        changeQuickSnapsRealmData.sendQuickSnap(image: self.inputImage?.pngData() ?? Data(), sendTo: self.selectedContacts, completion: { result in
            if result == false {
                //error sending post
                self.loadAni = false
                self.loadSending = false
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                self.cameraState = .closed
                
                let event = Event()
                event.notificationType = .push
                var occs: [NSNumber] = []
                for i in self.selectedContacts {
                    occs.append(NSNumber(value: i))
                }
                event.usersIDs = occs
                event.type = .oneShot

                var pushParameters = [String : String]()
                pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") sent you a quick snap"
                pushParameters["ios_sound"] = "app_sound.wav"

                if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                            options: .prettyPrinted) {
                  let jsonString = String(bytes: jsonData,
                                          encoding: String.Encoding.utf8)

                  event.message = jsonString

                  Request.createEvent(event, successBlock: {(events) in
                    print("sent push notification!! \(events)")
                    occs.removeAll()
                  }, errorBlock: {(error) in
                    print("error sending noti: \(error.localizedDescription)")
                    occs.removeAll()
                  })
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.loadAni = false
                    self.savedTakenImg = false
                    self.selectedContacts.removeAll()
                    self.inputImage = nil
                    self.loadSending = false
                }
            }
        })
    }
    
    func loadImage() {
        guard let inputImage2 = inputCameraRollImage else { return }
        self.inputImage = inputImage2
    }
}
