//
//  ProfileSettingsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import SDWebImageSwiftUI
import FirebaseDatabase
import WKView
import StoreKit

// MARK: Profile View
struct ProfileView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var dimissView: Bool
    @Binding var selectedNewDialog: Int
    @State var fromContactsPage: Bool = false
    @State var userPhoneNumber: String = String()
    @State var selectionPersonalProfile: Int? = nil
    @State var profileImgSize = CGFloat(55)
    @State var alertNum: Int = ChatrApp.dialogs.contactRequestIDs.count
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    @State private var editProfileAction: Int? = 0
    @State var localAuth: Bool = false
    @State var isPremium: Bool = false
    @State var isInfoPrivate: Bool = false
    @State var isMessagingPrivate: Bool = false
    @State var openPremium: Bool = false
    @State var helpsupport: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack {
                //MARK: Self Profile Section
                NavigationLink(destination: EditProfileView().environmentObject(self.auth), tag: 1, selection: $editProfileAction) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 20, style: .circular)
                            .foregroundColor(Color("buttonColor"))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                        
                        HStack {
                            if self.auth.isUserAuthenticated == .signedIn {
                                if let avitarURL = self.profile.results.first?.avatar {
                                    WebImage(url: URL(string: avitarURL))
                                        .resizable()
                                        .placeholder{ Image(systemName: "person.fill") }
                                        .indicator(.activity)
                                        .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                        .scaledToFill()
                                        .clipShape(Circle())
                                        .frame(width: 55, height: 55, alignment: .center)
                                        .padding(.vertical, 10)
                                        .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                                }
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
                                    
                                    Text(self.profile.results.first?.fullName ?? "No Name")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }.offset(y: self.auth.subscriptionStatus == .subscribed ? 3 : 0)
                                
                                Text("edit profile")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.leading)
                                    .offset(y: self.auth.subscriptionStatus == .subscribed ? -3 : 0)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .resizable()
                                .font(Font.title.weight(.bold))
                                .scaledToFit()
                                .frame(width: 7, height: 15, alignment: .center)
                                .foregroundColor(.secondary)
                        }.padding(.horizontal)
                    }.onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        self.editProfileAction = 1
                    }
                }.buttonStyle(ClickMiniButtonStyle())
                .frame(height: 60, alignment: .center)
                .background(Color.clear)
                .padding(.top)
                .padding(.horizontal)
                
                //MARK: Services Section
                HStack {
                    Text("SERVICES:")
                        .font(.caption)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .offset(y: 2)
                    Spacer()
                }.padding(.top, 30)
                
                VStack(alignment: .center) {
                    VStack(spacing: 0) {
                        
                        //Share Profile
                        NavigationLink(destination: ShareProfileView(dimissView: self.$dimissView, contactID: self.profile.results.first?.id ?? 0, contactFullName: self.profile.results.first?.fullName ?? "Chatr Contact", contactAvatar: self.profile.results.first?.avatar ?? "").environmentObject(self.auth)) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("QRIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Share Profile")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                    
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        
                        //Chatr Premium
                        VStack(alignment: .trailing, spacing: 0) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                if !UserDefaults.standard.bool(forKey: "premiumSubscriptionStatus") {
                                    self.openPremium.toggle()
                                }
                            }) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack(alignment: .center) {
                                        Image("VerifiedIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.primary)
                                            .frame(width: 32, height: 32, alignment: .center)
                                            .padding(.trailing, 5)
                                        
                                        Text("Chatr Premium")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .padding(.vertical, 8)
                                    
                                    Divider()
                                        .frame(width: Constants.screenWidth - 95)
                                }
                            }.buttonStyle(changeBGButtonStyle())
                        }.sheet(isPresented: self.$openPremium, content: {
                            MembershipView()
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                                .navigationBarTitle("")
                        })
                        
                        //Contcat Requests
                        NavigationLink(destination: contactRequestView(dismissView: self.$dimissView, selectedNewDialog: self.$selectedNewDialog).environmentObject(self.auth)) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(alignment: .center) {
                                    ZStack(alignment: .center) {
                                        Image("ContactRequestIcon")
                                            .resizable()
                                            .frame(width: 32, height: 32, alignment: .center)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Text("\((self.auth.profile.results.first?.contactRequests.count ?? 0) + (Chat.instance.contactList?.pendingApproval.count ?? 0))")
                                                .foregroundColor(.white)
                                                .fontWeight(.medium)
                                                .font(.caption)
                                                .padding(.horizontal, 5)
                                        }.background(Capsule().frame(height: 18).frame(minWidth: 18).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 2.5, x: 0, y: 2.5))
                                        .offset(x: -15, y: -15)
                                        .opacity((self.auth.profile.results.first?.contactRequests.count ?? 0) + (Chat.instance.contactList?.pendingApproval.count ?? 0) > 0 ? 1 : 0)
                                    }
                                    
                                    Text("Contact Requests")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)
                                        .offset(x: 5)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        
                        //Data & Storage Requests
                        NavigationLink(destination: storageView().environmentObject(self.auth)) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("DataStorageIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Data & Storage")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        
                        //Appearance Requests
                        NavigationLink(destination: appearanceView().environmentObject(self.auth)) {
                            HStack {
                                Image("AppearanceIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.primary)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Text("Appearance")
                                    .font(.none)
                                    .fontWeight(.none)
                                    .foregroundColor(.primary)

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .font(Font.title.weight(.bold))
                                    .scaledToFit()
                                    .frame(width: 7, height: 15, alignment: .center)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                            .padding(.vertical, 8)
                            
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                    }
                }.background(Color("buttonColor"))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                //MARK: Security Section
                /*
                HStack {
                    Text("SECURITY:")
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
                        
                        //Private Profile
                        NavigationLink(destination: securityView(isLocalAuthOn: self.$localAuth, isPremium: self.$isPremium, isInfoPrivate: self.$isInfoPrivate, isMessaging: self.$isMessagingPrivate).environmentObject(self.auth).navigationBarTitle("Privacy").modifier(GroupedListModifier())) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("PrivacyIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Privacy")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        .onAppear() {
                            self.isInfoPrivate = self.profile.results.first?.isInfoPrivate ?? false
                            self.isMessagingPrivate = self.profile.results.first?.isMessagingPrivate ?? false
                        }
                            
                        //Blocked Contacts Profile
                        NavigationLink(destination: ringtoneView().navigationBarTitle("Blocked Contacts").modifier(GroupedListModifier())) {
                            HStack {
                                Image("BlockedIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.primary)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Text("Blocked Contacts")
                                    .font(.none)
                                    .fontWeight(.none)
                                    .foregroundColor(.primary)

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .font(Font.title.weight(.bold))
                                    .scaledToFit()
                                    .frame(width: 7, height: 15, alignment: .center)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                            .padding(.vertical, 8)
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                    }
                }.background(Color("buttonColor"))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                //MARK: Requirements Section
                HStack {
                    Text("REQUIREMENTS:")
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
                        
                        //Help & Support
                        Button(action: {
                            self.helpsupport.toggle()
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("HelpSupportIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("FAQ & Support")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .sheet(isPresented: self.$helpsupport, content: {
                            NavigationView {
                                WebView(url: "www.chatr-messaging.com",
                                    tintColor: Color("buttonColor_darker"),
                                    titleColor: Color("bgColor_opposite"),
                                    backText: Text("Done").foregroundColor(.blue),
                                    reloadImage: Image(systemName: "arrow.counterclockwise"),
                                    goForwardImage: Image(systemName: "arrow.forward"),
                                    goBackImage: Image(systemName: "arrow.backward"),
                                    allowedHosts: Constants.allowedHosts,
                                    forbiddenHosts: [])
                            }
                        })
                        
                        //Rate Chatr
                        Button(action: {
                            StoreReviewHelper.requestReview()
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("RateIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Rate Chatr")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        
                        //More About Chatr
                        NavigationLink(destination: AboutChatrView()) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("AboutIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("About Chatr")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                            
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        
                        //Advanced Profile
                        NavigationLink(destination: advancedView(dimissView: self.$dimissView).environmentObject(self.auth)) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image("AdvancedIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.primary)
                                        .frame(width: 32, height: 32, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Advanced")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.primary)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 95)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
 
                        //Log out view
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.auth.preventDismissal = true
                            self.auth.isUserAuthenticated = .signedOut
                            withAnimation {
                                self.dimissView.toggle()
                            }
                        }) {
                            HStack {
                                Image("LogOutIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.red)
                                    .frame(width: 32, height: 32, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Text("Log Out")
                                    .font(.none)
                                    .fontWeight(.none)
                                    .foregroundColor(.red)

                                Spacer()
                                Image(systemName: "chevron.right")
                                    .resizable()
                                    .font(Font.title.weight(.bold))
                                    .scaledToFit()
                                    .frame(width: 7, height: 15, alignment: .center)
                                    .foregroundColor(.secondary)
                            }.padding(.horizontal)
                            .padding(.vertical, 8)
                        }.buttonStyle(changeBGButtonStyle())
                    }
                }.background(Color("buttonColor"))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
                .padding(.bottom, 5)
 
 */
                
            
                Spacer()
                //MARK: FOOTER
                FooterInformation()
                    .padding(.top, 50)
                    .padding(.bottom, 30)
            }.padding(.top, 110)
        }.navigationBarTitle("Profile", displayMode: .large)
        .background(Color("bgColor"))
        .navigationViewStyle(StackNavigationViewStyle())
        .edgesIgnoringSafeArea(.all)
        .navigationBarItems(leading:
            Button(action: {
                print("Done btn tap")
                withAnimation {
                    self.dimissView.toggle()
                }
            }) {
                Text(self.fromContactsPage ? "" : "Done")
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }.disabled(self.fromContactsPage ? true : false)
        )
    }
}

struct BottomView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image("ChatBubble_dark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 27, height: 18, alignment: .center)
                    
                    Text("Chatr")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                }
                
                Text("Made with ♥ in New York")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button(action: {
                   let screenName =  "bshaw_dev"
                   let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
                   let webURL = NSURL(string: "https://twitter.com/\(screenName)")!
                   let application = UIApplication.shared

                   if application.canOpenURL(appURL as URL) {
                        application.open(appURL as URL)
                   } else {
                        application.open(webURL as URL)
                   }
                }) {
                    Text("@bshaw_dev")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .padding(.bottom)
                }
                
                Text("version " + Constants.projectVersion)
                    .font(.subheadline)
                    .fontWeight(.none)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.bottom, 30)
            }
            Spacer()
        }
    }
}
