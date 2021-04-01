//
//  ShareProfileView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/11/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import RealmSwift
import FirebaseDynamicLinks
import CarBode
import Social
import SDWebImageSwiftUI
import AVFoundation
import SCSDKCreativeKit
import SlideOverCard

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
    @State var showShared = false
    @State var hasCopiedUrl = false
    @State var openScan = false
    @State var showingTwitter = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
             VStack {
                //MARK: QR Code
                ZStack(alignment: .center) {
                    if !foundUser {
                        VStack {
                            Image(systemName: "qrcode")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.primary)
                                .padding(10)

                            Text("loading QR code...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ZStack(alignment: .bottom) {
                        ZStack {
                            Rectangle()
                                .frame(width: 275, height: 275)
                                .cornerRadius(40)
                                .foregroundColor(Color.white)
                                .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 12)
                            
                            CBBarcodeView(data: self.$shareURL, barcodeType: self.$barcodeType, orientation: self.$rotate, onGenerated: { _ in })
                                .frame(width: 225, height: 225)
                                .padding(.all, 25)
                            
                            Circle()
                                .foregroundColor(Color("bgColor"))
                                .frame(width: 65, height: 65, alignment: .center)
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
                            
                            Image("iconCoin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58, alignment: .center)
                        }.animation(.spring(response: 0.45, dampingFraction: 0.60, blendDuration: 0))
                        
                        ZStack(alignment: .center) {
                            BlurView(style: .systemUltraThinMaterial)
                                .frame(minWidth: 175, idealWidth: 200, maxWidth: 220)
                                .frame(height: 54)
                                .cornerRadius(15)
                                .foregroundColor(Color("bgColor"))
                                .shadow(color: Color.white.opacity(0.1), radius: 6, x: 0, y: 2)
                                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)
                            
                            HStack(alignment: .center) {
                                if self.auth.isUserAuthenticated == .signedIn {
                                    WebImage(url: URL(string: self.contactAvatar))
                                        .resizable()
                                        .placeholder{ Image(systemName: "person.fill") }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 38, height: 38, alignment: .center)
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
                    .opacity(self.shareURL != "" ? 1 : 0)
                }.padding(.top)

                //MARK: Copy Link
                HStack {
                    Text("PROFILE LINK:")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .offset(y: 2)
                    Spacer()
                }.padding(.top)
                
                HStack() {
                    HStack {
                        Image("linkIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                            .padding(.leading, 10)
                        
                        Text(self.shareURL)
                            .foregroundColor(.primary)
                            .font(.system(size: 16))
                            .lineLimit(1)
                            .padding(.vertical, 15)
                            .padding(.trailing, 10)
                    }.foregroundColor(.gray)
                    .background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
                    .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 8)
                    
                    Button(action: {
                        if self.hasCopiedUrl {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            UIPasteboard.general.setValue(self.shareURL, forPasteboardType: kUTTypePlainText as String)
                            self.hasCopiedUrl = true
                        }
                    }) {
                        Image(systemName: hasCopiedUrl ? "checkmark" : "doc.on.doc")
                            .resizable()
                            .scaledToFit()
                            .padding(Constants.menuBtnSize * 0.25)
                            .padding(.horizontal, 2)
                            .foregroundColor(.primary)
                    }.buttonStyle(HomeButtonStyle())
                }.padding(.horizontal)
                .padding(.bottom)
                
                
                //MARK: Action Buttons
                HStack(alignment: .center, spacing: 20) {
                    Button(action: {
                        let photo = SCSDKSnapPhoto(imageUrl: URL(string: "https://homepages.cae.wisc.edu/~ece533/images/frymire.png")!)
                        let snap = SCSDKPhotoSnapContent(snapPhoto: photo)
                        let sticker = SCSDKSnapSticker(stickerImage: #imageLiteral(resourceName: "iconCoin"))
                        snap.sticker = sticker
                        snap.caption = "Add me on Chatr! It's a simple, fun, & secure messaging app we can use to message eachother for FREE! Download at: " + Constants.appStoreLink
                        snap.attachmentUrl = self.shareURL
                        
                        SCSDKSnapAPI().startSending(snap, completionHandler: { error in
                            print("Shared \(self.shareURL)) on SnapChat.")
                            if let error = error {
                                print(error.localizedDescription)
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        })
                    }) {
                        VStack {
                            Image("snapchatIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30, alignment: .center)
                                .foregroundColor(.white)

                            Text("Snapchat")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }.frame(width: 100, height: 75, alignment: .center)
                        .background(Color(red: 255/255, green: 252/255, blue: 0/255, opacity: 1.0))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                        .shadow(color: Color(red: 255/255, green: 252/255, blue: 0/255, opacity: 0.3), radius: 20, x: 0, y: 10)
                    }.buttonStyle(ClickButtonStyle())
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.shareBackgroundImage()
                    }) {
                        VStack {
                            Image("instagramIcon_black")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30, alignment: .center)
                                .foregroundColor(.white)
                            
                            Text("Instagram")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }.frame(width: 100, height: 75, alignment: .center)
                        .background(Color("buttonColor"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                    }.buttonStyle(ClickButtonStyle())
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.openScan.toggle()
                    }) {
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30, alignment: .center)
                                .foregroundColor(.white)

                            Text("Scan QR")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }.frame(width: 100, height: 75, alignment: .center)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 6)
                    }.buttonStyle(ClickButtonStyle())
                }.padding(.all)
                .frame(width: Constants.screenWidth)

                FooterInformation()
                    .padding(.top, 80)
                    .padding(.bottom)
                
            }.frame(width: Constants.screenWidth)
        }.navigationBarTitle("Share Profile", displayMode: .automatic)
        .animation(.spring(response: 0.35, dampingFraction: 0.60, blendDuration: 0))
        .navigationBarItems(trailing:
            Button(action: {
                withAnimation {
                    self.showShared.toggle()
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.trailing, 5)
                    .font(Font.system(size: 22, weight: .regular))
                    .foregroundColor(.primary)
            }.disabled(self.foundUser ? false : true)
        ).onAppear {
            self.getURLLink()
        }.sheet(isPresented: self.$showShared) {
            ShareSheet(activityItems: [URL(string: self.shareURL)!])
        }.slideOverCard(isPresented: $openScan, onDismiss: {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }) {
            VStack(alignment: .center) {
                Text("Scan QR Code")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .offset(y: -20)

                Text("Scan any Chatr QR code to open to the profile.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .offset(y: -10)

                ScanQRView(dimissView: self.$dimissView)
                    .environmentObject(self.auth)
                    .frame(width: .infinity, height: Constants.screenWidth / 1.2, alignment: .center)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 0)
                    .padding(.top, 5)
            }
        }
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
            self.foundUser = true
        })
    }
    
    func shareBackgroundImage() {
        let image = UIImage(imageLiteralResourceName: "SoftChatBubbles_DarkWallpaper")
        let sticker = UIImage(imageLiteralResourceName: "like")

        InstagramStories.Shared.post(bgImage: image, stickerImage: sticker, contentURL: self.shareURL)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
    
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}
