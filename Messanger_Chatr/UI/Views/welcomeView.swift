//
//  welcomeView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/1/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import SwiftUI
import UIKit
import Combine
import RealmSwift
import PhoneNumberKit
import Photos
import Contacts
import CoreLocation
import SDWebImageSwiftUI
import CoreTelephony

// MARK: Welcome View
struct welcomeView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var auth: AuthModel
    @State private var bgDelay = false
    @Binding var presentView: Bool
    
    var body: some View {
        ZStack {
            MainBody(presentView: self.$presentView)
                .environmentObject(self.auth)
                .edgesIgnoringSafeArea(.bottom)
        }//.background(AnimatedGradientGradientBG())
        .opacity(bgDelay ? 1 : 0)
        //.animation(Animation.easeInOut(duration: 1.0).delay(0.3))
        .onAppear(perform: ({
            if self.auth.isUserAuthenticated == .signedOut {
                self.bgDelay = true
            } else {
                self.bgDelay = false
            }
        }))
    }
}

struct WalkthroughData: Identifiable {
    var id = UUID()
    var title: String
    var subtitle: String
    var image: String
}

var WalkthroughDataArray = [
    WalkthroughData(title: "Messaging \nReimagined", subtitle: "The most fun messaging experiance.\nSafe. Fun. & Free.", image: "WalkthroughImage1"),
    WalkthroughData(title: "The Most Fun", subtitle: "Send contacts fun messages using GIF's, Photos, or Quick Snaps!", image: "WalkthroughImage2"),
    WalkthroughData(title: "Fast & Reliable", subtitle: "Chatr uses the fastest servers to make it a seemless experiance", image: "WalkthroughImage3"),
    WalkthroughData(title: "Your Contacts \nAre Waiting", subtitle: "Contacts that have regristered are \nwaiting to for you to say hello 👋", image: "WalkthroughImage4")
]

// MARK: Main Home Body
struct MainBody: View {
    @EnvironmentObject var auth: AuthModel
    @State private var continuePermissions = false
    @State private var continuePt1: Bool = false
    @State private var continuePt2: Bool = false
    @State private var continuePt3: Bool = false
    @State private var continuePt4: Bool = false
    @State var contactsPermission: Bool = false
    @State var locationPermission: Bool = false
    @State var notificationPermission: Bool = false
    @State var photoPermission: Bool = false
    @State var cameraPermission: Bool = false
    @State var pageIndex: Int = 0
    @State var scrollOffset: CGFloat = CGFloat()
    @State var text: String = ""
    @State var textArea: String = "+1"
    @Binding var presentView: Bool
             
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading) {
                        Text("Welcome to")
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(Color("SoftTextColor"))
                        
                        Image("logo-word")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 38, alignment: .leading)
                    }
                    
                    Spacer()
                    Image("iconCoin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60, alignment: .center)
                        .shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 10)
                }.padding(.all, 30)
                .padding(.top, 10)

                Carousel(width: Constants.screenWidth, page: self.$pageIndex, scrollOffset: self.$scrollOffset, height: Constants.screenHeight - 250)
                    .disabled(self.continuePermissions || self.continuePt1 ? true : false)
                    .opacity(self.continuePermissions || self.continuePt1 ? 0.0 : 1.0)
                    .frame(width: Constants.screenWidth)
                    .offset(y: Constants.screenWidth == 375 ? -30 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                
                HStack(alignment: .center) {
                    PageControl(page: self.$pageIndex, color: "black")
                        .disabled(self.continuePermissions || self.continuePt1 ? true : false)
                        .padding(.leading)
                        .frame(minWidth: 35, idealWidth: 50, maxWidth: 75)
                        .animation(.spring(response: 0.45, dampingFraction: 0.45, blendDuration: 0))
 
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        if self.contactsPermission == true && self.locationPermission == true && self.photoPermission == true && self.notificationPermission == true && self.cameraPermission {
                            self.continuePt1.toggle()
                        } else {
                            self.continuePermissions.toggle()
                        }
                    }) {
                        HStack(alignment: .center, spacing: 15) {
                            Image("ChatBubble")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.semibold))
                                .frame(width: 28, height: 24, alignment: .center)

                            Text("Start Chatting")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }.padding(.horizontal, 10)
                     }.buttonStyle(MainButtonStyle())
                    .frame(maxWidth: 210)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.125), lineWidth: 2.5))
                    .disabled(self.continuePermissions || self.continuePt1 ? true : false)
                    .shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 10)
                }.padding(.horizontal, 25)
                .offset(y: self.continuePermissions || self.continuePt1 ? 150 : -44)
            }
            
            PermissionsView(continuePt1: self.$continuePt1, permisContinue: self.$continuePermissions, contactsPermission: self.$contactsPermission, locationPermission: self.$locationPermission, notificationPermission: self.$notificationPermission, photoPermission: self.$photoPermission, cameraPermission: self.$cameraPermission)
                .frame(minHeight: 240, idealHeight: 390, maxHeight: 470, alignment: .center)
                .frame(maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.top, 10)
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 0, y: 15)
                .offset(x: continuePermissions ? 0 : Constants.screenWidth, y: 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.45, blendDuration: 0))

            PhoneNumberView(continuePt1: $continuePt1, text: self.$text, textArea: self.$textArea)
                .environmentObject(self.auth)
                //.frame(minHeight: 240, idealHeight: 260, maxHeight: 270, alignment: .center)
                .frame(minWidth: 240, idealWidth: 320, maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 0, y: 15)
                .offset(x: continuePt1 ? 0 : Constants.screenWidth, y: 60)
                .offset(x:self.auth.verifyPhoneNumberStatus == .success ? -(Constants.screenWidth) : 0)
                .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                .KeyboardAwarePadding()
                .resignKeyboardOnDragGesture()


            VerifyNumberView(text: self.$text, textArea: self.$textArea)
                .environmentObject(self.auth)
                .frame(minHeight: 200, idealHeight: 210, maxHeight: 220, alignment: .center)
                .frame(maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 0, y: 15)
                .offset(x: self.auth.verifyPhoneNumberStatus == .success ? 0 : Constants.screenWidth, y: 75)
                .offset(x: self.auth.verifyCodeStatus == .success ? -(Constants.screenWidth) : 0)
                .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                .KeyboardAwarePadding()
                .resignKeyboardOnDragGesture()
            
            
            AddInfoView(continuePt4: self.$continuePt4)
                .environmentObject(self.auth)
                .frame(width: Constants.screenWidth - 50, height: 220, alignment: .center)
                .frame(maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 10, y: 15)
                .offset(x: self.auth.verifyCodeStatus == .success && self.auth.haveUserFullName == false ? 0 : self.continuePt4 ? 0 : Constants.screenWidth, y: 60)
                .offset(x: self.continuePt4 ? -(Constants.screenWidth) : 0, y: 0)
                .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                .KeyboardAwarePadding()
                .resignKeyboardOnDragGesture()
           
            
            AddProfileImageView(continuePt3: self.$continuePt3, continuePt4: self.$continuePt4, presentView: self.$presentView)
                .frame(width: Constants.screenWidth - 50, height: 235, alignment: .center)
                .frame(maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.top, 20)
                .padding(.bottom, 50)
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 0, y: 15)
                .offset(x: self.continuePt4 || (self.auth.haveUserProfileImg == false && self.auth.verifyCodeStatus == .success && self.auth.haveUserFullName == true) ? 0 : Constants.screenWidth, y: 10)
                .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                .resignKeyboardOnDragGesture()
            
            welcomeBackView(presentView: self.$presentView)
                .frame(width: Constants.screenWidth - 50, height: 225, alignment: .center)
                .frame(maxWidth: 400)
                .background(BlurView(style: .systemThinMaterial))
                .cornerRadius(30)
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color("blurBorder"), lineWidth: 2.5))
                .padding(.top, 20)
                .padding(.bottom, 50)
                .padding(.horizontal, 25)
                .shadow(color: Color("buttonShadow_Deeper"), radius: 15, x: 0, y: 15)
                .offset(x: self.auth.haveUserFullName == true && self.auth.haveUserProfileImg == true && self.auth.isFirstTimeUser == false && self.auth.verifyCodeStatus == .success ? 0 : Constants.screenWidth, y: 50)
                .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                .resignKeyboardOnDragGesture()
        }.ignoresSafeArea()
        .background(
            Image("Walkthrough BG1")
                .resizable()
                .scaledToFill()
                .offset(x: -60)
                .offset(x: -self.scrollOffset / 3)
                .offset(x: continuePermissions ? -50 : 0)
                .offset(x: continuePt1 ? -50 : 0)
                .offset(x: self.auth.verifyPhoneNumberStatus == .success ? -50 : 0)
                .offset(x: self.auth.haveUserFullName == true && self.auth.haveUserProfileImg == true && self.auth.isFirstTimeUser == false && self.auth.verifyCodeStatus == .success ? -50 : 0)
                .offset(x: self.continuePt4 || (self.auth.haveUserProfileImg == false && self.auth.verifyCodeStatus == .success) ? -50 : 0)
                .frame(width: Constants.screenWidth * 3.5, alignment: .leading)
                .animation(.spring(response: 0.6, dampingFraction: 0.45, blendDuration: 0.4))
                .zIndex(-1)
        )
    }
}

// MARK: Walkthrough Cell
struct WalkthroughCell: View, Identifiable {
    let id = UUID()
    @State var title : String
    @State var subTitleText : String
    @State var imageName : String

    var body: some View {
                ZStack(alignment: .bottom) {
                    Image(self.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(minHeight: Constants.screenHeight / 2.25)
                        .padding(.bottom, 75)

                    VStack(alignment: .center, spacing: 10) {
                        Text(self.title)
                            .font(.system(size: 30))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.primary.opacity(0.9))
                        
                        Text(self.subTitleText)
                            .font(.subheadline)
                            .foregroundColor(Color.primary.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }.padding(.vertical, 15)
                    .padding(.bottom, 10)
                    .padding(.horizontal)
                    .frame(minWidth: Constants.screenWidth / 2, maxWidth: Constants.screenWidth - 60, alignment: .center)
                    .background(
                        BlurView(style: .systemUltraThinMaterial)
                            .cornerRadius(25)
                            .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color("blurBorder"), lineWidth: 2.5))
                    ).shadow(color: Color("buttonShadow"), radius: 20, x: 0, y: 20)
                }.frame(width: Constants.screenWidth)
    }
}

// MARK: Permissions View
struct PermissionsView: View {
    @Binding var continuePt1: Bool
    @Binding var permisContinue: Bool
    @Binding var contactsPermission: Bool
    @Binding var locationPermission: Bool
    @Binding var notificationPermission: Bool
    @Binding var photoPermission: Bool
    @Binding var cameraPermission: Bool
    var locationManager: CLLocationManager = CLLocationManager()
    
    var body: some View {
        VStack {
            Text("Permissions")
                .font(.system(size: 28))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.primary)
                .padding(.top, 25)
            
            Text("To provide the best experience, please allow your contacts, photos, notifications, & location.")
                .font(.system(size: 12))
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
                .padding(.horizontal, 5)
            
            Spacer()

            Group {
            // MARK: Contacts
                HStack {
                    Image(systemName: "person.and.person")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 27)
                        .foregroundColor(.primary)
                        .padding(.trailing, 10)
                            
                    Text("Contacts")
                        .font(.none)
                        .fontWeight(.none)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()

                    Button(action: {
                        let store = CNContactStore()
                        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                            store.requestAccess(for: .contacts){succeeded, err in
                                guard err == nil && succeeded else {
                                    self.contactsPermission = false
                                    return
                                }
                                if succeeded {
                                    self.contactsPermission = true
                                }
                            }
                        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                            self.contactsPermission = true

                        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            self.contactsPermission = false
                        }
                    }) {
                     Text(self.contactsPermission ? "Allowed" : "Allow")
                           .padding([.top, .bottom], 10)
                           .padding([.leading, .trailing], 20)
                           .transition(.identity)
                     }.onAppear {
                        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                            self.contactsPermission = false
                        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
                            self.contactsPermission = true
                        }
                     }
                     .disabled(self.contactsPermission ? true : false)
                     .frame(height: 35)
                    .background(LinearGradient(gradient: Gradient(colors: !self.contactsPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                Divider()
            // MARK: Location
                HStack {
                    Image(systemName: "location")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 27)
                        .foregroundColor(.primary)
                        .padding(.trailing, 5)
                            
                    Text("Location")
                        .font(.none)
                        .fontWeight(.none)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                                    
                    Button(action: {
                        if self.locationPermission == false {
                            self.locationManager.requestAlwaysAuthorization()
                            self.locationPermission = true
                        }
                    }) {
                     Text(self.locationPermission ? "Allowed" : "Allow")
                            .padding([.top, .bottom], 10)
                            .padding([.leading, .trailing], 20)
                            .transition(.identity)
                      }
                      .disabled(self.locationPermission ? true : false)
                      .frame(height: 35)
                      .background(LinearGradient(gradient: Gradient(colors: !self.locationPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .onAppear(perform: {
                        if CLLocationManager.locationServicesEnabled() {
                            switch locationManager.authorizationStatus {
                                case .notDetermined, .restricted, .denied:
                                    print("No access to location")
                                    self.locationPermission = false
                                case .authorizedAlways, .authorizedWhenInUse:
                                    print("Access location true")
                                    self.locationPermission = true
                                @unknown default:
                                break
                            }
                        } else {
                            print("Location services are not enabled")
                            self.locationPermission = false
                        }
                    })
                }
                
                Divider()
            // MARK: Notification
                HStack {
                    Image(systemName: "bell")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 27)
                        .foregroundColor(.primary)
                        .padding(.trailing, 5)
                            
                    Text("Notifications")
                        .font(.none)
                        .fontWeight(.none)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        if self.notificationPermission == false {
                            print("allow access to noit")
                            if #available(iOS 10, *) {                                
                                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound, .carPlay], completionHandler: { (granted, error) in
                                    if error == nil {
                                        print("error with notification permissions")
                                        DispatchQueue.main.async(execute: {
                                            UIApplication.shared.registerForRemoteNotifications()
                                        })
                                        self.checkNotiPermission()
                                    }
                                })
                            } else {
                                let notificationSettings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
                                DispatchQueue.main.async(execute: {
                                    UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                                    UIApplication.shared.registerForRemoteNotifications()
                                })
                                self.checkNotiPermission()
                            }
                        }
                      }) {
                        Text(self.notificationPermission ? "Allowed" : "Allow")
                            .padding([.top, .bottom], 10)
                            .padding([.leading, .trailing], 20)
                            .transition(.identity)
                      }.onAppear {
                        self.checkNotiPermission()
                      }
                      .disabled(self.notificationPermission ? true : false)
                      .frame(height: 35)
                      .background(LinearGradient(gradient: Gradient(colors: !self.notificationPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                
                Divider()
                //MARK: Photo Library
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 27)
                        .foregroundColor(.primary)
                        .padding(.trailing, 5)
                         
                    Text("Photo Library")
                        .font(.none)
                        .fontWeight(.none)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()

                    Button(action: {
                        if self.photoPermission == false {
                          let photos = PHPhotoLibrary.authorizationStatus()
                          if photos == .notDetermined {
                              PHPhotoLibrary.requestAuthorization({ status in
                                  if status == .authorized {
                                    DispatchQueue.main.async(execute: {
                                        self.photoPermission = true
                                    })
                                  }
                              })
                          } else if photos == .authorized {
                            self.photoPermission = true
                          }
                        }
                    }) {
                     Text(self.photoPermission ? "Allowed" : "Allow")
                           .padding([.top, .bottom], 10)
                           .padding([.leading, .trailing], 20)
                           .transition(.identity)
                     }.onAppear {
                        let status = PHPhotoLibrary.authorizationStatus()
                        if (status == PHAuthorizationStatus.authorized) {
                            self.photoPermission = true
                        } else if (status == PHAuthorizationStatus.denied) {
                            self.photoPermission = false
                        }
                     }
                     .disabled(self.photoPermission ? true : false)
                     .frame(height: 35)
                    .background(LinearGradient(gradient: Gradient(colors: !self.photoPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                   .foregroundColor(.white)
                   .cornerRadius(20)
                }
                
                Divider()
                
                //MARK: Camera Library
                HStack {
                    Image(systemName: "camera")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 27)
                        .foregroundColor(.primary)
                        .padding(.trailing, 5)
                         
                    Text("Camera")
                        .font(.none)
                        .fontWeight(.none)
                        .foregroundColor(Color.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()

                    Button(action: {
                        if self.cameraPermission == false {
                            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                                if granted {
                                    self.cameraPermission = true
                                } else {
                                    self.cameraPermission = false
                                }
                            })
                        }
                    }) {
                        Text(self.cameraPermission ? "Allowed" : "Allow")
                            .padding([.top, .bottom], 10)
                            .padding([.leading, .trailing], 20)
                            .transition(.identity)
                    }.onAppear {
                        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                            self.cameraPermission = true
                        } else {
                            self.cameraPermission = false
                        }
                    }
                    .disabled(self.cameraPermission ? true : false)
                    .frame(height: 35)
                    .background(LinearGradient(gradient: Gradient(colors: !self.cameraPermission ? [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)] : [Color(red: 195 / 255, green: 195 / 255, blue: 195 / 255, opacity: 1.0), Color(.sRGB, red: 145 / 255, green: 145 / 255, blue: 145 / 255, opacity: 1.0)]), startPoint: .top, endPoint: .bottom))
                   .foregroundColor(.white)
                   .cornerRadius(20)
                }
            }
            
            Spacer()
            if self.notificationPermission == true && self.photoPermission == true && self.locationPermission == true && self.contactsPermission == true && self.cameraPermission == true {
                HStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.continuePt1.toggle()
                        self.permisContinue.toggle()
                    }) {
                        HStack(alignment: .center, spacing: 15) {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.semibold))
                                .frame(width: 20, height: 18, alignment: .center)
                        }.padding(.horizontal, 15)
                    }.buttonStyle(MainButtonStyle())
                    .frame(width: 170)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                }
            } else {
                HStack {
                    Spacer()
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.continuePt1.toggle()
                        self.permisContinue.toggle()
                     }) {
                        ZStack {
                            Text("Skip")
                                .italic()
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.all, 15)
                                .padding(.horizontal, 10)
                        }
                    }.buttonStyle(changeBGButtonStyleDisabled())
                }
            }
            Spacer()
        }.padding([.trailing, .leading], 20)
    }
    
    func checkNotiPermission() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                print("Noti permission is .notDermined")
                self.notificationPermission = false
            } else if settings.authorizationStatus == .denied {
                print("Noti permission is .denied")
                self.notificationPermission = false
            } else if settings.authorizationStatus == .authorized {
                print("Noti permission is .auth")
                self.notificationPermission = true
            }
        })
    }
}

// MARK: Phone Number View
struct PhoneNumberView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var continuePt1: Bool
    @Binding var text: String
    @Binding var textArea: String
    @State var doneSucess = false
    @State private var loadAni = false
    @State private var openTerms = false

    var body: some View {
        VStack(alignment: .center) {
            Text("Phone Number")
                .font(.system(size: 28))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.primary)
                .padding(.top, 25)
                .padding(.bottom, 2.5)
                .padding(.horizontal, 30)

            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                self.openTerms.toggle()
            }) {
                Text("By entering your phone number you are agreeing to our Terms of Service & Privacy Policy.")
                    .font(.system(size: 12))
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }.buttonStyle(ClickMiniButtonStyle())
            .padding(.bottom, 10)
            .sheet(isPresented: $openTerms) {
                NavigationView {
                    TermsView(mainText: Constants.termsOfService)
                        .navigationBarItems(leading:
                            Button(action: {
                                withAnimation {
                                    self.openTerms.toggle()
                                }
                            }) {
                                Text("Done")
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                            })
                }
            }
                        
            HStack {
                TextField("", text: $textArea)
                    .keyboardType(.numberPad)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 70, height: 50)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .background(Color("bgColor"))
                    .cornerRadius(18)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5)
                    .onAppear() {
                        self.textArea = getCountryCode()
                    }

                ZStack {
                    PhoneNumberTextFieldView(text: $text, isFirstResponder: $continuePt1, doneSuccess: $doneSucess)
                        .environmentObject(self.auth)
                        .frame(height: 50)
                        .lineLimit(1)
                        .padding(.leading)
                }.background(Color("bgColor"))
                .cornerRadius(18)
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5)
                
            }.padding(.horizontal, 25)
            
            if auth.verifyPhoneNumberStatus == .success {
               Text("Success")
                   .padding(20)
                   .foregroundColor(Color.white)
            } else if auth.verifyPhoneNumberStatus == .loading {
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 25, height: 25)
                    .rotationEffect(.init(degrees: self.loadAni ? 360 : 0))
                    .padding(.vertical, 10)
                    .padding(.bottom, 30)
                    .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))
                    .onAppear(perform: ({
                        self.loadAni.toggle()
                    }))
            } else if auth.verifyPhoneNumberStatus == .error {
                Text("error, please try again")
                    .font(.footnote)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 2)
                    .padding(.bottom, self.text.count >= 5 ? 0 : 10)
                    .foregroundColor(Color.secondary)
                    .onAppear {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.continuePt1 = true
                    }
                
                if self.text.count >= 5 {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                       self.auth.sendVerificationNumber(numberText: self.textArea + self.text)
                   }) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Verify")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 18, alignment: .center)
                        }.padding(.horizontal)
                    }.buttonStyle(MainButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                }
            } else if auth.verifyPhoneNumberStatus == .undefined || auth.verifyPhoneNumberStatus == .error {
                if self.text.count >= 5 {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                       self.auth.sendVerificationNumber(numberText: self.textArea + self.text)
                   }) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Verify")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 18, alignment: .center)
                        }.padding(.horizontal)
                    }.buttonStyle(MainButtonStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .padding(.bottom)
                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                } else {
                    Button(action: {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                   }) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("Verify")
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.medium))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 18, alignment: .center)
                        }.padding(.horizontal)
                    }.buttonStyle(MainButtonStyleDeselected())
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .padding(.bottom)
                }
            } else {
              Text("Verify")
                  .fontWeight(.medium)
                  .padding(.horizontal , 20)
                  .foregroundColor(Color.white)
          }
        }
    }
}

func getCountryCode() -> String {
    guard let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders, let countryCode = carrier.first?.value.isoCountryCode else { return "+1" }
    let prefixCodes = ["AF": "93", "AE": "971", "AL": "355", "AN": "599", "AS":"1", "AD": "376", "AO": "244", "AI": "1", "AG":"1", "AR": "54","AM": "374", "AW": "297", "AU":"61", "AT": "43","AZ": "994", "BS": "1", "BH":"973", "BF": "226","BI": "257", "BD": "880", "BB": "1", "BY": "375", "BE":"32","BZ": "501", "BJ": "229", "BM": "1", "BT":"975", "BA": "387", "BW": "267", "BR": "55", "BG": "359", "BO": "591", "BL": "590", "BN": "673", "CC": "61", "CD":"243","CI": "225", "KH":"855", "CM": "237", "CA": "1", "CV": "238", "KY":"345", "CF":"236", "CH": "41", "CL": "56", "CN":"86","CX": "61", "CO": "57", "KM": "269", "CG":"242", "CK": "682", "CR": "506", "CU":"53", "CY":"537","CZ": "420", "DE": "49", "DK": "45", "DJ":"253", "DM": "1", "DO": "1", "DZ": "213", "EC": "593", "EG":"20", "ER": "291", "EE":"372","ES": "34", "ET": "251", "FM": "691", "FK": "500", "FO": "298", "FJ": "679", "FI":"358", "FR": "33", "GB":"44", "GF": "594", "GA":"241", "GS": "500", "GM":"220", "GE":"995","GH":"233", "GI": "350", "GQ": "240", "GR": "30", "GG": "44", "GL": "299", "GD":"1", "GP": "590", "GU": "1", "GT": "502", "GN":"224","GW": "245", "GY": "595", "HT": "509", "HR": "385", "HN":"504", "HU": "36", "HK": "852", "IR": "98", "IM": "44", "IL": "972", "IO":"246", "IS": "354", "IN": "91", "ID":"62", "IQ":"964", "IE": "353","IT":"39", "JM":"1", "JP": "81", "JO": "962", "JE":"44", "KP": "850", "KR": "82","KZ":"77", "KE": "254", "KI": "686", "KW": "965", "KG":"996","KN":"1", "LC": "1", "LV": "371", "LB": "961", "LK":"94", "LS": "266", "LR":"231", "LI": "423", "LT": "370", "LU": "352", "LA": "856", "LY":"218", "MO": "853", "MK": "389", "MG":"261", "MW": "265", "MY": "60","MV": "960", "ML":"223", "MT": "356", "MH": "692", "MQ": "596", "MR":"222", "MU": "230", "MX": "52","MC": "377", "MN": "976", "ME": "382", "MP": "1", "MS": "1", "MA":"212", "MM": "95", "MF": "590", "MD":"373", "MZ": "258", "NA":"264", "NR":"674", "NP":"977", "NL": "31","NC": "687", "NZ":"64", "NI": "505", "NE": "227", "NG": "234", "NU":"683", "NF": "672", "NO": "47","OM": "968", "PK": "92", "PM": "508", "PW": "680", "PF": "689", "PA": "507", "PG":"675", "PY": "595", "PE": "51", "PH": "63", "PL":"48", "PN": "872","PT": "351", "PR": "1","PS": "970", "QA": "974", "RO":"40", "RE":"262", "RS": "381", "RU": "7", "RW": "250", "SM": "378", "SA":"966", "SN": "221", "SC": "248", "SL":"232","SG": "65", "SK": "421", "SI": "386", "SB":"677", "SH": "290", "SD": "249", "SR": "597","SZ": "268", "SE":"46", "SV": "503", "ST": "239","SO": "252", "SJ": "47", "SY":"963", "TW": "886", "TZ": "255", "TL": "670", "TD": "235", "TJ": "992", "TH": "66", "TG":"228", "TK": "690", "TO": "676", "TT": "1", "TN":"216","TR": "90", "TM": "993", "TC": "1", "TV":"688", "UG": "256", "UA": "380", "US": "1", "UY": "598","UZ": "998", "VA":"379", "VE":"58", "VN": "84", "VG": "1", "VI": "1","VC":"1", "VU":"678", "WS": "685", "WF": "681", "YE": "967", "YT": "262","ZA": "27" , "ZM": "260", "ZW":"263"]
    let countryDialingCode = prefixCodes[countryCode.uppercased()] ?? "+1"
    return "+" + countryDialingCode
}

// MARK: Verify Phone Number View
struct VerifyNumberView: View {
    @EnvironmentObject var auth: AuthModel
    @State private var loadAni = false
    @State var textCode = ""
    @Binding var text: String
    @Binding var textArea: String
        
    var body: some View {
        ZStack(alignment: .center) {
            VStack(alignment: .center) {
                Text("Verify Phone Number")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)
                    .padding(.top, 30)
                    .padding([.trailing, .leading], 20)

                Text("Enter the 6 digit code sent to \n\(self.textArea) \(text.format(phoneNumber: String(text.dropFirst())))")
                    .font(.system(size: 12))
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
                    .padding(.horizontal, 30)

                Spacer()
                if auth.verifyCodeStatus == .success {
                    Text("Success")
                        .font(.footnote)
                        .padding([.trailing, .leading], 20)
                        .foregroundColor(Color.secondary)
                } else if auth.verifyCodeStatus == .error {
                    VerifyCodeTextFieldView(text: $textCode, isFirstResponder: $auth.verifyPhoneStatusKeyboard)
                        .environmentObject(self.auth)
                        .cornerRadius(18)
                        .frame(height: 50)
                        .lineLimit(1)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5)
                        .padding([.leading, .trailing], 30)
                    
                    Text("error, please try again")
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .foregroundColor(Color.secondary)
                        .onAppear() {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                } else if auth.verifyCodeStatus == .loading {
                    Text("verifying...")
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .foregroundColor(Color.secondary)
                        .animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
                } else {
                    VerifyCodeTextFieldView(text: $textCode, isFirstResponder: $auth.verifyPhoneStatusKeyboard)
                        .environmentObject(self.auth)
                        .cornerRadius(18)
                        .frame(height: 50)
                        .lineLimit(1)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 30)
                }
                
//                Circle()
//                    .trim(from: 0, to: 0.8)
//                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
//                    .frame(width: auth.verifyCodeStatus == .loading ? 25 : 0, height: auth.verifyCodeStatus == .loading ? 25 : 0)
//                    .rotationEffect(.init(degrees: auth.verifyCodeStatus == .loading ? 360 : 0))
//                    .opacity(auth.verifyCodeStatus == .loading ? 1 : 0)
//                    .animation(Animation.linear(duration: 0.55).repeatForever(autoreverses: false))

                Button(action: {
                    self.auth.verifyPhoneNumberStatus = .undefined
                    self.auth.verifyCodeStatus = .undefined
                }) {
                    ZStack {
                       Text("new number")
                            .underline()
                            .font(.footnote)
                            .foregroundColor(Color.secondary)
                            .padding(.top, 10)
                            .multilineTextAlignment(.center)
                    }
                }.disabled(auth.verifyCodeStatus == .error || auth.verifyCodeStatus == .undefined ? false : true)
                Spacer()
            }.animation(.spring(response: 0.48, dampingFraction: 0.45, blendDuration: 0))
        }
    }
}

// MARK: Add Info / Name View
struct AddInfoView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var continuePt4: Bool
    @State var firstNameFilled: Bool = false
    @State var loadingSetName: Bool = false
    @State var text = ""

    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack(alignment: .center) {
                    Text("What's your name?")
                        .font(.system(size: 28))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.primary)
                        .padding(.top, 30)
                        .padding([.trailing, .leading], 20)

                    Spacer()
                    
                    FullNameFieldView(text: self.$text, isFirstResponder: self.$auth.verifyCodeStatusKeyboard)
                        .environmentObject(self.auth)
                        .cornerRadius(18)
                        .frame(height: 50)
                        .frame(maxWidth: 325)
                        .lineLimit(1)
                        .padding([.trailing, .leading], 20)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                    
                    if self.text.count > 3 && self.loadingSetName == false {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.loadingSetName = true
                            self.auth.updateFullName(phoneNumber: UserDefaults.standard.string(forKey: "phoneNumber")  ?? "", fullName: self.text.trimmingCharacters(in: .whitespacesAndNewlines), completion: { result in
                                if result != true {
                                    self.auth.haveUserFullName = false
                                    self.loadingSetName = false
                                }
                                //success
                                UIApplication.shared.endEditing(true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    self.auth.haveUserFullName = true
                                    self.continuePt4 = true
                                    self.loadingSetName = false
                                }
                            })
                        }) {
                            HStack(alignment: .center, spacing: 10) {
                                Text("Set Name")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .scaledToFit()
                                    .font(Font.title.weight(.semibold))
                                    .frame(width: 20, height: 18, alignment: .center)
                            }.padding(.horizontal, 15)
                        }.buttonStyle(MainButtonStyle())
                        .frame(width: 170)
                        .disabled(loadingSetName ? true : false)
                        .padding(.horizontal)
                        .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                    } else {
                        Button(action: {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                       }) {
                            HStack(alignment: .center, spacing: 10) {
                                Text(self.loadingSetName ? "Setting Name" : "Set Name")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("disabledButton"))
                                
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .scaledToFit()
                                    .font(Font.title.weight(.medium))
                                    .frame(width: 20, height: 18, alignment: .center)
                            }.padding(.horizontal, 15)
                        }.buttonStyle(MainButtonStyleDeselected())
                        .frame(width: 170)
                        .padding(.horizontal)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: Add Profile Image View
struct AddProfileImageView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @EnvironmentObject var auth: AuthModel
    @Binding var continuePt3: Bool
    @Binding var continuePt4: Bool
    @Binding var presentView: Bool

    @State var showImagePicker: Bool = false
    @State private var image: Image? = nil
    @State private var inputImage: UIImage? = nil

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                Spacer()
                Text("Choose Avatar")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                ZStack {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        withAnimation {
                            self.showImagePicker = true
                        }
                    }) {
                        ZStack {
                            BlurView(style: .prominent)
                                .frame(width: 110, height: 110, alignment: .center)
                                .cornerRadius(55)
                                .shadow(color: Color("buttonShadow_Deeper"), radius: 20, x: 0, y: 20)
                            
                            Circle()
                                .trim(from: 0, to: self.auth.avatarProgress)
                                .stroke(Color.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .foregroundColor(Color.primary)
                                .opacity(self.auth.avatarProgress == 0.0 || self.auth.avatarProgress == 1.0 ? 0.0 : 0.75)
                                .frame(width: 102, height: 102)

                            Circle()
                                .foregroundColor(Color("bgColor"))
                                .opacity(0.8)
                               .frame(width: 90, height: 90, alignment: .center)
                               .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                            
                            if (image == nil) {
                                VStack {
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 27, height: 25, alignment: .center)
                                    
                                    Text("tap to upload")
                                       .font(.system(size: 10))
                                       .fontWeight(.regular)
                                       .multilineTextAlignment(.center)
                                       .foregroundColor(Color.secondary)
                                }
                             }
                        }
                    }.buttonStyle(ClickButtonStyle())
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker22(sourceType: .photoLibrary) { (imageUrl, img) in
                            if let image = img {
                                self.image = Image(uiImage: image)
                            }

                            self.auth.uploadFile(imageUrl, completionHandler: { imageId in
                                self.auth.setUserAvatar(imageId: imageId, oldLink: "", completion: { success in
                                    print("DONEEE SETTING UP URL! \(success)")
                                })
                            })
                        }
                    }
                    
                    image?.resizable().scaledToFill().clipped().frame(width: 90, height: 90).cornerRadius(45)
                    .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                }
                 
                Spacer()
                
                Button(action: {
                    //UIApplication.shared.endEditing(true)
                    //self.auth.isUserAuthenticated = .signedIn
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.presentView = false
                    //self.presentationMode.wrappedValue.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.auth.preventDismissal = false
                        self.auth.isUserAuthenticated = .signedIn
                    }
                }) {
                    ZStack {
                        Text("Skip")
                            .font(.system(size: 14))
                            .font(.caption)
                            .underline()
                            .italic()
                            .disabled(self.auth.avatarProgress == 0.0 ? false : true)
                            .opacity(self.auth.avatarProgress == 0.0 ? 1 : 0)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.secondary)
                    }
                }.buttonStyle(ClickButtonStyle())
                .padding(.all, 15)
                .frame(height: 25)

                Spacer()
            }
        }
    }
}

// MARK: Welcome Back View
struct welcomeBackView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var auth: AuthModel
    @State var loadAni: Bool = false
    @State var dismissView: Bool = false
    @Binding var presentView: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                Spacer()
                Text("Welcome Back!")
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.primary)
                    .padding(.top, 25)
                    .padding([.trailing, .leading], 20)

                Spacer()
                HStack(alignment: .center) {
                    WebImage(url: URL(string: self.auth.profile.results.first?.avatar ?? ""))
                        .resizable()
                        .placeholder{ Image(systemName: "person.fill") }
                        .indicator(.activity)
                        .transition(.fade(duration: 0.25))
                        .scaledToFill()
                        .frame(width: 55, height: 55, alignment: .center)
                        .clipShape(Circle())
                        .padding(.leading)
                    
                    VStack(alignment: .leading) {
                        Text(self.auth.haveUserFullName == true ? self.auth.profile.results.first?.fullName ?? "Chatr User" : "Chatr User")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(UserDefaults.standard.string(forKey: "phoneNumber")?.format(phoneNumber: String(UserDefaults.standard.string(forKey: "phoneNumber")?.dropFirst().dropFirst() ?? "+1 (123) 456-6789")) ?? "+1 (123) 456-6789")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                        
                    if self.auth.haveUserFullName && self.auth.haveUserProfileImg {
                        Text("")
                            .onAppear() {
                                guard !self.loadAni else { return }

                                self.loadAni = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                                    if self.auth.isFirstTimeUser == false {
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    }
                                    self.dismissView = true
                                    self.loadAni = false
                                }
                            }
                    }
                }.padding(.all)
                .background(RoundedRectangle(cornerRadius: 20)
                            .frame(height: 75)
                            .frame(minWidth: 100)
                            .padding(.all)
                            .cornerRadius(10)
                            .foregroundColor(Color("bgColor").opacity(0.45))
                            .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5))
                
                Text("Preparing your experience...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .offset(y: -5)
                
                Spacer()
                
                if self.dismissView {
                    Text("")
                        .onAppear() {
                            if self.auth.profile.results.first?.id != 0 {
                                self.presentView = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    self.auth.preventDismissal = false
                                    self.auth.isUserAuthenticated = .signedIn
                                    changeContactsRealmData.shared.observeQuickSnaps()
                                }
                            }
                        }
                }
                /*
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        self.auth.preventDismissal = false
                        self.auth.isUserAuthenticated = .signedIn
                    }
                }) {
                    Text("Start Chatting")
                        .fontWeight(.medium)
                        .foregroundColor(Color.white)
                }
                .buttonStyle(MainButtonStyle())
                .padding(.horizontal, 45)
                .frame(height: 40)
                .frame(maxWidth: 300)
                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                .padding(.bottom)
                
                Spacer()
                 */
            }
        }
    }
}

//MARK: Carousel View
struct Carousel : UIViewRepresentable {
    var width : CGFloat
    @Binding var page : Int
    @Binding var scrollOffset : CGFloat
    var height : CGFloat
    
    func makeCoordinator() -> Coordinator {
        return Carousel.Coordinator(parent1: self)
    }

    func makeUIView(context: Context) -> UIScrollView{
        // ScrollView Content Size...
        let total = width * CGFloat(WalkthroughDataArray.count)
        let view = UIScrollView()
        view.isPagingEnabled = true
        //1.0  For Disabling Vertical Scroll....
        view.contentSize = CGSize(width: total, height: 1.0)
        view.bounces = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.delegate = context.coordinator
        
        // Now Going to  embed swiftUI View Into UIView...
        let view1 = UIHostingController(rootView: ListView(page: self.$page))
        view1.view.frame = CGRect(x: 0, y: 0, width: total, height: self.height)
        view1.view.backgroundColor = .clear
        view.addSubview(view1.view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) { }
    
    class Coordinator : NSObject,UIScrollViewDelegate{
        var parent : Carousel
        
        init(parent1: Carousel) {
            parent = parent1
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Using This Function For Getting Currnet Page
        
            let page = Int(scrollView.contentOffset.x / UIScreen.main.bounds.width)
            self.parent.page = page
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.parent.scrollOffset = scrollView.contentOffset.x
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            let page = Int(scrollView.contentOffset.x / UIScreen.main.bounds.width)
            self.parent.page = page
        }
    }
}

//MARK: Walkthrough List
struct ListView : View {
    @Binding var page : Int
    var walkthroughData = WalkthroughDataArray
    
    var body: some View{
        HStack(spacing: 0){
            ForEach(walkthroughData) { i in
                WalkthroughCell(title: i.title, subTitleText: i.subtitle, imageName: i.image)
                    .frame(width: Constants.screenWidth)
                    .padding(.top)
                    .padding(.bottom, 100)
            }
        }
    }
}

//MARK: UIPageControl
struct PageControl : UIViewRepresentable {
    @Binding var page : Int
    @State var color: String = ""
    
    func makeUIView(context: Context) -> UIPageControl {
        let view = UIPageControl()
        if self.color == "white" {
            view.currentPageIndicatorTintColor = .white
            view.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
        } else {
            view.currentPageIndicatorTintColor = UIColor(named: "SoftTextColor")
            view.pageIndicatorTintColor = UIColor(named: "SoftTextColor")?.withAlphaComponent(0.2)
        }
        view.numberOfPages = WalkthroughDataArray.count
        return view
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        // Updating Page Indicator When Ever Page Changes....
        DispatchQueue.main.async {
            uiView.currentPage = self.page
        }
    }
}

// MARK: Keyboard Aware Modifier
struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    private var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue }
                .map { $0.cgRectValue.height },
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
       ).eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight - 20)
            .onReceive(keyboardHeightPublisher) { self.keyboardHeight = $0 }
            .animation(.spring(response: 0.45, dampingFraction: 0.6, blendDuration: 0))
    }
}

extension View {
    func KeyboardAwarePadding() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAwareModifier())
    }
}
