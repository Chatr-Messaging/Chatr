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
import SDWebImageSwiftUI
import PopupView
import RealmSwift
import LocalAuthentication
import UserNotifications


// MARK: Preview View
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            if #available(iOS 14.0, *) {
                mainHomeList(showNewChat: .constant(false), showContacts: .constant(false), showUserProfile: .constant(false))
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
    @State var showNewChat: Bool = false
    @State var showContacts: Bool = false
    @State var showUserProfile: Bool = false

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
                            print("View did appear. the sesh avalible: \(Session.current.tokenHasExpired) Session Details: \(String(describing: Session.current.sessionDetails)) && the facID: \(String(describing: self.auth.profile.results.first?.isLocalAuthOn))")
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
            
            mainHomeList(showNewChat: self.$showNewChat,
                         showContacts: self.$showContacts,
                         showUserProfile: self.$showUserProfile)
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
    @Binding var showNewChat: Bool
    @Binding var showContacts: Bool
    @Binding var showUserProfile: Bool
    @State var searchText: String = String()
    @State var keyboardText: String = String()
    @State var selectedDialogID: String = String()
    @State var newDialogID: String = ""
    @State var newDialogFromContact: Int = 0
    @State var newDialogFromSharedContact: Int = 0
    @State var isPreLoading = false
    @State var isLoading = false
    @State var showFullKeyboard = false
    @State var emptyQuickSnaps: Bool = false
    @State var hasAttachments: Bool = false
    @State var showSharedContact: Bool = false
    @State var receivedNotification: Bool = false
    @State var disableDialog: Bool = false
    @State var alertNum = 0
    @State var isLocalOpen : Bool = UserDefaults.standard.bool(forKey: "localOpen")
    @State var activeView = CGSize.zero
    @State var keyboardDragState = CGSize.zero
    @State var keyboardHeight: CGFloat = 0
    @State var textFieldHeight: CGFloat = 0
    @State var selectedContacts: [Int] = []
    @State var chatMessageViewHeight: CGFloat = 0
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var selectedQuickSnapContact: ContactStruct = ContactStruct()
    @Namespace var dialogNamespace
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))
    let wallpaperNames = ["", "SoftChatBubbles_DarkWallpaper", "SoftPaperAirplane-Wallpaper", "oldHouseWallpaper", "nycWallpaper", "michaelAngelWallpaper"]
    
    var body: some View {
        ZStack {
            if !self.auth.isLoacalAuth && self.auth.isUserAuthenticated != .signedOut {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        
                        //MARK: Header Section
                        HomeHeaderSection(showUserProfile: self.$showUserProfile)
                            .environmentObject(self.auth)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.btnSize + 75)
                            .padding(.horizontal)
                            .padding(.top)
                            .sheet(isPresented: self.$showUserProfile, onDismiss: {
                                if self.auth.isUserAuthenticated != .signedOut {
                                    self.loadSelectedDialog()
                                    print("loading selected dialog \(self.newDialogFromContact)")
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
                                    }.buttonStyle(ClickButtonStyle())
                                }
                            }.onAppear {
                                //UserDefaults.standard.set(false, forKey: "localOpen")
                                //self.isLocalOpen = false
                                NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                                    print("received notification!! ;D \(self.auth.notificationtext)")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.receivedNotification.toggle()
                                }
                            }
                            
                        // MARK: "Message" Title
                        HomeMessagesTitle(isLocalOpen: self.$isLocalOpen, contacts: self.$showContacts, newChat: self.$showNewChat, showUserProfile: self.$showUserProfile, selectedContacts: self.$selectedContacts)
                            .frame(height: 50)
                            .environmentObject(self.auth)
                            .padding(.bottom, 25)
                            .sheet(isPresented: self.$showContacts, onDismiss: {
                                self.loadSelectedDialog()
                                print("loading selected dialog")
                            }) {
                                ContactsView(newDialogID: self.$newDialogFromContact, dismissView: self.$showContacts)
                                    .environmentObject(self.auth)
                                    .background(Color("bgColor"))
                                    .edgesIgnoringSafeArea(.all)
                            }
                            .onChange(of: self.newDialogFromSharedContact) { newValue in
                                print("the new value dialog from contact is: \(newValue)")
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
                                    .frame(width: Constants.screenWidth, height: Constants.screenHeight, alignment: .center)
                                    .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY : -35)
                                    .opacity(self.isLocalOpen ? Double((275 - self.activeView.height) / 150) : 0)
                                    .simultaneousGesture(DragGesture(minimumDistance: self.isLocalOpen ? 0 : 500).onChanged({ (_) in }))
                                    .sheet(isPresented: self.$showSharedContact, onDismiss: {
                                        self.loadSelectedDialog()
                                        print("loading selected dialog \(self.newDialogFromContact)")
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
                                    }
                                
                                //Wallpaper View
                                Image(self.wallpaperNames[UserDefaults.standard.integer(forKey: "selectedWallpaper")])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: Constants.screenWidth, height: Constants.screenHeight - 150)
                                    .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY + 150 : 0)
                                    .offset(y: self.isLocalOpen ? self.activeView.height : 0)
                                    .opacity(self.isLocalOpen ? Double((275 - self.activeView.height) / 150) : 0)
                                    .animation(.spring(response: 0.45, dampingFraction: self.isLocalOpen ? 0.65 : 0.75, blendDuration: 0))
                                    .simultaneousGesture(DragGesture(minimumDistance: self.isLocalOpen ? 0 : 500).onChanged({ (_) in }))
                                
                                QuickSnapsSection(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$selectedQuickSnapContact, emptyQuickSnaps: self.$emptyQuickSnaps)
                                    .environmentObject(self.auth)
                                    .frame(width: Constants.screenWidth)
                                    .offset(y: self.isLocalOpen ? -geometry.frame(in: .global).minY - (UIDevice.current.hasNotch ? -60 : 5) : 0)
                                    .offset(x: self.isLocalOpen ? (((self.activeView.height - 150) / 1.5) / 150) * 40 : 0, y: self.isLocalOpen ? self.activeView.height / 1.5 : 0)
                                    //.scaleEffect(self.isLocalOpen ? ((self.activeView.height / 150) * 22.5) / 150 + 0.85 : 1.0)
                                    .animation(.spring(response: 0.45, dampingFraction: self.isLocalOpen ? 0.55 : 0.75, blendDuration: 0))
                                    .padding(.vertical, self.emptyQuickSnaps ? 0 : 20)
                                
                            }.zIndex(5)
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
                        CustomSearchBar(searchText: self.$searchText, localOpen: self.$isLocalOpen, loading: self.$isLoading)
                            .opacity(self.isLocalOpen ? Double(self.activeView.height / 150) : 1)
                            .opacity(self.isLoading ? 0 : 1)
                            .opacity(self.dialogs.results.count != 0 ? 1 : 0)
                            .offset(y: self.isLocalOpen ? -75 + (self.activeView.height / 3) : 0)
                            .offset(y: self.emptyQuickSnaps ? -60 : 35)
                            .blur(radius: self.isLocalOpen ? ((950 - (self.activeView.height * 3)) / 600) * 2 : 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0))
                            .resignKeyboardOnDragGesture()
                            .sheet(isPresented: self.$showNewChat, onDismiss: {
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
                        
                        //MARK: Dialogs Section
                        if self.dialogs.results.filter { $0.isDeleted != true }.count == 0 {
                            VStack {
                                Spacer()
                                Image("NoChats")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(minWidth: Constants.screenWidth - 20, maxWidth: Constants.screenWidth)
                                    .frame(height: 250)
                                    .onAppear() {
                                        changeDialogRealmData.fetchDialogs(completion: { _ in })
                                    }
                                
                                Text("No Messages Found")
                                    .foregroundColor(.primary)
                                    .font(.system(size: 28))
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 10)
                                
                                Text("Start a new conversation!")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.secondary)
                                    .padding(.bottom, 30)
                                
                                Button(action: {
                                    self.showNewChat.toggle()
                                }) {
                                    Text("Start Conversation")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }.buttonStyle(MainButtonStyle())
                                .frame(height: 45)
                                .frame(minWidth: 220, maxWidth: 260)
                                .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
                                
                                Spacer()
                            }.offset(y: 30)
                        } else {
                            //Main Dialog Cells
                            VStack {
                                ForEach(self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }, id: \.self) { i in
                                    GeometryReader { geo in
                                        ZStack(alignment: .topLeading) {
                                            DialogCell(dialogModel: i,
                                                       isOpen: self.$isLocalOpen,
                                                       activeView: self.$activeView,
                                                       selectedDialogID: self.$selectedDialogID)
                                                .environmentObject(self.auth)
                                                .opacity(self.isLocalOpen ? (i.isOpen ? 1 : 0) : 1)
                                                .offset(y: i.isOpen && self.isLocalOpen ? -geo.frame(in: .global).minY + (self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 50 : 25) : 125) : self.emptyQuickSnaps ? -45 : 50)
                                                .offset(y: self.isLocalOpen ? self.activeView.height : 0)
                                                .shadow(color: Color.black.opacity(self.isLocalOpen ? (self.colorScheme == .dark ? 0.40 : 0.15) : 0.15), radius: self.isLocalOpen ? 15 : 8, x: 0, y: self.isLocalOpen ? (self.colorScheme == .dark ? 15 : 5) : 5)
                                                .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                                .zIndex(self.isLocalOpen ? 3 : -1)
                                                .id(i.id)
                                        }.onTapGesture {
                                            self.isLocalOpen.toggle()
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                                            UserDefaults.standard.set(i.id, forKey: "selectedDialogID")
                                            if !UserDefaults.standard.bool(forKey: "localOpen") {
                                                UserDefaults.standard.set(true, forKey: "localOpen")
                                                changeDialogRealmData().updateDialogOpen(isOpen: true, dialogID: i.id)
                                                print("opening dialog")
                                            } else {
                                                UserDefaults.standard.set(false, forKey: "localOpen")
                                                changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: i.id)
                                                changeDialogRealmData.fetchDialogs(completion: { _ in })
                                                if i.dialogType == "group" || i.dialogType == "public" {
                                                    self.auth.leaveDialog()
                                                }
                                                if self.keyboardText.count > 0 {
                                                    self.auth.selectedConnectyDialog?.sendUserStoppedTyping()
                                                }
                                                //changeDialogRealmData().updateDialogTypedText(text: self.keyboardText, dialogID: i.id)
                                            }
                                        }.gesture(DragGesture(minimumDistance: 0).onChanged { value in
                                            guard value.translation.height < 150 else { UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true); return }
                                            guard value.translation.height > 0 else { return }
                                            
                                            self.activeView = value.translation
                                        }.onEnded { value in
                                            if self.activeView.height > 50 {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                UserDefaults.standard.set(false, forKey: "localOpen")
                                                changeDialogRealmData().updateDialogOpen(isOpen: false, dialogID: i.id)
                                                //changeDialogRealmData().updateDialogTypedText(text: self.keyboardText, dialogID: i.id)
                                                changeDialogRealmData.fetchDialogs(completion: { _ in })

                                                self.isLocalOpen = false
                                                self.isLoading = false
                                                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                                            }
                                            self.activeView.height = .zero
                                            if i.dialogType == "group" || i.dialogType == "public" {
                                                self.auth.leaveDialog()
                                            }
                                            if self.keyboardText.count > 0 {
                                                self.auth.selectedConnectyDialog?.sendUserStoppedTyping()
                                            }
                                        })
                                    }
                                }.offset(y: 50)
                                .frame(height: 75, alignment: .center)
                                .simultaneousGesture(DragGesture(minimumDistance: UserDefaults.standard.bool(forKey: "localOpen") ? 0 : 500).onChanged({ (_) in }))
                                .padding(.horizontal, self.isLocalOpen ? 0 : 20)
                                .background(Color.clear)
                                .onAppear {
                                    //UserDefaults.standard.set(false, forKey: "localOpen")
                                    //ChatrApp.dialogs.getDialogUpdates() { result in }
                                    //self.dialogActions.fetchDialogs(completion: { result in })
                                }
                            }.disabled(self.disableDialog)
                            .onChange(of: UserDefaults.standard.bool(forKey: "localOpen")) { newValue in
                                print("did change dialog state - new value of: \(newValue)")
                                self.disableDialog = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                    self.disableDialog = false
                                }
                            }
                        }
                    }
                    
                    if self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.count >= 4 || self.dialogs.filterDia(text: self.searchText).filter { $0.isDeleted != true }.count == 0 {
                        FooterInformation()
                            .padding(.top, 120)
                            .padding(.bottom, 20)
                            .opacity(self.isLocalOpen ? 0 : 1)
                    }
                }

                //Chat View
                if UserDefaults.standard.bool(forKey: "localOpen") {
                    ChatMessagesView(activeView: self.$activeView, keyboardChange: self.$keyboardHeight, dialogID: self.$selectedDialogID, textFieldHeight: self.$textFieldHeight, keyboardDragState: self.$keyboardDragState, hasAttachment: self.$hasAttachments, newDialogFromSharedContact: self.$newDialogFromSharedContact)
                        .environmentObject(self.auth)
                        .frame(width: Constants.screenWidth, alignment: .bottom)
                        .frame(minHeight: 1)
                        .contentShape(Rectangle())
                        .offset(y: self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 124 : 88) : 198)
                        .padding(.bottom, self.emptyQuickSnaps ? (UIDevice.current.hasNotch ? 124 : 88) : 198)
                        .offset(y: self.activeView.height)// + (self.emptyQuickSnaps ? 25 : 197))
                        //height: Constants.screenHeight - 248 - (self.textFieldHeight < 120 ? self.textFieldHeight : 120) - self.keyboardHeight + self.keyboardDragState.height - (self.hasAttachments ? 95 : 0)
                        //.padding(.bottom, (self.textFieldHeight < 120 ? self.textFieldHeight : 120) + self.keyboardHeight - self.keyboardDragState.height + (self.hasAttachments ? 95 : 0) + 248)
                        .animation(.timingCurve(0.5, 0.8, 0.2, 1, duration: 0.30))
                        .opacity(self.isLocalOpen ? Double((190 - self.activeView.height) / 150) : 0)
                        .zIndex(0)
                        .simultaneousGesture(DragGesture(minimumDistance: 800).onChanged({ (_) in }))
                        .onDisappear {
                            self.auth.leaveDialog()
                        }
                        //.onAppear {
                            //self.chatMessageViewHeight = Constants.screenHeight - 248 - (self.textFieldHeight < 120 ? self.textFieldHeight : 120) - self.keyboardHeight + self.keyboardDragState.height - (self.hasAttachments ? 95 : 0)
                            //print("the geo for chat messag view is: \((self.textFieldHeight < 120 ? self.textFieldHeight : 120) + self.keyboardHeight + self.keyboardDragState.height + (self.hasAttachments ? 95 : 0)) & now: \(self.chatMessageViewHeight)")
                            //Perfect message view height below **DO NOT DELETE**
                            //Constants.screenHeight - 248 - (self.textFieldHeight < 120 ? self.textFieldHeight : 120) - self.keyboardHeight + self.keyboardDragState.height - (self.hasAttachments ? 95 : 0)
                            
//                                        UserDefaults.standard.set(false, forKey: "localOpen")
//                                        ChatrApp.messages.getMessageUpdates(dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "", completion: { newMessages in
//                                            print("Message view successfully pulled new messages!")
//                                        })
                        //}
                    }

                //keyboard View
                KeyboardCardView(height: self.$textFieldHeight, mainText: self.$keyboardText, hasAttachments: self.$hasAttachments)
                    .environmentObject(self.auth)
                    .frame(alignment: .center)
                    .background(BlurView(style: .systemThinMaterial)) //Color("bgColor")
                    .cornerRadius(20)
                    //.scaleEffect(1 - self.activeView.height / 2500)
                    //.offset(y: self.activeView.height / 6)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: -5)
                    .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.75))
                    .offset(y: self.isLocalOpen ? Constants.screenHeight - (UIDevice.current.hasNotch || self.keyboardHeight != 0 ? 50 : 30) - (self.textFieldHeight <= 120 ? self.textFieldHeight : 120) - self.keyboardHeight + self.keyboardDragState.height - (self.hasAttachments ? 95 : 0) : Constants.screenHeight)
                    .gesture(
                        DragGesture().onChanged { value in
                            self.keyboardDragState = value.translation
                            print("the drag keyboard is: \(self.keyboardDragState.height)")
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
                                //changeDialogRealmData().updateDialogTypedText(text: self.keyboardText, dialogID: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
                                self.keyboardHeight = 0
                                UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                            }
                        }
                        .onEnded { valueEnd in
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
                    ).onAppear {
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
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
                    changeDialogRealmData.fetchDialogs(completion: { _ in
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