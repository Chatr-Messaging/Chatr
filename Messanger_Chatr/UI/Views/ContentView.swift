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
import PopupView
import RealmSwift
import LocalAuthentication
import UserNotifications
import SlideOverCard
import ConfettiSwiftUI

// MARK: Preview View
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            if #available(iOS 14.0, *) {
                mainHomeList()
                    .background(Color("bgColor"))
            } else {
                // Fallback on earlier versions
                OldHomeView()
            }
        }
    }
}

// MARK: Old Home / eirlier than iOS 14
struct OldHomeView: View {
    @EnvironmentObject var auth: AuthModel

    var body: some View {
        ZStack {
            Text("You are seeing 'OldHomeView' becuse you do not have iOS 14")
        }
    }
}

// MARK: Home / Starting Point
@available(iOS 14.0, *)
struct HomeView: View {
    @EnvironmentObject var auth: AuthModel
    @State var loginIsPresented: Bool = true

    var body: some View {
        ZStack {
            switch self.auth.isUserAuthenticated {
            case .undefined:
                Text("user Sign In status is Unknown.")
                    .foregroundColor(.primary)
                    .edgesIgnoringSafeArea(.all)
            case .signedIn:
                if !self.auth.preventDismissal {
                    Text("")
                        .onAppear(perform: {
                            if self.auth.profile.results.first?.isLocalAuthOn ?? false {
                                self.auth.isLoacalAuth = true
                                let context = LAContext()
                                var error: NSError?

                                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                    let reason = "Identify yourself!"

                                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                        if success {
                                            self.auth.isLoacalAuth = false
                                        }
                                    }
                                }
                            } else { self.auth.isLoacalAuth = false }
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
                DismissGuardian(preventDismissal: $auth.preventDismissal, attempted: $auth.attempted) {
                    Button(action: {
                    }) {
                        Text("")
                    }.sheet(isPresented: self.$loginIsPresented, content: {
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
                            .onDisappear(perform: {
                                self.auth.preventDismissal = false
                                self.auth.verifyCodeStatusKeyboard = false
                                self.auth.verifyPhoneStatusKeyboard = false
                            })
                    })
                }
            case .error:
                Text("There is an internal error.\n Please contact Chatr for help.")
                    .foregroundColor(.primary)
                    .edgesIgnoringSafeArea(.all)
            }
            
            mainHomeList()
                .background(Color("bgColor"))
                .environmentObject(self.auth)
                .edgesIgnoringSafeArea(.all)
                .opacity(self.auth.isUserAuthenticated == .signedIn ? 1 : 0)
                .disabled(self.auth.isUserAuthenticated == .signedIn ? false : true)
            
        }.background(Color("deadViewBG"))
        .onOpenURL { url in
            let link = url.absoluteString
            print("opened from URL!! :D \(link)")
        }
    }
}

// MARK: Main Home List
@available(iOS 14.0, *)
struct mainHomeList: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @EnvironmentObject var auth: AuthModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var messageViewModel = ChatMessageViewModel()
    @GestureState var isDragging = false
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
    @State var receivedNotification: Bool = false
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
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var selectedQuickSnapContact: ContactStruct = ContactStruct()
    @Namespace var namespace
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))
    let wallpaperNames = ["", "SoftChatBubbles_DarkWallpaper", "SoftPaperAirplane-Wallpaper", "oldHouseWallpaper", "nycWallpaper", "michaelAngelWallpaper"]
    
    var body: some View {
        ZStack {
            if !self.auth.isLoacalAuth && self.auth.isUserAuthenticated != .signedOut {
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
                                        self.auth.logOutFirebase(completion: {
                                            self.auth.logOutConnectyCube()
                                        })
                                    }
                                }) {
                                    if self.auth.isUserAuthenticated == .signedIn {
                                        NavigationView {
                                            ProfileView(dimissView: self.$showUserProfile, selectedNewDialog: self.$newDialogFromContact)
                                                .environmentObject(self.auth)
                                                .background(Color("bgColor"))
                                        }
                                    }
                                }.onAppear {
                                    NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        self.receivedNotification.toggle()
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
                                }
                        }.frame(height: Constants.btnSize + 100)
                        .onChange(of: self.showPinDetails) { msgId in
                            if self.showPinDetails != "" {
                                self.showPinDetails = ""
                                if let msg = self.auth.messages.selectedDialog(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").filter({ $0.id == msgId }).first {
                                    self.messageViewModel.message = msg
                                    self.messageViewModel.isDetailOpen = true
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
                        HomeMessagesTitle(isLocalOpen: self.$isLocalOpen, contacts: self.$showContacts, newChat: self.$showNewChat, selectedContacts: self.$selectedContacts)
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
                            .onChange(of: self.newDialogFromSharedContact) { newValue in
                                if self.newDialogFromSharedContact != 0 {
                                    print("the contact id trying to message is: \(newDialogFromSharedContact)")
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
                                    changeDialogRealmData.shared.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.selectedDialogID)
                                    UserDefaults.standard.set(self.selectedDialogID, forKey: "selectedDialogID")
                                    self.newDialogID = ""
                                }
                            }
                        }) {
                            NewConversationView(usedAsNew: true, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                                .environmentObject(self.auth)
                        }
                        .sheet(isPresented: self.$isDiscoverOpen, onDismiss: {
                            print("dismiss discover vieww")
                            if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                                self.loadPublicDialog(diaId: diaId)
                            } else if let diaId = UserDefaults.standard.string(forKey: "openingDialogId"), !diaId.isEmpty {
                                self.loadPublicDialog(diaId: diaId)
                            }
                        }) {
                            NavigationView {
                                DiscoverView(removeDoneBtn: false, dismissView: self.$isDiscoverOpen, showPinDetails: self.$showPinDetails)
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
                                changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: "\(self.newDialogFromContact)")
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
                            VStack {
                                Image("EmptyDialog")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: Constants.screenWidth - 20, maxWidth: Constants.screenWidth)
                                    .frame(height: Constants.screenWidth < 375 ? 200 : 150)
                                    .padding(.horizontal, 10)
                                    .onAppear() {
                                        changeDialogRealmData.shared.fetchDialogs(completion: { _ in })
                                    }
                                
                                Text(self.auth.isFirstTimeUser ? "Lets Get Started!" : "No Messages Found")
                                    .foregroundColor(.primary)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .frame(alignment: .center)
                                    .padding(.top, 15)
                                
                                Text("Start a new conversation \nor discover an existing group!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 25)
                                    .frame(height: 80)
                                
                                Button(action: {
                                    self.showNewChat.toggle()
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                }) {
                                    HStack(alignment: .center, spacing: 15) {
                                        Text("Start Conversation")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Image("ComposeIcon_white")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)
                                            .offset(x: -2, y: -2)
                                    }.padding(.horizontal, 15)
                                }.buttonStyle(MainButtonStyle())
                                .frame(maxWidth: 230)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
                                
                                Button(action: {
                                    print("the screen is: \(Constants.screenWidth)")
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isDiscoverOpen.toggle()
                                }) {
                                    HStack(alignment: .center, spacing: 15) {
                                        Text("Discover Channels")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Image(systemName: "safari")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22, alignment: .center)
                                            .offset(x: -2, y: -2)
                                    }.padding(.horizontal, 15)
                                    .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 55, maxHeight: 55)
                                    .background(Color("buttonColor"))
                                    .cornerRadius(15)
                                    .frame(maxWidth: 230)
                                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
                                }
                                .buttonStyle(ClickButtonStyle())
                            }.offset(y: Constants.screenWidth < 375 ? 60 : 10)
                        }
                        
                        //MARK: Main Dialog Cells
                        ForEach(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }, id: \.id) { i in
                            GeometryReader { geo in
                                DialogCell(dialogModel: i,
                                           isOpen: $isLocalOpen,
                                           activeView: $activeView,
                                           selectedDialogID: $selectedDialogID,
                                           showPinDetails: $showPinDetails)
                                    .environmentObject(auth)
                                    .contentShape(Rectangle())
                                    .position(x: i.isOpen && isLocalOpen ? UIScreen.main.bounds.size.width / 2 : UIScreen.main.bounds.size.width / 2 - 20, y: i.isOpen && isLocalOpen ? activeView.height + 40 : 40)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .zIndex(i.isOpen ? 2 : 0)
                                    .opacity(isLocalOpen ? (i.isOpen ? 1 : 0) : 1)
                                    .offset(y: i.isOpen && isLocalOpen ? -geo.frame(in: .global).minY + (emptyQuickSnaps ? (UIDevice.current.hasNotch ? 50 : 25) : 110) : emptyQuickSnaps ? -25 : 70)
                                    .shadow(color: Color.black.opacity(isLocalOpen ? (colorScheme == .dark ? 0.25 : 0.15) : 0.15), radius: isLocalOpen ? 15 : 8, x: 0, y: self.isLocalOpen ? (colorScheme == .dark ? 15 : 5) : 5)
                                    .animation(.spring(response: isLocalOpen ? 0.375 : 0.45, dampingFraction: isLocalOpen ? 0.65 : 0.8, blendDuration: 0))
                                    .id(i.id)
                                    .onTapGesture {
                                        onCellTapGesture(id: i.id, dialogType: i.dialogType)
                                    }.simultaneousGesture(DragGesture(minimumDistance: i.isOpen ? 0 : 500).onChanged { value in
                                        guard value.translation.height < 150 else { return }
                                        guard value.translation.height > 0 else { return }

                                        activeView = value.translation
                                    }.onEnded { value in
                                        if activeView.height > 50 {
                                            onCellTapGesture(id: i.id, dialogType: i.dialogType)
                                        }
                                        activeView.height = .zero
                                    })
                            }.frame(height: 75, alignment: .center)
                            .padding(.horizontal, isLocalOpen && i.isOpen ? 0 : 20)
                        }
                        .disabled(self.disableDialog)
                        .onChange(of: UserDefaults.standard.bool(forKey: "localOpen")) { _ in
                            disableDialog = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                disableDialog = false
                            }
                        }
                        .onAppear {
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            self.isLocalOpen = false
                        }
                        
                        if self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.count >= 3 {
                            FooterInformation()
                                .padding(.top, 140)
                                .padding(.bottom, 25)
                                .opacity(self.isLocalOpen ? 0 : 1)
                        }
                    }
                }.overlay(
                    //MARK: Chat Messages View
                    GeometryReader { geo in
                        ChatMessagesView(viewModel: self.messageViewModel, activeView: self.$activeView, keyboardChange: self.$keyboardHeight, dialogID: self.$selectedDialogID, textFieldHeight: self.$textFieldHeight, keyboardDragState: self.$keyboardDragState, hasAttachment: self.$hasAttachments, newDialogFromSharedContact: self.$newDialogFromSharedContact, namespace: self.namespace)
                            .environmentObject(self.auth)
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
                )
                .slideOverCard(isPresented: $showWelcomeNewUser, onDismiss: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }) {
                    EarlyAdopterView(counter: self.$counter)
                }

                //MARK: Keyboard View
                GeometryReader { geo in
                    KeyboardCardView(height: self.$textFieldHeight, isOpen: self.$isLocalOpen, mainText: self.$keyboardText, hasAttachments: self.$hasAttachments, showImagePicker: self.$showKeyboardMediaAssets, isKeyboardActionOpen: self.$isKeyboardActionOpen)
                        .environmentObject(self.auth)
                        .frame(width: Constants.screenWidth, height: Constants.screenHeight * 0.75, alignment: .center)
                        .shadow(color: Color.black.opacity(0.15), radius: 14, x: 0, y: -5)
                        .offset(y: self.isLocalOpen ? geo.frame(in: .global).maxY - 40 -
                            (UIDevice.current.hasNotch ? 0 : -20) - (self.textFieldHeight <= 180 ? self.textFieldHeight : 180) - (self.hasAttachments ? 110 : 0) - self.keyboardHeight + (self.isKeyboardActionOpen ? -80 : 0) : geo.frame(in: .global).maxY)
                        .zIndex(2)
                        .onChange(of: self.auth.visitContactProfile) { newValue in
                            if newValue {
                                self.showSharedContact.toggle()
                                self.auth.visitContactProfile = false
                            }
                        }.onChange(of: self.auth.visitPublicDialogProfile) { newValue in
                            if newValue {
                                print("did I make it this far lolll: \(newValue)")
                                if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                                    print("helooo we here: \(diaId) && \(self.auth.dynamicLinkPublicDialogID)")
                                }

                                self.showSharedPublicDialog.toggle()
                                self.auth.visitPublicDialogProfile = false
                            }
                        }
                        .onAppear {
                            self.selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
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

                if self.messageViewModel.isDetailOpen {
                    BubbleDetailView(viewModel: self.messageViewModel, namespace: self.namespace, newDialogFromSharedContact: self.$newDialogFromSharedContact)
                        .environmentObject(self.auth)
                        .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                        .zIndex(2)
                        .disabled(self.messageViewModel.isDetailOpen ? false : true)
                }
            } else {
                //MARK: LOCKED OUT VIEW
                LockedOutView()
            }

            //MARK: Quick Snap View
            QuickSnapStartView(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$selectedQuickSnapContact)
                .environmentObject(self.auth)
                .disabled(self.quickSnapViewState != .closed || self.auth.isLoacalAuth ? false : true)
                .opacity(self.auth.isLoacalAuth ? 0 : 1)
                .popup(isPresented: self.$receivedNotification, type: .floater(), position: .top, animation: Animation.spring(), autohideIn: 5, closeOnTap: true) {
                    NotificationSection()
                        .environmentObject(self.auth)
                }
            
            ConfettiCannon(counter: $counter, repetitions: 3, repetitionInterval: 0.2)
        }
    }
    
    func loadSelectedDialog() {
        if self.newDialogFromContact != 0 {
            for dia in dialogs.filterDia(text: self.searchText).filter({ $0.isDeleted != true }) {
                for occu in dia.occupentsID {
                    if occu == self.newDialogFromContact && dia.dialogType == "private" {
                        UserDefaults.standard.set(dia.id, forKey: "selectedDialogID")
                        self.selectedDialogID = dia.id
                        self.newDialogFromContact = 0
                        self.isLocalOpen = true
                        UserDefaults.standard.set(true, forKey: "localOpen")
                        changeDialogRealmData.shared.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: dia.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        
                        break
                    }
                }
                
                if self.newDialogFromContact == 0 { break }
            }

            if self.newDialogFromContact != 0 {
                let dialog = ChatDialog(dialogID: nil, type: .private)
                dialog.occupantIDs = [NSNumber(value: self.newDialogFromContact)]  // an ID of opponent

                Request.createDialog(dialog, successBlock: { (dialog) in
                    changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                        UserDefaults.standard.set(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id, forKey: "selectedDialogID")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            print("opening new dialog: \(self.newDialogID) & \(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")")
                            self.selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
                            self.isLocalOpen = true
                            UserDefaults.standard.set(self.isLocalOpen, forKey: "localOpen")
                            changeDialogRealmData.shared.updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")
                            self.newDialogFromContact = 0
                        }
                    })
                }) { (error) in
                    //occu.removeAll()
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    print("error making dialog: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadPublicDialog(diaId: String) {
        self.isLocalOpen = false
        UserDefaults.standard.set(false, forKey: "localOpen")
        changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: self.selectedDialogID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            UserDefaults.standard.set(diaId, forKey: "selectedDialogID")
            self.selectedDialogID = diaId
            self.newDialogFromContact = 0
            self.isLocalOpen = true
            UserDefaults.standard.set(true, forKey: "localOpen")
            changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: diaId)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UserDefaults.standard.set("", forKey: "openingDialogId")
        }
    }
    
    func onCellTapGesture(id: String, dialogType: String) {
        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        UserDefaults.standard.set(id, forKey: "selectedDialogID")
        
        if !UserDefaults.standard.bool(forKey: "localOpen") {
            UserDefaults.standard.set(true, forKey: "localOpen")
            withAnimation {
                self.isLocalOpen = true
                self.selectedDialogID = id
            }
            changeDialogRealmData.shared.updateDialogOpen(isOpen: true, dialogID: id)
        } else {

            self.isLocalOpen = false
            UserDefaults.standard.set(false, forKey: "localOpen")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: id)

                Request.cancelAllRequests({
                    if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                        changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: diaId)
                    } else {
                        changeDialogRealmData.shared.fetchDialogs(completion: { _ in
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
                    changeDialogRealmData.shared.updateDialogOpen(isOpen: false, dialogID: id)
                    
                    changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                        if dialogType == "group" || dialogType == "public" {
                            self.auth.leaveDialog()
                        }
                    })

                    if let diaId = UserDefaults.standard.string(forKey: "visitingDialogId"), !diaId.isEmpty {
                        UserDefaults.standard.set("", forKey: "visitingDialogId")
                        changeDialogRealmData.shared.unsubscribePublicConnectyDialog(dialogID: diaId)
                    }
                })
            }
        }
        self.activeView.height = .zero
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
