//
//  ShareProfileView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/11/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import FirebaseDynamicLinks
import CarBode
import SDWebImageSwiftUI
import AVFoundation

struct ShareProfileView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dimissView: Bool
    @State var contactID: Int
    @State var contactFullName: String
    @State var contactAvatar: String
    @State var shareURL = ""
    @State var barcodeType = CBBarcodeView.BarcodeType.qrCode
    @State var rotate = CBBarcodeView.Orientation.up
    @State var torchIsOn = false
    @State var foundUser = false
    @State var hideQrCode = false
    
    var body: some View {
        ZStack {
            //MARK: Camera View
            ZStack(alignment: .center) {
                ZStack(alignment: .bottomTrailing) {
                    CBScanner(supportBarcode: .constant([.qr, .code128]), torchLightIsOn: self.$torchIsOn, scanInterval: .constant(0.5)) {
                        if self.foundUser == false {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.foundUser = true
                            
                            //print("have received incoming link!: \(String(describing: URL(string: $0)))")
                            DynamicLinks.dynamicLinks().handleUniversalLink((URL(string: String(describing: $0)) ?? URL(string: ""))!, completion: { (dynamicLink, error) in
                                guard error == nil else {
                                    print("found erre: \(String(describing: error?.localizedDescription))")
                                    return
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.75) {
                                    if let dynamicLink = dynamicLink {
                                        self.auth.handleIncomingDynamicLink(dynamicLink)
                                    }
                                }
                            })
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity)
                    .frame(minHeight: 0, maxHeight: .infinity)
                    .foregroundColor(Color("bgColor"))
                    
                    HStack {
                        Button(action: {
                            self.torchIsOn.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            ZStack {
                                BlurView(style: .systemUltraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(15)
                                    .foregroundColor(Color("bgColor"))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                
                                Image(systemName: self.torchIsOn ? "lightbulb.fill" : "lightbulb.slash.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.primary)
                                    .frame(width: 25, height: 25, alignment: .center)
                            }
                        }.buttonStyle(ClickMiniButtonStyle())
                        
                        Button(action: {
                            self.hideQrCode.toggle()
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            ZStack(alignment: .center) {
                                BlurView(style: .systemUltraThinMaterial)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(15)
                                    .foregroundColor(Color("bgColor"))
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                
                                Image(systemName: self.hideQrCode ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.primary)
                                    .frame(width: 22, height: 22, alignment: .center)
                            }
                        }.buttonStyle(ClickMiniButtonStyle())
                    }.padding(.vertical, 30)
                    .padding(.horizontal, 20)
                }
                
                VStack() {
                    if self.foundUser {
                        VStack {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55, alignment: .center)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                                .padding(.bottom, 10)
                            
                            Text("Found Contact!")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                                
                            Text("redirecting shortly...")
                                .font(.subheadline)
                                .fontWeight(.none)
                                .foregroundColor(.white)
                                .opacity(0.8)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                        }.offset(y: -100)
                        .onAppear() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                self.foundUser = false
                                withAnimation {
                                    self.dimissView.toggle()
                                }
                            }
                        }
                    }
                }.opacity(self.foundUser ? 1 : 0)
                .animation(.linear)
            }
            
            //MARK: QR Code
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    ZStack(alignment: .bottom) {
                        ZStack {
                            Rectangle()
                                .frame(width: 240, height: 240)
                                .cornerRadius(25)
                                .foregroundColor(Color.white)
                                .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 10)
                            
                            CBBarcodeView(data: self.$shareURL, barcodeType: self.$barcodeType, orientation: self.$rotate, onGenerated: { _ in })
                                .frame(width: 225, height: 225)
                                .padding(.all, 10)
                            
                            Circle()
                                .foregroundColor(Color("bgColor"))
                                .frame(width: 65, height: 65, alignment: .center)
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
                            
                            Image("iconCoin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 55, height: 55, alignment: .center)
                        }.animation(.spring(response: 0.45, dampingFraction: 0.60, blendDuration: 0))
                        .onTapGesture() {
                            self.hideQrCode.toggle()
                            print("show qr \(geo.frame(in: .global).maxY)")
                        }
                        
                        ZStack(alignment: .center) {
                            BlurView(style: .systemUltraThinMaterial)
                                .frame(minWidth: 175, idealWidth: 200, maxWidth: 220)
                                .frame(height: 45)
                                .cornerRadius(15)
                                .foregroundColor(Color("bgColor"))
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                            
                            HStack(alignment: .center) {
                                if self.auth.isUserAuthenticated == .signedIn {
                                    WebImage(url: URL(string: self.contactAvatar))
                                        .resizable()
                                        .placeholder{ Image(systemName: "person.fill") }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 35, height: 35, alignment: .center)
                                        .padding(.vertical, 10)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                }
                                
                                VStack(alignment: .leading) {
                                    HStack(alignment: .center, spacing: 3) {
                                        if self.auth.subscriptionStatus == .subscribed {
                                            Image(systemName: "checkmark.seal")
                                                .resizable()
                                                .scaledToFit()
                                                .font(Font.title.weight(.semibold))
                                                .frame(width: 18, height: 18, alignment: .center)
                                                .foregroundColor(Color("main_blue"))
                                        }
                                        
                                        Text(self.contactFullName)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)
                                    }.offset(y: self.auth.subscriptionStatus == .subscribed ? 3 : 0)
                                    
                                    Text(UserDefaults.standard.string(forKey: "phoneNumber")?.format(phoneNumber: String(UserDefaults.standard.string(forKey: "phoneNumber")?.dropFirst().dropFirst() ?? "+1 (123) 456-6789")) ?? "+1 (123) 456-6789")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .offset(y: self.auth.subscriptionStatus == .subscribed ? -3 : 0)
                                }
                            }.frame(minWidth: 175, idealWidth: 200, maxWidth: 220)
                        }.offset(y: 35)
                    }.padding(.bottom, 30)
                    .scaleEffect(self.hideQrCode ? 0.5 : 1.0)
                    .transition(AnyTransition.opacity)
                    .opacity(self.shareURL != "" ? 1 : 0)
                    .offset(x: self.hideQrCode ? -geo.frame(in: .global).minX - 100 : 0, y: self.hideQrCode ? geo.frame(in: .global).maxY - 275 : geo.frame(in: .global).maxY / 2.33)
                    
                }.frame(width: Constants.screenWidth)
                .navigationBarTitle("Share Profile")
                .background(Color.clear)
                .edgesIgnoringSafeArea(.all)
                .animation(.spring(response: 0.35, dampingFraction: 0.60, blendDuration: 0))
                .onAppear {
                    self.getURLLink()
                }
            }
        }.edgesIgnoringSafeArea(.all)
        .disabled(self.foundUser ? true : false)
    }

    func getURLLink() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.chatr-messaging.com"
        components.path = "/contact"
        
        let recipeIDQueryItem = URLQueryItem(name: "contactID", value: self.contactID.description)
        components.queryItems = [recipeIDQueryItem]
        
        print("I am sharing this new link: \(String(describing: components.url?.absoluteString))")
        
        guard let shareLink = DynamicLinkComponents.init(link: (components.url ?? URL(string: ""))!, domainURIPrefix: "https://chatrmessaging.page.link") else {
            print("can't make FDL componcets")
            return
        }
        if let myBundleId = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        //shareLink.iOSParameters?.appStoreID = ""
        shareLink.socialMetaTagParameters?.title = "\(self.contactFullName)'s Profile"
        shareLink.socialMetaTagParameters?.descriptionText = "\(self.contactFullName) shared their contact with you!"
        shareLink.socialMetaTagParameters?.imageURL = URL(string: self.contactAvatar)
        
        let longurl = shareLink.url
        print("the long dynamic link is: \(String(describing: longurl?.absoluteString))")
        
        shareLink.shorten(completion: { (url, warnings, error) in
            if error != nil {
                print("oh no we have an error: \(String(describing: error?.localizedDescription))")
            }
            if let warnings = warnings {
                for warning in warnings {
                    print("FDL warning: \(warning)")
                }
            }
            guard let url = url else { return }
            print("I have a short URL to share: \(url.absoluteString)")
            self.shareURL = url.absoluteString
        })
    }
}
