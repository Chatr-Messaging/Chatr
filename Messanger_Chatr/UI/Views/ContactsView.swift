//
//  ContactsView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/9/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import SDWebImageSwiftUI
import RealmSwift

struct ContactsView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @Binding var newDialogID: Int
    @Binding var dismissView: Bool
    @State var userPhoneNumber: String = ""
    @State var searchContact: String = ""
    @State var showUserProfile: Bool = false
    @State var showAddChat: Bool = false
    @State var showAddNewContact: Bool = false
    @State var profileImgSize = CGFloat(45)
    @State var alertNum: Int = 0
    @State var fullName: String = ""
    @State var pageIndex: Int = 0
    @State var scrollOffset: CGFloat = CGFloat()
    @State private var navLinkAction: Int? = 0
    @State private var bannerCount: Int = 0
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var selectedQuickSnapContact: ContactStruct = ContactStruct()
    @State var contactBannerDataArray: [ContactBannerData] = []
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack() {
                        
                        //MARK: Self Profile Section
                        NavigationLink(destination: ProfileView(dimissView: $showUserProfile, selectedNewDialog: self.$newDialogID, fromContactsPage: true), tag: 1, selection: $navLinkAction) {
                            ZStack(alignment: .center) {
                                RoundedRectangle(cornerRadius: 20, style: .circular)
                                    .foregroundColor(Color("buttonColor"))
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                                
                                HStack {
                                    if self.auth.isUserAuthenticated == .signedIn {
                                        ZStack {
                                            if let avitarURL = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.avatar {
                                                WebImage(url: URL(string: avitarURL))
                                                    .resizable()
                                                    .placeholder{ Image(systemName: "person.fill") }
                                                    .indicator(.activity)
                                                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                                    .scaledToFill()
                                                    .clipShape(Circle())
                                                    .frame(width: 55, height: 55, alignment: .center)
                                                    .padding(.leading, 10)
                                                    .shadow(color: Color("buttonShadow"), radius: 8, x: 0, y: 5)
                                            }
                                            ZStack(alignment: .center) {
                                                HStack {
                                                    Text("\((self.auth.profile.results.first?.contactRequests.count ?? 0))")
                                                        .foregroundColor(.white)
                                                        .fontWeight(.medium)
                                                        .font(.footnote)
                                                        .padding(.horizontal, 5)
                                                }.background(Capsule().frame(height: 22).frame(minWidth: 22).foregroundColor(Color("alertRed")).shadow(color: Color("alertRed").opacity(0.75), radius: 5, x: 0, y: 5))
                                            }.offset(x: -19.25, y: -19.25)
                                            .opacity((self.auth.profile.results.first?.contactRequests.count ?? 0) > 0 ? 1 : 0)
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
                                            Text(self.fullName)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                                .onAppear() {
                                                    self.fullName = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "Chatr User"
                                                }
                                        }.offset(y: self.auth.subscriptionStatus == .subscribed ? 3 : 0)
                                        
                                        Text(self.userPhoneNumber)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .offset(y: self.auth.subscriptionStatus == .subscribed ? -3 : 0)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack {
                                        Image(systemName: "qrcode.viewfinder")
                                            .resizable()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .foregroundColor(.secondary)
                                            .padding(.trailing, 5)
                                        
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding()
                                    .padding(.vertical, 10)
                                }
                                
                            }
                        }.buttonStyle(ClickMiniButtonStyle())
                        .frame(height: 60, alignment: .center)
                        .background(Color.clear)
                        .padding(.top)
                        .padding(.horizontal)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.navLinkAction = 1
                        }
                        
                        //MARK: BANNER Section
                        VStack {
                            //Show Banner only if 1.) User N  ot Premium, User has not uploaded address book, or
                            //ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
                            ZStack(alignment: .bottom) {
                                if self.contactBannerDataArray.count > 0 {
                                    ContactCarousel(width: Constants.screenWidth, page: self.$pageIndex, scrollOffset: self.$scrollOffset, dataArray: self.$contactBannerDataArray, dataArrayCount: self.$bannerCount, quickSnapViewState: self.$quickSnapViewState, height: self.contactBannerDataArray.count > 0 ? 160 : 0)
                                        .environmentObject(self.auth)
                                        .frame(width: Constants.screenWidth, height: self.contactBannerDataArray.count > 0 ? 175 : 0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0))
                                        .resignKeyboardOnDragGesture()
                                    
                                    if self.contactBannerDataArray.count > 1 {
                                        ContactPageControl(page: self.$pageIndex, dataArrayCount: self.$bannerCount, color: colorScheme == .dark ? "white" : "black")
                                            .frame(minWidth: 35, idealWidth: 50, maxWidth: 75)
                                    }
                                }
                            }.onAppear {
                                //discover is always on...
                                if self.contactBannerDataArray.count < 4 {
                                    self.contactBannerDataArray.append(ContactBannerData(titleBold: "Discover", title: "Channels", subtitleImage: "magnifyingglass", subtitle: "Join your favorite public groups", imageMain: "contactsBanner", gradientBG: "discoverBackground"))
                                    
                                    self.contactBannerDataArray.append(ContactBannerData(titleBold: "Chatr", title: "Premium", subtitleImage: "arrow.up.right", subtitle: "Upgrade to", imageMain: "shieldWide", gradientBG: "preimumBackground"))
                                    
                                    self.contactBannerDataArray.append(ContactBannerData(titleBold: "Sync", title: "Address Book", subtitleImage: "text.book.closed", subtitle: "Connect with existing contacts", imageMain: "addressBook", gradientBG: "sendQuickSnapBackground"))
                                    
                                    self.contactBannerDataArray.append(ContactBannerData(titleBold: "Send", title: "Quick Snaps", subtitleImage: "paperplane.fill", subtitle: "Send moments to your contacts", imageMain: "quickSnapBanner", gradientBG: "syncAddressBackground"))
                                    
                                    self.bannerCount = self.contactBannerDataArray.count

                                    if self.auth.subscriptionStatus != .notSubscribed {
                                        self.bannerCount -= 1
                                    }
                                    if AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self)).results.count != 0 {
                                        self.bannerCount -= 1
                                    }
                                }
                            }
                        }
                        
                        
                        //MARK: HIGHLIGHTED Section
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .center) {
                                    //Online Section
                                    if self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isOnline == true }).count > 0 {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("ONLINE:")
                                                .font(.caption)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                            
                                            HStack(spacing: 10) {
                                                ForEach(self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isOnline == true }), id: \.self) { savedContact in
                                                    NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromContacts, contact: savedContact).edgesIgnoringSafeArea(.all).environmentObject(self.auth)) {
                                                        HighlightedContactCell(contact: savedContact, newMessage: self.$newDialogID, dismissView: self.$dismissView, selectedQuickSnapContact: self.$selectedQuickSnapContact, quickSnapViewState: self.$quickSnapViewState)
                                                            .frame(width: 150, height: 150)
                                                            .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                                            .background(Color("buttonColor"))
                                                            .cornerRadius(20)
                                                            .disabled(self.quickSnapViewState == .closed ? false : true)
                                                            
                                                    }.buttonStyle(ClickMiniButtonStyle())
                                                }.frame(height: 150)
                                            }.padding(.trailing, 10)
                                        }
                                    }
                                    
                                    //Favorite Section
                                    if self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isFavourite == true && $0.isOnline == false }).count > 0 {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("FAVORITE:")
                                                .font(.caption)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                            
                                            HStack(spacing: 10) {
                                                ForEach(self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isFavourite == true && $0.isOnline == false }), id: \.self) { savedContact in
                                                    NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromContacts, contact: savedContact).edgesIgnoringSafeArea(.all).environmentObject(self.auth)) {
                                                        HighlightedContactCell(contact: savedContact, newMessage: self.$newDialogID, dismissView: self.$dismissView, selectedQuickSnapContact: self.$selectedQuickSnapContact, quickSnapViewState: self.$quickSnapViewState)
                                                            .frame(width: 150, height: 150)
                                                            .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                                            .background(Color("buttonColor"))
                                                            .cornerRadius(20)
                                                            .disabled(self.quickSnapViewState == .closed ? false : true)
                                                            
                                                    }.buttonStyle(ClickMiniButtonStyle())
                                                }.frame(height: 150)
                                            }.padding(.trailing, 10)
                                        }
                                    }
                                    
                                    //Last Qucik Snap
                                    if self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isFavourite == false && $0.isOnline == false && $0.hasQuickSnaped == true }).count > 0 {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("RECENT:")
                                                .font(.caption)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                            
                                            HStack(spacing: 10) {
                                                ForEach(self.auth.contacts.results.filter({ $0.isMyContact == true && $0.isFavourite == false && $0.isOnline == false && $0.hasQuickSnaped == true }), id: \.self) { savedContact in
                                                    NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromContacts, contact: savedContact).edgesIgnoringSafeArea(.all).environmentObject(self.auth)) {
                                                        HighlightedContactCell(contact: savedContact, newMessage: self.$newDialogID, dismissView: self.$dismissView, selectedQuickSnapContact: self.$selectedQuickSnapContact, quickSnapViewState: self.$quickSnapViewState)
                                                            .frame(width: 150, height: 150)
                                                            .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                                            .background(Color("buttonColor"))
                                                            .cornerRadius(20)
                                                            .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                                            .disabled(self.quickSnapViewState == .closed ? false : true)
                                                            
                                                    }.buttonStyle(ClickMiniButtonStyle())
                                                }.frame(height: 150)
                                            }
                                        }
                                    }
                                }.padding(.horizontal)
                            }.frame(width: Constants.screenWidth, height: self.auth.contacts.results.filter({ $0.isMyContact == true && ($0.isOnline == true || $0.isFavourite == true || $0.hasQuickSnaped == true) }).count > 0 ? 150 : 0)
                            .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                        }.padding(.bottom, self.auth.contacts.results.filter({ $0.isMyContact == true && ($0.isOnline == true || $0.isFavourite == true || $0.hasQuickSnaped == true) }).count > 0 ? 25 : 0)
                        .resignKeyboardOnDragGesture()
                        
                        //MARK: CONTACTS Section
                        if self.auth.contacts.results.filter({ $0.isMyContact == true }).count == 0 {
                            //MARK: No Contact Section
                            VStack {
                                Spacer()
                                Text("No Contacts")
                                    .font(.largeTitle)
                                    .foregroundColor(.primary)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                Text("Start connecting to people \naround the world!")
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 10)
                                
                                Image("NoContacts")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.bottom, 20)
                                
                                Button(action: {
                                    self.showAddChat.toggle()
                                }) {
                                    HStack {
                                        Image(systemName: "person.fill.badge.plus")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 26, height: 22, alignment: .center)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 5)
                                        
                                        Text("Add Contacts")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }.buttonStyle(MainButtonStyle())
                                .frame(height: 45)
                                .frame(minWidth: 200, maxWidth: 240)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                                .padding(.bottom, 20)
                                .sheet(isPresented: self.$showAddChat, onDismiss: {
                                    print("loading selected dialog")
                                    if self.newDialogID != 0 {
                                        self.dismissView.toggle()
                                    }
                                }) {
                                    addNewContactView(dismissView: self.$showAddChat, newDialogID: self.$newDialogID)
                                        .environmentObject(self.auth)
                                        .background(Color("bgColor"))
                                        .onAppear() {
                                            self.newDialogID = 0
                                        }
                                }
                                
                                Spacer()
                            }.animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                        } else {
                            
                            //MARK: Search, Filter, & Add Section
                            HStack {
                                
                                /*
                                //Filter Btn
                                Button(action: {
                                    print("tap filter btn")
                                    
                                    let event = Event()
                                    event.notificationType = .push
                                    event.usersIDs = [NSNumber(value: 654260)]
                                    event.type = .oneShot

                                    var pushParameters = [String : String]()
                                    pushParameters["title"] = "Marissa Frankford"
                                    pushParameters["message"] = "Hello Brandon Shaw!! Test Push Noti"
                                    pushParameters["ios_badge"] = "1"
                                    pushParameters["ios_sound"] = "app_sound.wav"

                                    if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                                                options: .prettyPrinted) {
                                      let jsonString = String(bytes: jsonData,
                                                              encoding: String.Encoding.utf8)

                                      event.message = jsonString

                                      Request.createEvent(event, successBlock: {(events) in
                                        print("sent push notification!! \(events)")
                                      }, errorBlock: {(error) in
                                        print("error sending noti: \(error.localizedDescription)")
                                      })
                                    }
                                    
                                }) {
                                    ZStack {
                                        Rectangle()
                                            .frame(width: Constants.btnSize, height: Constants.btnSize, alignment: .center)
                                            .foregroundColor(Color("buttonColor"))
                                            .clipShape(RoundedRectangle(cornerRadius: Constants.btnSize / 3.5, style: .circular))
                                            .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 8)
                                        
                                        Image(systemName: "slider.horizontal.3")
                                            .resizable()
                                            .frame(width: 20, height: 18, alignment: .center)
                                            .foregroundColor(.primary)
                                    }
                                }.padding(.horizontal)
                                .buttonStyle(ClickButtonStyle())
                                */
                                
                                //Seach Bar
                                ZStack {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .padding(.leading, 5)
                                            .foregroundColor(.primary)
                                        
                                        TextField("Search", text: $searchContact)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 16))
                                            .lineLimit(1)
                                            .keyboardType(.webSearch)
                                            .padding(.vertical, 2)
                                        
                                        if !searchContact.isEmpty {
                                            Button(action: {
                                                self.searchContact = ""
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }.padding(EdgeInsets(top: 10, leading: 5, bottom: 10, trailing: 10))
                                    .foregroundColor(.gray)
                                    .background(Color("buttonColor"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
                                    .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 8)
                                }.frame(minWidth: 80, maxWidth: 200)
                                .padding(.horizontal)
                                
                                Spacer()
                                
                                //Add new user button
                                Button(action: {
                                        self.showAddNewContact.toggle()
                                }) {
                                    ZStack {
                                        Rectangle()
                                            .frame(width: Constants.btnSize, height: Constants.btnSize, alignment: .center)
                                            .foregroundColor(Color("buttonColor"))
                                            .clipShape(RoundedRectangle(cornerRadius: Constants.btnSize / 3.5, style: .circular))
                                            .shadow(color: Color.black.opacity(0.20), radius: 10, x: 0, y: 8)
                                        
                                        Image(systemName: "person.badge.plus")
                                            .resizable()
                                            .frame(width: 22, height: 20, alignment: .center)
                                            .foregroundColor(.primary)
                                    }
                                }.padding(.horizontal)
                                .buttonStyle(ClickButtonStyle())
                                .sheet(isPresented: self.$showAddNewContact, onDismiss: {
                                    print("loading selected dialog")
                                    if self.newDialogID != 0 {
                                        self.dismissView.toggle()
                                    }
                                }) {
                                    addNewContactView(dismissView: self.$showAddNewContact, newDialogID: self.$newDialogID)
                                        .environmentObject(self.auth)
                                        .background(Color("bgColor"))
                                        .onAppear() {
                                            self.newDialogID = 0
                                        }
                                }
                            }.padding(.bottom, 10)
                            .resignKeyboardOnDragGesture()
                            
                            //MARK: Contact Section
                            HStack {
                                Text(self.auth.contacts.results.filter({ $0.isMyContact == true }).count == 1 ? "\(self.auth.contacts.results.filter({ $0.isMyContact == true }).count) TOTAL CONTACT:" : "\(self.auth.contacts.results.filter({ $0.isMyContact == true }).count) TOTAL CONTACTS:")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.horizontal)
                                    .offset(y: 2)
                                Spacer()
                            }
                            
                            LazyVStack(alignment: .center, spacing: 0) {
                                ForEach(self.auth.contacts.filterContact(text: self.searchContact).filter({ $0.isMyContact == true }).sorted { $0.fullName < $1.fullName }, id: \.self) { contact in
                                    if contact.id != Session.current.currentUserID {
                                        NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromContacts, contact: contact).edgesIgnoringSafeArea(.all).environmentObject(self.auth)) {
                                            VStack(alignment: .trailing, spacing: 0) {
                                                HStack {
                                                    ZStack() {
                                                        if let avitarURL = contact.avatar {
                                                            WebImage(url: URL(string: avitarURL))
                                                                .resizable()
                                                                .placeholder{ Image(systemName: "person.fill") }
                                                                .indicator(.activity)
                                                                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                                                .scaledToFill()
                                                                .clipShape(Circle())
                                                                .frame(width: 40, height: 40, alignment: .center)
                                                                .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 5)
                                                        } else {
                                                            ZStack(alignment: .center) {
                                                                Circle()
                                                                    .frame(width: 40, height: 40, alignment: .center)
                                                                    .foregroundColor(Color("bgColor"))
                                                                
                                                                Text("".firstLeters(text: contact.fullName))
                                                                    .font(.system(size: 14))
                                                                    .fontWeight(.bold)
                                                                    .foregroundColor(.primary)
                                                            }
                                                        }
                                                        
                                                        RoundedRectangle(cornerRadius: 5)
                                                            .frame(width: 10, height: 10)
                                                            .foregroundColor(.green)
                                                            .opacity(contact.isOnline ? 1 : 0)
                                                            .offset(x: 12, y: 15)
                                                        
                                                        if contact.quickSnaps.count > 0 {
                                                            Circle()
                                                                .stroke(Constants.quickSnapGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                                .frame(width: 48, height: 48)
                                                                .foregroundColor(.clear)
                                                        }
                                                    }
                                                    
                                                    VStack(alignment: .leading) {
                                                        HStack(spacing: 5) {
                                                            if contact.isPremium {
                                                                Image(systemName: "checkmark.seal")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .font(Font.title.weight(.medium))
                                                                    .frame(width: 16, height: 16, alignment: .center)
                                                                    .foregroundColor(Color("main_blue"))
                                                            }
                                                                                                                        
                                                            Text(contact.fullName)
                                                                .font(.headline)
                                                                .fontWeight(.semibold)
                                                                .foregroundColor(.primary)
                                                                .multilineTextAlignment(.leading)
                                                        }.offset(y: contact.isPremium ? 3 : 0)
                                                        
                                                        Text(contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                                            .font(.caption)
                                                            .fontWeight(.regular)
                                                            .foregroundColor(.secondary)
                                                            .multilineTextAlignment(.leading)
                                                            .offset(y: contact.isPremium ? -3 : 0)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .resizable()
                                                        .font(Font.title.weight(.bold))
                                                        .scaledToFit()
                                                        .frame(width: 7, height: 15, alignment: .center)
                                                        .foregroundColor(.secondary)
                                                }.padding(.horizontal)
                                                .padding(.vertical, 10)
                                                
                                                if self.auth.contacts.results.filter({ $0.isMyContact == true }).sorted { $0.fullName < $1.fullName }.last != contact {
                                                    Divider()
                                                        .frame(width: Constants.screenWidth - 100)
                                                }
                                            }
                                        }.buttonStyle(changeBGButtonStyle())
                                        .resignKeyboardOnDragGesture()
                                        .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                    }
                                }
                            }.background(Color("buttonColor"))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                            .KeyboardAwarePadding()
                        }
                        
                        Spacer()
                        //MARK: FOOTER
                        FooterInformation()
                            .padding(.vertical, 30)
                    }.padding(.top, 110)
                }.navigationBarTitle("Contacts", displayMode: .large)
                .background(Color("bgColor"))
                .edgesIgnoringSafeArea(.all)
                .navigationBarItems(leading:
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .foregroundColor(.primary)
                    })
                
            }.navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                self.userPhoneNumber = UserDefaults.standard.string(forKey: "phoneNumber")?.format(phoneNumber: String(UserDefaults.standard.string(forKey: "phoneNumber")?.dropFirst().dropFirst() ?? "+1 (123) 456-6789")) ?? "+1 (123) 456-6789"
                print("the Chat contacts count: \(String(describing: Chat.instance.contactList?.contacts.count)) & Realm Contacts count: \(self.auth.contacts.results.count)")
            }
            
            //MARK: Quick Snap View
            QuickSnapStartView(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$selectedQuickSnapContact)
                .environmentObject(self.auth)
                .disabled(self.quickSnapViewState != .closed || self.auth.isLoacalAuth ? false : true)
                .opacity(self.auth.isLoacalAuth ? 0 : 1)
        }
    }
}

