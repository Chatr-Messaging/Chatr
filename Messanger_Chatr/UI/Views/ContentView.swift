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
                            ChatrApp.connect()
                            StoreReviewHelper.checkAndAskForReview()
                            
                            if self.auth.profile.results.first?.isLocalAuthOn ?? false {
                                self.auth.isLoacalAuth = true
                                let context = LAContext()
                                var error: NSError?

                                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                                    let reason = "Identify yourself!"

                                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                                        if success {
                                            self.auth.isLoacalAuth = false
                                        } else {
                                            // error
                                            print("error! logging in")
                                        }
                                    }
                                } else {
                                    // no biometry
                                    print("error with biometry!")
                                }
                            } else {
                                self.auth.isLoacalAuth = false
                            }
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
        .onAppear {
            self.auth.configureFirebaseStateDidChange()
        }
    }
}

// MARK: Main Home List
@available(iOS 14.0, *)
struct mainHomeList: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @EnvironmentObject var auth: AuthModel
    @Environment(\.colorScheme) var colorScheme
    @GestureState var isDragging = false
    @State var showContacts: Bool = false
    @State var showUserProfile: Bool = false
    @State var showNewChat: Bool = false
    @State var searchText: String = String()
    @State var keyboardText: String = String()
    @State var selectedDialogID: String = String()
    @State var newDialogID: String = ""
    @State var newDialogFromContact: Int = 0
    @State var newDialogFromSharedContact: Int = 0
    @State var showFullKeyboard = false
    @State var emptyQuickSnaps: Bool = false
    @State var hasAttachments: Bool = false
    @State var showSharedContact: Bool = false
    @State var receivedNotification: Bool = false
    @State var disableDialog: Bool = false
    @State var isLocalOpen : Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @State var activeView = CGSize.zero
    @State var keyboardDragState = CGSize.zero
    @State var keyboardHeight: CGFloat = 0
    @State var textFieldHeight: CGFloat = 0
    @State var selectedContacts: [Int] = []
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var selectedQuickSnapContact: ContactStruct = ContactStruct()
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
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 10)
                                .padding(.top)
                                .sheet(isPresented: self.$showUserProfile, onDismiss: {
                                    if self.auth.isUserAuthenticated != .signedOut {
                                        self.loadSelectedDialog()
                                    } else {
                                        self.auth.logOutFirebase()
                                        self.auth.logOutConnectyCube()
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
                                }
                        }.frame(height: Constants.btnSize + 100)
                            
                        // MARK: "Message" Title
                        HomeMessagesTitle(isLocalOpen: self.$isLocalOpen, contacts: self.$showContacts, newChat: self.$showNewChat, selectedContacts: self.$selectedContacts)
                            .frame(height: 50)
                            .environmentObject(self.auth)
                            .padding(.bottom, 45)
                            .sheet(isPresented: self.$showContacts, onDismiss: {
                                if self.auth.isUserAuthenticated != .signedOut {
                                    self.loadSelectedDialog()
                                } else {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                        self.auth.logOutFirebase()
                                        self.auth.logOutConnectyCube()
                                    }
                                }
                            }) {
                                ContactsView(newDialogID: self.$newDialogFromContact, dismissView: self.$showContacts)
                                    .environmentObject(self.auth)
                                    .background(Color("bgColor"))
                                    .edgesIgnoringSafeArea(.all)
                            }
                            .onChange(of: self.newDialogFromSharedContact) { newValue in
                                if newValue != 0 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
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
                                    .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY - (UIDevice.current.hasNotch ? -60 : 5) : 0)
                                    .offset(y: self.isLocalOpen ? self.activeView.height / 1.5 : 0)
                                    //.scaleEffect(self.isLocalOpen ? ((self.activeView.height / 150) * 22.5) / 150 + 0.85 : 1.0)
                                    .animation(.spring(response: 0.45, dampingFraction: self.isLocalOpen ? 0.65 : 0.75, blendDuration: 0))
                                    .padding(.vertical, self.emptyQuickSnaps ? 0 : 20)
                            }
                        }.sheet(isPresented: self.$showNewChat, onDismiss: {
                            if self.newDialogID.count > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                                    self.isLocalOpen = true
                                    UserDefaults.standard.set(self.isLocalOpen, forKey: "localOpen")
                                    changeDialogRealmData().updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")
                                    UserDefaults.standard.set(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id, forKey: "selectedDialogID")
                                    self.newDialogID = ""
                                }
                            }
                        }) {
                            NewConversationView(usedAsNew: true, selectedContact: self.$selectedContacts, newDialogID: self.$newDialogID)
                                .environmentObject(self.auth)
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
                                .offset(y: self.emptyQuickSnaps ? -50 : 45)
                                .blur(radius: self.isLocalOpen ? ((950 - (self.activeView.height * 3)) / 600) * 2 : 0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0))
                                .resignKeyboardOnDragGesture()
                        }
                                                
                        //MARK: Dialogs Section
                        if self.dialogs.results.filter { $0.isDeleted != true }.count == 0 {
                            VStack {
                                Image("NoChats")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: Constants.screenWidth - 20, maxWidth: Constants.screenWidth)
                                    .frame(height: Constants.screenWidth < 375 ? 250 : 200)
                                    .padding(.horizontal, 10)
                                    .onAppear() {
                                        changeDialogRealmData().fetchDialogs(completion: { _ in })
                                    }
                                
                                Text("No Messages Found")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 28))
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 15)
                                    .padding(.bottom, 5)
                                
                                Text("Start a new conversation!")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.secondary)
                                    .padding(.bottom, 25)
                                
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
                            }.offset(y: Constants.screenWidth < 375 ? 60 : -30)
                        }
                        
                        //MARK: Main Dialog Cells
                        ForEach(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }, id: \.id) { i in
                            if self.isLocalOpen && i.isOpen && !self.disableDialog {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 75, alignment: .center)
                                    .padding(.all)
                            }
                            
                            GeometryReader { geo in
                                DialogCell(dialogModel: i,
                                           isOpen: self.$isLocalOpen,
                                           activeView: self.$activeView,
                                           selectedDialogID: self.$selectedDialogID)
                                    .environmentObject(self.auth)
                                    .contentShape(Rectangle())
                                    .position(x: self.isLocalOpen ? UIScreen.main.bounds.size.width / 2 : UIScreen.main.bounds.size.width / 2 - 20, y: i.isOpen ? 40 : 40)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .zIndex(i.isOpen ? 2 : 0)
                                    .opacity(self.isLocalOpen ? (i.isOpen ? 1 : 0) : 1)
                                    .offset(y: i.isOpen && self.isLocalOpen ? -geo.frame(in: .global).minY + (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 50 : 25) : 125) : self.emptyQuickSnaps ? -45 : 50)
                                    .offset(y: self.isLocalOpen ? self.activeView.height : 0)
                                    .shadow(color: Color.black.opacity(self.isLocalOpen ? (self.colorScheme == .dark ? 0.40 : 0.15) : 0.15), radius: self.isLocalOpen ? 15 : 8, x: 0, y: self.isLocalOpen ? (self.colorScheme == .dark ? 15 : 5) : 5)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.95, blendDuration: 0))
                                    .id(i.id)
                                    .onTapGesture {
                                        self.onCellTapGesture(id: i.id, dialogType: i.dialogType)
                                    }.simultaneousGesture(DragGesture(minimumDistance: i.isOpen ? 0 : 500).onChanged { value in
                                        guard value.translation.height < 150 else { return }
                                        guard value.translation.height > 0 else { return }
                                        
                                        self.activeView = value.translation
                                    }.onEnded { value in
                                        if self.activeView.height > 50 {
                                            self.onCellTapGesture(id: i.id, dialogType: i.dialogType)
                                        }
                                        self.activeView.height = .zero
                                    })
                            }.frame(height: 75, alignment: .center)
                            .padding(.horizontal, self.isLocalOpen ? 0 : 20)
                        }.offset(y: 60)
                        .disabled(self.disableDialog)
                        .onChange(of: UserDefaults.standard.bool(forKey: "localOpen")) { _ in
                            self.disableDialog = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.disableDialog = false
                            }
                        }
                        //.onAppear {
                            //UserDefaults.standard.set(false, forKey: "localOpen")
                            //ChatrApp.dialogs.getDialogUpdates() { result in }
                        //}

                        if self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.count >= 3 {
                            FooterInformation()
                                .padding(.top, 140)
                                .padding(.bottom, 25)
                                .opacity(self.isLocalOpen ? 0 : 1)
                        }
                    }
                }
                
                //MARK: Chat Messages View
                if UserDefaults.standard.bool(forKey: "localOpen") {
                    GeometryReader { geo in
                        ChatMessagesView(activeView: self.$activeView, keyboardChange: self.$keyboardHeight, dialogID: self.$selectedDialogID, textFieldHeight: self.$textFieldHeight, keyboardDragState: self.$keyboardDragState, hasAttachment: self.$hasAttachments, newDialogFromSharedContact: self.$newDialogFromSharedContact)
                            .environmentObject(self.auth)
                            .frame(width: Constants.screenWidth, height: Constants.screenHeight - (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 123 : 87) : 197), alignment: .bottom)
                            .zIndex(1)
                            .contentShape(Rectangle())
                            .offset(y: -geo.frame(in: .global).minY + (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 123 : 87) : 197))
                            .padding(.bottom, self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 123 : 87) : 197)
                            .offset(y: self.activeView.height) // + (self.emptyQuickSnaps ? 25 : 197))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0))
                            .simultaneousGesture(DragGesture(minimumDistance: UserDefaults.standard.bool(forKey: "localOpen") ? 800 : 0))
                            .layoutPriority(1)
                            .onDisappear {
                                self.auth.leaveDialog()
                            }
                    }
                }

                //MARK: Keyboard View
                KeyboardCardView(height: self.$textFieldHeight, isOpen: self.$isLocalOpen, mainText: self.$keyboardText, hasAttachments: self.$hasAttachments)
                    .environmentObject(self.auth)
                    .frame(alignment: .center)
                    .background(BlurView(style: .systemUltraThinMaterial)) //Color("bgColor")
                    .cornerRadius(20)
                    //.scaleEffect(1 - self.activeView.height / 2500)
                    //.offset(y: self.activeView.height / 6)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
                    .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5))
                    .offset(y: self.isLocalOpen ? Constants.screenHeight - (UIDevice.current.hasNotch || self.keyboardHeight != 0 ? 50 : 30) - (self.textFieldHeight <= 120 ? self.textFieldHeight : 120) - self.keyboardHeight + self.keyboardDragState.height - (self.hasAttachments ? 95 : 0) : Constants.screenHeight)
                    .zIndex(2)
                    .gesture(DragGesture().onChanged { value in
                            self.keyboardDragState = value.translation
                            if self.showFullKeyboard {
                                self.keyboardDragState.height += -100
                            }
                            if self.keyboardDragState.height < -120 {
                                self.keyboardDragState.height = -110
                            }
                            if self.keyboardDragState.height > 100 {
                                self.keyboardDragState.height = 110
                            }
                            if self.keyboardDragState.height > 50 {
                                self.keyboardHeight = 0
                                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    UserDefaults.standard.setValue(self.keyboardText, forKey: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "" + "typedText")
                                }
                            }
                        }.onEnded { valueEnd in
                            if self.keyboardDragState.height > 50 {
                                self.showFullKeyboard = false
                                self.keyboardDragState = .zero
                                self.keyboardHeight = 0
                                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            if self.keyboardDragState.height < -50 {
                                self.keyboardDragState.height = -100
                                self.showFullKeyboard = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            } else {
                                self.keyboardDragState = .zero
                                self.showFullKeyboard = false
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    ).sheet(isPresented: self.$showSharedContact, onDismiss: {
                        if self.newDialogFromContact != 0 {
                            self.isLocalOpen = false
                            UserDefaults.standard.set(false, forKey: "localOpen")
                            changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: "\(self.newDialogFromContact)")
                        }
                        self.loadSelectedDialog()
                    }) {
                        NavigationView {
                            VisitContactView(fromDialogCell: true, newMessage: self.$newDialogFromContact, dismissView: self.$showSharedContact, viewState: .fromDynamicLink)
                                .environmentObject(self.auth)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                    .onChange(of: self.auth.visitContactProfile) { newValue in
                        if newValue {
                            self.showSharedContact.toggle()
                            self.auth.visitContactProfile = false
                        }
                    }.onAppear {
                        self.selectedDialogID = UserDefaults.standard.string(forKey: "selectedDialogID") ?? ""
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (data) in
                            let height1 = data.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                            self.keyboardHeight = height1.cgRectValue.height - 20
                        }
                        
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
                            self.keyboardHeight = 0
                        }
                    }
                
//                GeometryReader { geometry in
//                    NotificationSection()
//                        .environmentObject(self.auth)
//                        .offset(y: self.receivedNotification ? -geometry.frame(in: .global).minY + (UIDevice.current.hasNotch ? 40 : 25) : -geometry.frame(in: .global).minY - 80)
//                        .animation(.spring(response: 0.65, dampingFraction: 0.55, blendDuration: 0))
//                        .onAppear() {
//                            NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
//                                print("received notification!! ;D \(self.auth.notificationtext)")
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                self.receivedNotification = true
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                                    self.receivedNotification = false
//                                }
//                            }
//                        }.onTapGesture {
//                            if self.receivedNotification {
//                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
//                                self.receivedNotification = false
//                            }
//                        }
//                }
                
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
        }
    }
    
    func loadSelectedDialog() {
        if self.newDialogFromContact != 0 {
            for dia in dialogs.filterDia(text: self.searchText).filter({ $0.isDeleted != true }) {
                for occu in dia.occupentsID {
                    if occu == self.newDialogFromContact && dia.dialogType == "private" {
                        self.newDialogFromContact = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                            self.isLocalOpen = true
                            UserDefaults.standard.set(true, forKey: "localOpen")
                            changeDialogRealmData().updateDialogOpen(isOpen: self.isLocalOpen, dialogID: dia.id)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            UserDefaults.standard.set(dia.id, forKey: "selectedDialogID")
                        }
                        
                        break
                    }
                }
            }

            if self.newDialogFromContact != 0 {
                let dialog = ChatDialog(dialogID: nil, type: .private)
                dialog.occupantIDs = [NSNumber(value: self.newDialogFromContact)]  // an ID of opponent

                Request.createDialog(dialog, successBlock: { (dialog) in
                    changeDialogRealmData().fetchDialogs(completion: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            print("opening new dialog: \(self.newDialogID) & \(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")")
                            self.isLocalOpen = true
                            UserDefaults.standard.set(self.isLocalOpen, forKey: "localOpen")
                            changeDialogRealmData().updateDialogOpen(isOpen: self.isLocalOpen, dialogID: self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id ?? "")
                            UserDefaults.standard.set(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.last?.id, forKey: "selectedDialogID")
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
    
    func onCellTapGesture(id: String, dialogType: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        self.selectedDialogID = id
        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
        UserDefaults.standard.set(id, forKey: "selectedDialogID")
        if !UserDefaults.standard.bool(forKey: "localOpen") {
            self.isLocalOpen = true
            UserDefaults.standard.set(true, forKey: "localOpen")
            changeDialogRealmData().updateDialogOpen(isOpen: true, dialogID: id)
        } else {
            self.isLocalOpen = false
            UserDefaults.standard.set(false, forKey: "localOpen")
            changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                changeDialogRealmData().fetchDialogs(completion: { _ in })
                if dialogType == "group" || dialogType == "public" {
                    self.auth.leaveDialog()
                }
            }
        }
    }
    
    func onChanged(value: DragGesture.Value, index: Int){
        guard value.translation.height < 150 else { UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true); return }
        guard value.translation.height > 0 else { return }
        
        self.activeView = value.translation
    }
    
    func onEnd(value: DragGesture.Value, index: Int, id: String, dialogType: String) {
        if self.activeView.height > 50 {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
            UserDefaults.standard.set(false, forKey: "localOpen")
            changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: id)
            changeDialogRealmData().fetchDialogs(completion: { _ in })
            self.isLocalOpen = false
        }
        self.activeView.height = .zero
        
        if dialogType == "group" || dialogType == "public" {
            self.auth.leaveDialog()
        }
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
