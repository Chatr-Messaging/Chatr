//
//  ContentView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 11/24/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CoreData
import ConnectyCube
import RealmSwift
import LocalAuthentication
import UserNotifications
import SlideOverCard
import ConfettiSwiftUI


// MARK: Home / Starting Point
@available(iOS 14.0, *)
struct HomeView: View {
    @EnvironmentObject var auth: AuthModel
    @State var loginIsPresented: Bool = true

    var body: some View {
        ZStack {
            switch self.auth.isUserAuthenticated {
            case .undefined:
                Text("user's sign-in status is unknown.")
                    .foregroundColor(.primary)
                    .edgesIgnoringSafeArea(.all)
            case .signedIn:
                if !self.auth.preventDismissal {
                    Text("")
                        .onAppear(perform: {
                            //ChatrApp.connect()
                            self.auth.initIAPurchase()

                            if self.auth.profile.results.first?.isLocalAuthOn ?? false {
                                self.auth.isLocalAuth = true
                                let context = LAContext()
                                var error: NSError?

                                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                    let reason = "Identify yourself!"

                                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                        if success {
                                            self.auth.isLocalAuth = false
                                        }
                                    }
                                }
                            } else { self.auth.isLocalAuth = false }
                        })
                        .onDisappear(perform: {
                            self.auth.haveUserFullName = false
                            self.auth.haveUserProfileImg = false
                            self.loginIsPresented = true
                        })
                } else {
                    Text("")
                        .onAppear {
                            self.auth.haveUserFullName = false
                            self.auth.haveUserProfileImg = false
                            self.auth.isUserAuthenticated = .signedOut
                        }
                }
            case .signedOut:
                if #available(iOS 15.0, *) {
                    Button(action: {
                    }) {
                        Text("")
                    }.sheet(isPresented: self.$loginIsPresented, onDismiss: {
                        self.auth.preventDismissal = false
                        self.auth.verifyCodeStatusKeyboard = false
                        self.auth.verifyPhoneStatusKeyboard = false
                    }) {
                        welcomeView(presentView: self.$loginIsPresented)
                            .background(Color("bgColor"))
                            .edgesIgnoringSafeArea(.all)
                            .environmentObject(self.auth)
                            .disabled(self.auth.isUserAuthenticated == .signedOut ? false : true)
                            .interactiveDismissDisabled(self.auth.preventDismissal)
                            .onAppear(perform: {
                                self.auth.preventDismissal = true
                                self.auth.verifyCodeStatus = .undefined
                                self.auth.verifyPhoneNumberStatus = .undefined
                            })
                    }
                } else {
                    DismissGuardian(preventDismissal: $auth.preventDismissal, attempted: $auth.attempted) {
                        Button(action: {
                        }) {
                            Text("")
                        }.sheet(isPresented: self.$loginIsPresented, onDismiss: {
                            self.auth.preventDismissal = false
                            self.auth.verifyCodeStatusKeyboard = false
                            self.auth.verifyPhoneStatusKeyboard = false
                        }) {
                            welcomeView(presentView: self.$loginIsPresented)
                                .background(Color("bgColor"))
                                .edgesIgnoringSafeArea(.all)
                                .environmentObject(self.auth)
                                .disabled(self.auth.isUserAuthenticated == .signedOut ? false : true)
                                .onAppear(perform: {
                                    self.auth.preventDismissal = true
                                    self.auth.verifyCodeStatus = .undefined
                                    self.auth.verifyPhoneNumberStatus = .undefined
                                })
                        }
                    }
                }
            case .error:
                Text("There is an internal error.\n Please contact Chatr for help.")
                    .foregroundColor(.primary)
                    .edgesIgnoringSafeArea(.all)
            }
            
            ChatrBaseView()
                .background(Color("bgColor"))
                .environmentObject(self.auth)
                .edgesIgnoringSafeArea(.all)
                .opacity(self.auth.isUserAuthenticated == .signedIn ? 1 : 0)
                .disabled(self.auth.isUserAuthenticated == .signedIn ? false : true)
            
        }.background(Color("deadViewBG"))
        .edgesIgnoringSafeArea(.all)
        //.onOpenURL { url in
            //let link = url.absoluteString
            //print("opened from URL!! :D \(link)")
        //}
//        .onAppear {
//            //self.auth.configureFirebaseStateDidChange()
//        }
    }
}

// MARK: Main Home List
@available(iOS 14.0, *)
struct ChatrBaseView: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @EnvironmentObject var auth: AuthModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var messageViewModel = ChatMessageViewModel()
    @ObservedObject var imagePicker = KeyboardCardViewModel()
    @State var showContacts: Bool = false
    @State var showUserProfile: Bool = false
    @State var showNewChat: Bool = false
    @State var searchText: String = String()
    @State var keyboardText: String = String()
    @State var selectedDialogID: String = String()
    @State var newDialogID: String = ""
    @State var showPinDetails: String = ""
    @State var newDialogFromContact: Int = 0
    @State var newDialogFromSharedContact: Int = 0
    @State var showFullKeyboard = false
    @State var emptyQuickSnaps: Bool = false
    @State var hasAttachments: Bool = false
    @State var showSharedContact: Bool = false
    @State var showSharedPublicDialog: Bool = false
    @State var isEditGroupOpen: Bool = false
    @State var canEditGroup: Bool = false
    @State var disableDialog: Bool = false
    @State var showWelcomeNewUser: Bool = false
    @State var showKeyboardMediaAssets: Bool = false
    @State var isLocalOpen : Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @State var activeView = CGSize.zero
    @State var keyboardDragState = CGSize.zero
    @State var keyboardHeight: CGFloat = 0
    @State var textFieldHeight: CGFloat = 38
    @State var selectedContacts: [Int] = []
    @State var counter: Int = 0
    @State var isKeyboardActionOpen: Bool = false
    @State var isTopCardOpen: Bool = false
    @State var isDiscoverOpen: Bool = false
    @State var isDetailOpen: Bool = false
    @State var detailMessageModel: MessageStruct = MessageStruct()
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var selectedQuickSnapContact: ContactStruct = ContactStruct()
    @Namespace var namespace
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))
    @State var shouldExecuteTap: Bool = true
    let wallpaperNames = ["", "SoftChatBubbles_DarkWallpaper", "SoftPaperAirplane-Wallpaper", "oldHouseWallpaper", "nycWallpaper", "michaelAngelWallpaper", "moonWallpaper", "patagoniaWallpaper", "oceanRocksWallpaper", "southAfricaWallpaper", "flowerWallpaper", "paintWallpaper"]
    
    var body: some View {
        ZStack(alignment: .center) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    //MARK: Header Section
                    GeometryReader { geo in
                        HomeHeaderSection(showUserProfile: self.$showUserProfile)
                            .environmentObject(self.auth)
                            .offset(y: geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY + 40 : (geo.frame(in: .global).minY < 40 ? 40 : -geo.frame(in: .global).minY + 40))
                            .padding(.horizontal, 10)
                            .padding(.top)
                            .sheet(isPresented: self.$showUserProfile, onDismiss: {
                                if self.auth.isUserAuthenticated != .signedOut {
                                    self.loadSelectedDialog()
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                        self.auth.logOutFirebase(completion: {
                                            self.auth.logOutConnectyCube()
                                        })
                                    }
                                }
                            }) {
                                if self.auth.isUserAuthenticated == .signedIn {
                                    NavigationView {
                                        ProfileView(dimissView: self.$showUserProfile, selectedNewDialog: self.$newDialogFromContact)
                                            .environmentObject(self.auth)
                                            .background(Color("bgColor"))
                                    }
                                }
                            }
                    }.frame(height: Constants.btnSize + 100)
                    .onChange(of: self.showPinDetails) { msgId in
                        if self.showPinDetails != "" {
                            self.showPinDetails = ""
                            if let msg = self.auth.messages.selectedDialog(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").filter({ $0.id == msgId }).first {
                                self.messageViewModel.message = msg
                                self.isDetailOpen = true
//                                    if msg.imageType == "video/mov" {
//                                        self.messageViewModel.loadVideo(fileId: msg.image, completion: { })
//                                    }
                            }
                        }
                    }
                    
                    if self.isTopCardOpen {
                        HomeBannerCard(isTopCardOpen: self.$isTopCardOpen, counter: self.$counter)
                            .environmentObject(self.auth)
                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.05)), removal: AnyTransition.identity))
                    }

                    // MARK: "Message" Title
                    HomeMessagesTitle(isLocalOpen: self.$isLocalOpen, contacts: self.$showContacts, newChat: self.$showNewChat)
                        .frame(height: 50)
                        .environmentObject(self.auth)
                        .padding(.bottom)
                        .sheet(isPresented: self.$showContacts, onDismiss: {
                            if self.auth.isUserAuthenticated != .signedOut {
                                if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                                    self.loadPublicDialog(diaId: diaId)
                                } else if let diaId = UserDefaults.standard.string(forKey: "openingDialogId"), !diaId.isEmpty {
                                    self.loadPublicDialog(diaId: diaId)
                                } else {
                                    self.loadSelectedDialog()
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                    self.auth.logOutFirebase(completion: {
                                        self.auth.logOutConnectyCube()
                                    })
                                }
                            }
                        }) {
                            ContactsView(newDialogID: self.$newDialogFromContact, dismissView: self.$showContacts, showPinDetails: self.$showPinDetails)
                                .environmentObject(self.auth)
                                .background(Color("bgColor"))
                                .edgesIgnoringSafeArea(.all)
                        }
                        .onChange(of: self.newDialogFromSharedContact) { _ in
                            if self.newDialogFromSharedContact != 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                                    self.loadSelectedDialog()
                                }
                            }
                        }
                    
                    //MARK: Quick Snaps Section
                    GeometryReader { geometry in
                        ZStack(alignment: .top) {
                            BlurView(style: .systemUltraThinMaterial)
                                .allowsHitTesting(!UserDefaults.standard.bool(forKey: "localOpen") ? false : true)
                                .simultaneousGesture(DragGesture(minimumDistance: self.isLocalOpen ? 0 : 500))
                                .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                                .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY : -35)
                                .opacity(self.isLocalOpen ? Double((275 - self.activeView.height) / 150) : 0)
                            
                            //Wallpaper View
                            Image(self.wallpaperNames[UserDefaults.standard.integer(forKey: "selectedWallpaper")])
                                .resizable()
                                .scaledToFill()
                                .frame(width: Constants.screenWidth, height: Constants.screenHeight - 150)
                                .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY + 150 : 0)
                                .offset(y: self.isLocalOpen ? self.activeView.height : 0)
                                .opacity(self.isLocalOpen ? Double((275 - self.activeView.height) / 150) : 0)
                                .animation(.spring(response: 0.45, dampingFraction: self.isLocalOpen ? 0.65 : 0.75, blendDuration: 0))
                                .allowsHitTesting(!UserDefaults.standard.bool(forKey: "localOpen") ? false : true)
                                .simultaneousGesture(DragGesture(minimumDistance: self.isLocalOpen ? 0 : 500))

                            QuickSnapsSection(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$selectedQuickSnapContact, emptyQuickSnaps: self.$emptyQuickSnaps, isLocalOpen: self.$isLocalOpen)
                                .environmentObject(self.auth)
                                .frame(width: Constants.screenWidth)
                                .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY - (UIDevice.current.hasNotch ? -15 : 30) : 0)
                                .offset(y: self.isLocalOpen ? self.activeView.height / 1.5 : 0)
                                .animation(.spring(response: 0.45, dampingFraction: self.isLocalOpen ? 0.65 : 0.75, blendDuration: 0))
                                .padding(.vertical, self.emptyQuickSnaps ? 0 : 20)
                        }
                    }.sheet(isPresented: self.$showNewChat, onDismiss: {
                        if self.newDialogID.count > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                                self.selectedDialogID = self.newDialogID
                                self.isLocalOpen = true
                                UserDefaults.standard.set(self.isLocalOpen, forKey: "localOpen")
                                self.auth.dialogs.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.selectedDialogID)
                                UserDefaults.standard.set(self.selectedDialogID, forKey: "selectedDialogID")
                                self.newDialogID = ""
                            }
                        }
                    }) {
                        NewConversationView(usedAsNew: true, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                            .environmentObject(self.auth)
                    }
                    .sheet(isPresented: self.$isDiscoverOpen, onDismiss: {
                        if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                            self.loadPublicDialog(diaId: diaId)
                        } else if let diaId = UserDefaults.standard.string(forKey: "openingDialogId"), !diaId.isEmpty {
                            self.loadPublicDialog(diaId: diaId)
                        } else {
                            self.loadSelectedDialog()
                        }
                    }) {
                        NavigationView {
                            DiscoverView(removeDoneBtn: false, dismissView: self.$isDiscoverOpen, showPinDetails: self.$showPinDetails, openNewDialogID: self.$newDialogFromContact)
                                .environmentObject(self.auth)
                                .navigationBarTitle("Discover", displayMode: .automatic)
                                .background(Color("bgColor")
                                .edgesIgnoringSafeArea(.all))
                        }
                    }
                    .sheet(isPresented: self.$showSharedContact, onDismiss: {
                        if self.newDialogFromContact != 0 {
                            self.isLocalOpen = false
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            self.auth.dialogs.updateDialogOpen(isOpen: false, dialogID: "\(self.newDialogFromContact)")
                        }
                        self.loadSelectedDialog()
                    }) {
                        NavigationView {
                            VisitContactView(fromDialogCell: true, newMessage: self.$newDialogFromContact, dismissView: self.$showSharedContact, viewState: .fromDynamicLink)
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }

//                        //MARK: Pull to refresh - loading dialogs
//                        PullToRefreshIndicator(isLoading: self.$isLoading, preLoading: self.$isPreLoading, localOpen: self.$isLocalOpen)
//                            .environmentObject(self.auth)
//                            .offset(y: self.emptyQuickSnaps ? -70 : 60)
//                            .onAppear() {
//                                self.isLoading = false
//                                self.isPreLoading = false
//                            }

                    //MARK: Search Bar
                    if self.dialogs.results.filter { $0.isDeleted != true }.count != 0 {
                        CustomSearchBar(searchText: self.$searchText, localOpen: self.$isLocalOpen)
                            .opacity(self.isLocalOpen ? Double(self.activeView.height / 150) : 1)
                            .opacity(self.dialogs.results.count != 0 ? 1 : 0)
                            .offset(y: self.isLocalOpen ? -75 + (self.activeView.height / 3) : 0)
                            .offset(y: self.emptyQuickSnaps ? -30 : 65)
                            .blur(radius: self.isLocalOpen ? ((950 - (self.activeView.height * 3)) / 600) * 2 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0))
                            .resignKeyboardOnDragGesture()
                    }
                                            
                    //MARK: Dialogs Section
                    if self.dialogs.results.filter { $0.isDeleted != true }.count == 0 {
                        EmptyDialogView(showNewChat: self.$showNewChat, isDiscoverOpen: self.$isDiscoverOpen)
                            .environmentObject(auth)
                            .offset(y: Constants.screenWidth < 375 ? 60 : 20)
                            .offset(y: self.emptyQuickSnaps ? 0 : 100)
                            .onAppear() {
                                self.auth.dialogs.fetchDialogs(completion: { _ in })
                            }
                    }
                    
                    //MARK: Main Dialog Cells
                    ForEach(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }, id: \.id) { i in
                        GeometryReader { geo in
                            Button(action: {
                                guard activeView.height == .zero || activeView.height > 50 else {
                                    activeView.height = .zero
                                    return
                                }

                                activeView.height = .zero
                                onCellTapGesture(id: i.id, dialogType: i.dialogType)
                            }) {
                                DialogCell(dialogModel: i,
                                           isOpen: $isLocalOpen,
                                           activeView: $activeView,
                                           selectedDialogID: $selectedDialogID,
                                           showPinDetails: $showPinDetails)
                                    .environmentObject(auth)
                                    .id(i.id)
                                    .tag(i.id)
                            }
                            .contentShape(Rectangle())
                            .position(x: i.isOpen && isLocalOpen ? UIScreen.main.bounds.size.width / 2 : UIScreen.main.bounds.size.width / 2 - 20, y: i.isOpen && isLocalOpen ? activeView.height + 40 : 40)
                            .fixedSize(horizontal: false, vertical: true)
                            .zIndex(i.isOpen ? 2 : 0)
                            .opacity(isLocalOpen ? (i.isOpen ? 1 : 0) : 1)
                            .offset(y: i.isOpen && isLocalOpen ? -geo.frame(in: .global).minY + (emptyQuickSnaps ? (UIDevice.current.hasNotch ? 50 : 25) : 110) : emptyQuickSnaps ? -25 : 70)
                            .animation(.spring(response: isLocalOpen ? 0.375 : 0.45, dampingFraction: isLocalOpen ? 0.68 : 0.8, blendDuration: 0))
                            .buttonStyle(dialogButtonStyle())
                            .shadow(color: Color.black.opacity(isLocalOpen ? (colorScheme == .dark ? 0.25 : 0.15) : 0.15), radius: isLocalOpen ? 15 : 8, x: 0, y: self.isLocalOpen ? (colorScheme == .dark ? 15 : 5) : 5)
                        }.frame(height: 75, alignment: .center)
                        .padding(.horizontal, isLocalOpen && i.isOpen ? 0 : 20)
                        .simultaneousGesture(DragGesture(minimumDistance: i.isOpen ? 0 : 500).onChanged { value in
                            guard value.translation.height < 150 else { return }
                            guard value.translation.height > 0 else { return }

                            activeView = value.translation
                        }.onEnded { value in
                            //if activeView.height > 50 {
                                //onCellTapGesture(id: i.id, dialogType: i.dialogType)
                            //}

                            //shouldExecuteTap = false
                            //activeView.height = .zero
                        })
                    }
                    .disabled(self.disableDialog)
                    .onChange(of: UserDefaults.standard.bool(forKey: "localOpen")) { isOpen in
                        //self.isLocalOpen = isOpen
                        if !isOpen {
                            self.isLocalOpen = false
                            self.isKeyboardActionOpen = false
                        }

                        self.disableDialog = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            self.disableDialog = false
                        }
                    }
                    .onAppear {
                        UserDefaults.standard.set(false, forKey: "localOpen")
                        self.isLocalOpen = false
                    }
                    
                    Button("tap me 22222222") {
                        showNotiHUD(image: "wifi", color: .blue, title: "Connected", subtitle: "cool ass subtitle...")
                    }.padding(.top, 145)

                    if self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.count >= 3 || self.dialogs.results.filter { $0.isDeleted != true }.count == 0 {
                        FooterInformation()
                            .padding(.top, 140)
                            .padding(.bottom, 25)
                            .opacity(self.isLocalOpen ? 0 : 1)
                    }
                }
            }
            .overlay(
                //MARK: Chat Messages View
                GeometryReader { geo in
//                    ChatMessagesView(viewModel: self.messageViewModel, activeView: self.$activeView, keyboardChange: self.$keyboardHeight, dialogID: self.$selectedDialogID, textFieldHeight: self.$textFieldHeight, keyboardDragState: self.$keyboardDragState, hasAttachment: self.$hasAttachments, newDialogFromSharedContact: self.$newDialogFromSharedContact, isKeyboardActionOpen: self.$isKeyboardActionOpen, isHomeDialogOpen: self.$isLocalOpen, isDetailOpen: self.$isDetailOpen, emptyQuickSnaps: self.$emptyQuickSnaps, detailMessageModel: self.$detailMessageModel, namespace: self.namespace)
                    if self.isLocalOpen, UserDefaults.standard.string(forKey: "selectedDialogID") == self.selectedDialogID, UserDefaults.standard.string(forKey: "selectedDialogID") != "" {
                        MessagesTimelineView()
                            //.environmentObject(self.auth)
                            //.position(x: UIScreen.main.bounds.size.width / 2, y: self.activeView.height)
                            .frame(width: Constants.screenWidth, height: Constants.screenHeight - (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 127 : 91) : 201), alignment: .bottom)
                            .fixedSize(horizontal: true, vertical: false)
                            .zIndex(1)
                            .contentShape(Rectangle())
                            .offset(y: -geo.frame(in: .global).minY + (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 127 : 91) : 186))
                            .padding(.bottom, self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 127 : 91) : 186)
                            .offset(y: self.activeView.height) // + (self.emptyQuickSnaps ? 25 : 197))
                            .simultaneousGesture(DragGesture(minimumDistance: UserDefaults.standard.bool(forKey: "localOpen") ? 800 : 0))
                            .layoutPriority(1)
                            .onDisappear {
                                guard let dialog = self.auth.selectedConnectyDialog, dialog.isJoined(), dialog.type == .group || dialog.type == .public else {
                                    return
                                }
                                
                                self.auth.leaveDialog()
                            }
                    }
                }
            )
            .slideOverCard(isPresented: $showWelcomeNewUser, onDismiss: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }) {
                EarlyAdopterView(counter: self.$counter)
            }

            //MARK: Keyboard View
            GeometryReader { geo in
                KeyboardCardView(imagePicker: self.imagePicker, height: self.$textFieldHeight, isOpen: self.$isLocalOpen, mainText: self.$keyboardText, hasAttachments: self.$hasAttachments, showImagePicker: self.$showKeyboardMediaAssets, isKeyboardActionOpen: self.$isKeyboardActionOpen, keyboardHeight: self.$keyboardHeight)
                    .environmentObject(self.auth)
                    .frame(width: Constants.screenWidth, alignment: .center)
                    .shadow(color: Color.black.opacity(0.15), radius: 14, x: 0, y: -5)
                    .offset(y: self.isLocalOpen ? geo.frame(in: .global).maxY - 50 - (UIDevice.current.hasNotch ? 0 : -20) - (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) - (self.hasAttachments ? 110 : 0) - self.keyboardHeight - (self.isKeyboardActionOpen ? 80 : 0) : geo.frame(in: .global).maxY)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0))
                    .zIndex(2)
                    .onChange(of: self.auth.visitContactProfile) { newValue in
                        if newValue {
                            self.showSharedContact.toggle()
                            self.auth.visitContactProfile = false
                        }
                    }.onChange(of: self.auth.visitPublicDialogProfile) { newValue in
                        if newValue {
//                                if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
//                                    print("helooo we here: \(diaId) && \(self.auth.dynamicLinkPublicDialogID)")
//                                }

                            self.showSharedPublicDialog.toggle()
                            self.auth.visitPublicDialogProfile = false
                        }
                    }
                    .sheet(isPresented: self.$showSharedPublicDialog, onDismiss: {
                        guard self.auth.dynamicLinkPublicDialogID == "" else {
                            self.auth.dynamicLinkPublicDialogID = ""

                            return
                        }

                        if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                            self.loadPublicDialog(diaId: diaId)
                        } else if let diaId = UserDefaults.standard.string(forKey: "openingDialogId"), !diaId.isEmpty {
                            self.loadPublicDialog(diaId: diaId)
                        }
                    }) {
                        NavigationView {
                            VisitGroupChannelView(dismissView: self.$showSharedPublicDialog, isEditGroupOpen: self.$isEditGroupOpen, canEditGroup: self.$canEditGroup, openNewDialogID: self.$newDialogFromContact, showPinDetails: self.$showPinDetails, fromSharedPublicDialog: self.auth.dynamicLinkPublicDialogID, viewState: .fromDiscover, dialogRelationship: .unknown)
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                                .navigationBarItems(leading:
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                UserDefaults.standard.set("", forKey: "visitingDialogId")
                                                UserDefaults.standard.set("", forKey: "openingDialogId")
                                                withAnimation {
                                                    self.showSharedPublicDialog.toggle()
                                                }
                                            }) {
                                                Text("Done")
                                                    .foregroundColor(.primary)
                                                    .fontWeight(.medium)
                                            }, trailing:
                                                Button(action: {
                                                    self.isEditGroupOpen.toggle()
                                                }) {
                                                    Text("Edit")
                                                        .foregroundColor(.blue)
                                                        .opacity(self.canEditGroup ? 1 : 0)
                                                }.disabled(self.canEditGroup ? false : true))
                        }
                    }
                    /*
                    .simultaneousGesture(DragGesture().onChanged { value in
                        self.keyboardDragState = value.translation
                        if self.showFullKeyboard {
                            self.keyboardDragState.height += -100
                        }
                        if self.keyboardDragState.height < -70 {
                            self.keyboardDragState.height = -70
                        }
                        if self.keyboardDragState.height > 140 {
                            self.keyboardDragState.height = 110
                        }
                    }.onEnded { valueEnd in
                        if self.keyboardDragState.height > 50 {
                            self.showFullKeyboard = false
                            self.keyboardDragState = .zero
                            self.keyboardHeight = 0
                            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }
                        if self.keyboardDragState.height < -50 {
                            self.keyboardDragState.height = -75
                            self.showFullKeyboard = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } else {
                            self.keyboardDragState = .zero
                            self.showFullKeyboard = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    })
                    */
            }

            //MARK: Bubble Detail View
            if self.isDetailOpen {
                BubbleDetailView(viewModel: self.messageViewModel, namespace: self.namespace, newDialogFromSharedContact: self.$newDialogFromSharedContact, isDetailOpen: self.$isDetailOpen, message: self.$detailMessageModel)
                    .environmentObject(self.auth)
                    .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                    .zIndex(2)
            }
            
            //MARK: LOCKED OUT VIEW
            if self.auth.isLocalAuth && self.auth.isUserAuthenticated != .signedOut {
                LockedOutView()
            }

            //MARK: Quick Snap View
            QuickSnapStartView(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$selectedQuickSnapContact)
                .environmentObject(self.auth)
                .disabled(self.quickSnapViewState != .closed || self.auth.isLocalAuth ? false : true)
                .opacity(self.auth.isLocalAuth ? 0 : 1)
            
            ConfettiCannon(counter: $counter, repetitions: 3, repetitionInterval: 0.2)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (notii) in
                if let dict = notii.userInfo as NSDictionary? {
                    if let image = dict["image"] as? String, let color = dict["color"] as? String, let title = dict["title"] as? String {
                        let subtitle = dict["image"] as? String

                        showNotiHUD(image: image, color: color == "blue" ? .blue : color == "primary" ? .primary : color == "red" ? .red : color == "orange" ? .orange : .primary, title: title, subtitle: subtitle)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }

            self.auth.delegateConnectionState = { connectState in
                switch connectState {
                case .connected:
                    showNotiHUD(image: "wifi", color: .blue, title: "Connected", subtitle: nil)

                case .disconnected:
                    showNotiHUD(image: "wifi", color: .red, title: "Disonnected", subtitle: nil)

                case .loading:
                    showNotiHUD(image: "wifi", color: .secondary, title: "", subtitle: "connecting...")

                default:
                    return
                }
            }

            if self.auth.isFirstTimeUser && UserDefaults.standard.bool(forKey: "isEarlyAdopter") {
                self.isTopCardOpen = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.showWelcomeNewUser.toggle()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.counter += 1
                    }
                }
            } else if self.auth.isFirstTimeUser {
                self.isTopCardOpen = true
            }
            
            self.selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
        }.onDisappear() {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotificationAlert"), object: nil)
        }
    }
    
    func loadSelectedDialog() {
        guard self.newDialogFromContact != 0 else { return }

        for dia in dialogs.filterDia(text: self.searchText).filter({ $0.isDeleted != true }) {
            for occu in dia.occupentsID {
                if occu == self.newDialogFromContact && dia.dialogType == "private" {
                    UserDefaults.standard.set(dia.id, forKey: "selectedDialogID")
                    self.selectedDialogID = dia.id
                    self.newDialogFromContact = 0
                    self.isLocalOpen = true
                    UserDefaults.standard.set(true, forKey: "localOpen")
                    self.auth.dialogs.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: dia.id)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    
                    return
                }
            }
            
            if self.newDialogFromContact == 0 { return }
        }

        let dialog = ChatDialog(dialogID: nil, type: .private)
        dialog.occupantIDs = [NSNumber(value: self.newDialogFromContact)]  // an ID of opponent

        Request.createDialog(dialog, successBlock: { (dialog) in
            self.auth.dialogs.fetchDialogs(completion: { _ in
                UserDefaults.standard.set(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id, forKey: "selectedDialogID")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
                    self.isLocalOpen = true
                    UserDefaults.standard.set(self.isLocalOpen, forKey: "localOpen")
                    self.auth.dialogs.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")
                    self.newDialogFromContact = 0
                }
            })
        }) { _ in
            //occu.removeAll()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    func loadPublicDialog(diaId: String) {
        self.isLocalOpen = false
        UserDefaults.standard.set(false, forKey: "localOpen")
        self.auth.dialogs.updateDialogOpen(isOpen: false, dialogID: self.selectedDialogID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            UserDefaults.standard.set(diaId, forKey: "selectedDialogID")
            self.selectedDialogID = diaId
            self.newDialogFromContact = 0
            self.isLocalOpen = true
            UserDefaults.standard.set(true, forKey: "localOpen")
            self.auth.dialogs.updateDialogOpen(isOpen: true, dialogID: diaId)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UserDefaults.standard.set("", forKey: "openingDialogId")
        }
    }
    
    func onCellTapGesture(id: String, dialogType: String) {
        guard self.shouldExecuteTap else {
            self.shouldExecuteTap = true

            return
        }

        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        UserDefaults.standard.set(id, forKey: "selectedDialogID")
        
        if !UserDefaults.standard.bool(forKey: "localOpen") {
            UserDefaults.standard.set(true, forKey: "localOpen")
            withAnimation {
                self.isLocalOpen = true
                self.selectedDialogID = id
            }
            self.auth.dialogs.updateDialogOpen(isOpen: true, dialogID: id)
        } else {

            self.isLocalOpen = false
            UserDefaults.standard.set(false, forKey: "localOpen")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                self.auth.dialogs.updateDialogOpen(isOpen: false, dialogID: id)

                Request.cancelAllRequests({
                    if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                        self.auth.dialogs.unsubscribePublicConnectyDialog(dialogID: diaId, isOwner: false)
                    } else {
                        self.auth.dialogs.fetchDialogs(completion: { _ in
                            if dialogType == "group" || dialogType == "public" {
                                self.auth.leaveDialog()
                            }
                        })
                    }
                })
            }
        }
    }
    
    func onChanged(value: DragGesture.Value, index: Int) {
        guard value.translation.height < 150 else { UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true); return }
        guard value.translation.height > 0 else { return }
        
        self.activeView = value.translation
    }
    
    func onEnd(value: DragGesture.Value, index: Int, id: String, dialogType: String) {
        if self.activeView.height > 50 {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
            UserDefaults.standard.set(false, forKey: "localOpen")
            self.isLocalOpen = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                Request.cancelAllRequests({
                    self.auth.dialogs.updateDialogOpen(isOpen: false, dialogID: id)
                    
                    self.auth.dialogs.fetchDialogs(completion: { _ in
                        if dialogType == "group" || dialogType == "public" {
                            self.auth.leaveDialog()
                        }
                    })

                    if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                        self.auth.dialogs.unsubscribePublicConnectyDialog(dialogID: diaId, isOwner: false)
                    }
                })
            }
        }
        self.activeView.height = .zero
    }
}
