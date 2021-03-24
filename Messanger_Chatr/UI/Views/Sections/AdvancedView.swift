//
//  AdvancedView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Combine
import ConnectyCube
import RealmSwift
import Contacts
import Photos
import Firebase

struct advancedView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel = AdvancedViewModel()
    @Binding var dimissView: Bool
    @State var diabaleSyncAddressBook: Bool = false
    @State var loadingSyncAddressBook: Bool = false
    @State var diabaleRestoreSub: Bool = false
    @State var deleteAccount: Bool = false
    @State var showDeleteAccountSheet: Bool = false
    @State var instagramReset: Bool = false
    
    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    //MARK: PERMISSIONS Section
                    HStack {
                        Text("PERMISSIONS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        VStack {
                            
                            //contacts section
                            VStack {
                                HStack {
                                    Image(systemName: "rectangle.stack.person.crop")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.contactsPermission ? .secondary : .primary)
                                    
                                    Text("Contacts")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(self.viewModel.contactsPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()

                                    Button(action: {
                                        self.viewModel.requestContacts()
                                    }) {
                                        Text(self.viewModel.contactsPermission ? "Allowed" : "Allow")
                                           .padding([.top, .bottom], 10)
                                           .padding([.leading, .trailing], 20)
                                           .transition(.identity)
                                    }.disabled(self.viewModel.contactsPermission ? true : false)
                                     .frame(height: 35)
                                    .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.contactsPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkContactsPermission()
                                }
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 65)
                                    .offset(x: 35)
                            }.padding(.bottom, 5)
                            
                            //Location section
                            VStack {
                                HStack {
                                    Image(systemName: "location")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.locationPermission ? .secondary : .primary)
                                    
                                    Text("Location")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .padding(.leading, 5)
                                        .foregroundColor(self.viewModel.locationPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if self.viewModel.locationPermission == false {
                                            self.viewModel.requestLocationPermission()
                                        }
                                    }) {
                                     Text(self.viewModel.locationPermission ? "Allowed" : "Allow")
                                            .padding([.top, .bottom], 10)
                                            .padding([.leading, .trailing], 20)
                                            .transition(.identity)
                                      }
                                      .disabled(self.viewModel.locationPermission ? true : false)
                                      .frame(height: 35)
                                      .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.locationPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkLocationPermission()
                                }
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 65)
                                    .offset(x: 35)
                            }.padding(.bottom, 5)
                            
                            //Notification section
                            VStack {
                                HStack {
                                    Image(systemName: "bell")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.notificationPermission ? .secondary : .primary)
                                    
                                    Text("Notifications")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .padding(.leading, 5)
                                        .foregroundColor(self.viewModel.notificationPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if self.viewModel.notificationPermission == false {
                                            if #available(iOS 10, *) {
                                                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound, .carPlay], completionHandler: { (granted, error) in
                                                    if error == nil {
                                                        DispatchQueue.main.async(execute: {
                                                            UIApplication.shared.registerForRemoteNotifications()
                                                        })
                                                        self.viewModel.checkNotiPermission()
                                                    }
                                                })
                                            } else {
                                                let notificationSettings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
                                                DispatchQueue.main.async(execute: {
                                                    UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                                                    UIApplication.shared.registerForRemoteNotifications()
                                                })
                                                self.viewModel.checkNotiPermission()
                                            }
                                        }
                                      }) {
                                        Text(self.viewModel.notificationPermission ? "Allowed" : "Allow")
                                            .padding([.top, .bottom], 10)
                                            .padding([.leading, .trailing], 20)
                                            .transition(.identity)
                                      }.disabled(self.viewModel.notificationPermission ? true : false)
                                      .frame(height: 35)
                                      .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.notificationPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkNotiPermission()
                                }
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 65)
                                    .offset(x: 35)
                            }.padding(.bottom, 5)
                            
                            //photos section
                            VStack {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.photoPermission ? .secondary : .primary)
                                    
                                    Text("Photos")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .padding(.leading, 5)
                                        .foregroundColor(self.viewModel.photoPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    Button(action: {
                                        if self.viewModel.photoPermission == false {
                                          let photos = PHPhotoLibrary.authorizationStatus()
                                          if photos == .notDetermined {
                                              PHPhotoLibrary.requestAuthorization({ status in
                                                  if status == .authorized{
                                                    DispatchQueue.main.async(execute: {
                                                        self.viewModel.photoPermission = true
                                                    })
                                                  }
                                              })
                                          }
                                        }
                                    }) {
                                     Text(self.viewModel.photoPermission ? "Allowed" : "Allow")
                                           .padding([.top, .bottom], 10)
                                           .padding([.leading, .trailing], 20)
                                           .transition(.identity)
                                     }.disabled(self.viewModel.photoPermission ? true : false)
                                     .frame(height: 35)
                                    .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.photoPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                   .foregroundColor(.white)
                                   .cornerRadius(20)
                                }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkPhotoPermission()
                                }
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 65)
                                    .offset(x: 35)
                            }.padding(.bottom, 5)
                            
                            //camera section
                            VStack {
                                HStack {
                                    Image(systemName: "camera")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.cameraPermission ? .secondary : .primary)
                                    
                                    Text("Camera")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .padding(.leading, 5)
                                        .foregroundColor(self.viewModel.cameraPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    Button(action: {
                                        if self.viewModel.cameraPermission == false {
                                            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                                                if granted {
                                                    self.viewModel.cameraPermission = true
                                                } else {
                                                    self.viewModel.cameraPermission = false
                                                }
                                            })
                                        }
                                    }) {
                                        Text(self.viewModel.cameraPermission ? "Allowed" : "Allow")
                                            .padding([.top, .bottom], 10)
                                            .padding([.leading, .trailing], 20)
                                            .transition(.identity)
                                    }.disabled(self.viewModel.cameraPermission ? true : false)
                                     .frame(height: 35)
                                     .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.cameraPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkCameraPermission()
                                }
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 65)
                                    .offset(x: 35)
                            }.padding(.bottom, 5)
                            
                            //mic section
                            VStack {
                                HStack {
                                    Image(systemName: "mic.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .foregroundColor(self.viewModel.micPermission ? .secondary : .primary)
                                    
                                    Text("Microphone")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .padding(.leading, 5)
                                        .foregroundColor(self.viewModel.micPermission ? .secondary : .primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                    Button(action: {
                                        if self.viewModel.micPermission == false {
                                            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                                                self.viewModel.micPermission = granted
                                            })
                                        }
                                    }) {
                                        Text(self.viewModel.micPermission ? "Allowed" : "Allow")
                                            .padding([.top, .bottom], 10)
                                            .padding([.leading, .trailing], 20)
                                            .transition(.identity)
                                    }.disabled(self.viewModel.micPermission ? true : false)
                                     .frame(height: 35)
                                     .background(LinearGradient(gradient: Gradient(colors: !self.viewModel.micPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(.white)
                                    .cornerRadius(20)
                                    }
                                }.padding(.horizontal)
                                .onAppear {
                                    self.viewModel.checkMicPermission()
                                }
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    //MARK: OTHER Section
                    HStack {
                        Text("OTHER:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    VStack(alignment: .center) {
                        VStack(spacing: 0) {
                            //Disconnect Instagram
                            
                            //Sync Address
                            Button(action: {
                                self.diabaleSyncAddressBook = true
                                self.loadingSyncAddressBook = true
                                changeAddressBookRealmData.shared.uploadAddressBook(completion: { _ in
                                    self.loadingSyncAddressBook = false
                                })
                            }) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack(alignment: .center) {
                                        Text(self.diabaleSyncAddressBook ? "Synced Address Book" : "Sync Address Book")
                                            .foregroundColor(self.diabaleSyncAddressBook ? .secondary : .primary)
                                        
                                        Spacer()
                                        //load the address book realm func
                                        ZStack {
                                            Text("last sync: \(self.auth.profile.results.first?.lastAddressBookUpdate ?? "n/a")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .opacity(self.loadingSyncAddressBook ? 0 : 1)
                                            
                                            if self.loadingSyncAddressBook {
                                                Circle()
                                                    .trim(from: 0, to: 0.8)
                                                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                                                    .frame(width: 20, height: 20)
                                                    .rotationEffect(.init(degrees: self.loadingSyncAddressBook ? 360 : 0))
                                                    .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                                                    .opacity(self.loadingSyncAddressBook ? 1 : 0)
                                                    .onAppear() {
                                                        self.loadingSyncAddressBook.toggle()
                                                    }
                                            }
                                        }
                                    }.padding(.horizontal)
                                    .padding(.vertical, 12.5)
                                    Divider()
                                        .frame(width: Constants.screenWidth - 80)
                                }
                            }.buttonStyle(changeBGButtonStyle())
                            .disabled(self.diabaleSyncAddressBook ? true : false)
                            
                            Button(action: {
                                Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["instagramAccessToken" : ""])
                                Database.database().reference().child("Users").child("\(Session.current.currentUserID)").updateChildValues(["instagramId" : ""])
                                self.instagramReset = false
                            }) {
                                HStack(alignment: .center) {
                                    Text(self.instagramReset ? "Unauthorize Instagram" : "Instagram Disabled")
                                        .foregroundColor(!self.instagramReset ? .secondary : .primary)
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 12.5)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                            }.buttonStyle(changeBGButtonStyle())
                            .disabled(!self.instagramReset ? true : false)
                            .onAppear {
                                if self.auth.profile.results.first?.instagramAccessToken != "" && self.auth.profile.results.first?.instagramId != 0 {
                                    self.instagramReset = true
                                }
                            }

                            //Restore Purchase
                            Button(action: {
                                self.auth.restorePurchase()
                                self.diabaleRestoreSub.toggle()
                            }) {
                                HStack(alignment: .center) {
                                    Text(self.diabaleRestoreSub ? "Restored Subscriptions" : "Restore Subscriptions")
                                        .foregroundColor(self.diabaleRestoreSub ? .secondary : .primary)
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 12.5)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                            }.buttonStyle(changeBGButtonStyle())
                            .disabled(self.diabaleRestoreSub ? true : false)
                            
                            //Delete Account
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.showDeleteAccountSheet.toggle()
                            }) {
                                HStack(alignment: .center) {
                                    Text(self.deleteAccount ? "Delete Account" : "Deleted Account")
                                        .foregroundColor(self.deleteAccount ? .secondary : .red)
                                    
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 12.5)
                            }.buttonStyle(changeBGButtonStyle())
                            .disabled(self.deleteAccount ? true : false)
                            .actionSheet(isPresented: $showDeleteAccountSheet) {
                                ActionSheet(title: Text("Are you sure?"), message: nil, buttons: [.destructive(Text("Delete Account"), action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.deleteAccount.toggle()
                                    Request.deleteCurrentUser(successBlock: {
                                        self.auth.preventDismissal = true
                                        self.auth.isUserAuthenticated = .signedOut
                                        withAnimation {
                                            self.dimissView.toggle()
                                        }
                                    }) { (error) in
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }), .cancel(Text("Cancel"))])
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    Spacer()
                    FooterInformation()
                        .padding(.top, 50)
                        .padding(.bottom, 25)
                }.padding(.top, 110)
            }.navigationBarTitle("Advanced", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
