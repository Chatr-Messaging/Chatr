//
//  VisitContactView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/29/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import MessageUI
import ConnectyCube
import RealmSwift
import PopupView
import Grid

struct VisitContactView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    var fromDialogCell: Bool = false
    @ObservedObject var viewModel = VisitContactViewModel()
    @Binding var newMessage: Int
    @Binding var dismissView: Bool
    @State var viewState: visitUserState = .unknown
    @State var contactRelationship: visitContactRelationship = .unknown
    @State var contact: ContactStruct = ContactStruct()
    @State var connectyContact: User = User()
    @State var igImageStyle = StaggeredGridStyle(.horizontal, tracks: .count(2), spacing: 2.5)
    @State var isProfileImgOpen: Bool = false
    @State var isProfileBioOpen: Bool = false
    @State var isUrlOpen: Bool = false
    @State private var showingMoreSheet = false
    @State var showForwardContact = false
    @State var receivedNotification: Bool = false
    @State var newDialogID: String = ""
    @State var selectedContact: [Int] = []
    @State var profileViewSize = CGSize.zero
    @State var selectedImageUrl = ""
    @State var contactWebsiteUrl: String = ""
    @State var scrollOffset: CGFloat = CGFloat.zero
    @State var quickSnapViewState: QuickSnapViewingState = .closed
    @State var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false
    var columns: [GridItem] = [
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5),
        GridItem(.flexible(), spacing: 5)
    ]

    var body: some View {
        ZStack(alignment: .center) {
            ScrollView(.vertical, showsIndicators: true) {
                //MARK: Top Profile
                topHeaderContactView(viewModel: self.viewModel, contact: self.$contact, quickSnapViewState: self.$quickSnapViewState, isProfileImgOpen: self.$isProfileImgOpen, isProfileBioOpen: self.$isProfileBioOpen, selectedImageUrl: self.$selectedImageUrl)
                    .environmentObject(self.auth)
                    .padding(.top)
                    .background(GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self,
                            value: -$0.frame(in: .named("visitContact-scroll")).origin.y)
                    })
                    .onPreferenceChange(ViewOffsetKey.self) {
                        self.scrollOffset = $0
                    }

                //MARK: Action Buttons
                actionButtonView(viewModel: self.viewModel, contact: self.$contact, quickSnapViewState: self.$quickSnapViewState, contactRelationship: self.$contactRelationship, newMessage: self.$newMessage, dismissView: self.$dismissView)
                    .padding(.vertical, 15)
                    .padding(.bottom, 15)

                //MARK: Social Section
                if self.contact.facebook != "" || self.contact.twitter != "" || self.contact.instagramAccessToken != "" {
                    if self.contact.instagramAccessToken != "" && (!self.contact.isInfoPrivate || self.contactRelationship == .contact) {
                        VStack(spacing: 0) {
                            if !self.viewModel.igMedia.isEmpty {
                                Button(action: {
                                    if !self.contact.isInfoPrivate || self.contactRelationship == .contact {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.viewModel.openInstagramApp()
                                    } else {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    }
                                }) {
                                    HStack(alignment: .center) {
                                        Image("instagramIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(.trailing, 5)

                                        Text("@\(self.viewModel.username) testeraccount")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .background(self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") ? Color.clear : !self.contact.isInfoPrivate || self.contactRelationship == .contact ? Color.clear : Color.secondary)
                                            .foregroundColor(self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") ? .secondary : !self.contact.isInfoPrivate || self.contactRelationship == .contact ? self.viewModel.username == "" ? .gray : .primary : .clear)

                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal, 40)
                                    .padding(.vertical, 12.5)
                                }.buttonStyle(ClickMiniButtonStyle())
                            
                                ScrollView(igImageStyle.axes) {
                                    Grid(self.viewModel.igMedia.sorted{ $0.timestamp > $1.timestamp }, id: \.self) { index in
                                        Button(action: {
                                            self.selectedImageUrl = index.media_url
                                            self.isProfileImgOpen.toggle()
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        }, label: {
                                            WebImage(url: URL(string: index.media_url))
                                                .resizable()
                                                .placeholder{ Image("empty-profile").resizable().scaledToFill() }
                                                .indicator(.activity)
                                                .scaledToFit()
                                        }).buttonStyle(ClickMiniButtonStyle())
                                    }.gridStyle(self.igImageStyle)
                                    .cornerRadius(10)
                                    .frame(minHeight: 300, maxHeight: 300, alignment: .center)
                                    .padding(.leading)
                                }.padding(.trailing)
                                .padding(.vertical, 10)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
                                .padding(.bottom, 10)
                            }
                        }
                    }
                }
                
                //MARK: Info Section
                miniHeader(title: "INFO:", doubleIndent: false)
                    .padding(.horizontal, 10)
                
                self.viewModel.styleBuilder(content: {
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack {
                            Image(systemName: "phone")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .frame(width: 20, height: 20, alignment: .center)
                                .padding(.trailing, 5)
                            
                            Text(self.contact.phoneNumber.format(phoneNumber: String(self.contact.phoneNumber.dropFirst())))
                                .font(.none)
                                .fontWeight(.none)
                                .background((self.contact.isInfoPrivate && self.contactRelationship != .contact) || (self.contactRelationship != .pendingRequestForYou && self.contactRelationship != .contact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID")) ? Color.secondary : Color.clear)
                                .foregroundColor((self.contact.isInfoPrivate && self.contactRelationship != .contact) || (self.contactRelationship != .pendingRequestForYou && self.contactRelationship != .contact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID")) ? .clear : .primary)
                                
                            Spacer()
                        }.padding(.horizontal)
                        .padding(.vertical, self.contact.emailAddress != "empty email address" && self.contact.website != "empty website" && !self.contact.isInfoPrivate ? 12.5 : 15)
                        
                        if self.contact.emailAddress != "empty email address" && self.contact.website != "empty website" && !self.contact.isInfoPrivate {
                            Divider()
                                .frame(width: Constants.screenWidth - 80)
                        }
                    }
                
                    //MARK: Email Address Section
                    if self.contact.emailAddress != "empty email address" && !self.contact.isInfoPrivate {
                        Button(action: {
                            if MFMailComposeViewController.canSendMail() && self.contact.emailAddress != "empty email address" && !self.contact.isInfoPrivate {
                                self.isShowingMailView.toggle()
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(alignment: .center) {
                                    Image(systemName: "envelope")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(self.contact.emailAddress == "empty email address" ? .gray : .primary)
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .padding(.trailing, 5)

                                    Text(self.contact.emailAddress)
                                        .font(.none)
                                        .fontWeight(.none)
                                        .background(self.contact.isInfoPrivate ? Color.secondary : Color.clear)
                                        .foregroundColor(self.contact.isInfoPrivate ? .clear : self.contact.emailAddress == "empty email address" ? .gray : .primary)

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
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                        .sheet(isPresented: $isShowingMailView) {
                            MailView(isShowing: self.$isShowingMailView, result: self.$mailResult, emailAddress: self.contact.emailAddress)
                        }
                    }

                    //MARK: Website Section
                    if self.contact.website != "empty website" && !self.contact.isInfoPrivate {
                        Button(action: {
                            if self.contact.website != "empty website" && !self.contact.isInfoPrivate {
                                //UIApplication.shared.open(URL(string:self.contact.website)!)
                                self.isUrlOpen.toggle()
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            } else {
                                print("website is empty")
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "safari")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(self.contact.website == "empty website" ? .gray : .primary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)

                                Text(self.contact.website)
                                    .font(.none)
                                    .fontWeight(.none)
                                    .background(self.contact.isInfoPrivate ? Color.secondary : Color.clear)
                                    .foregroundColor(self.contact.isInfoPrivate ? .clear : self.contact.website == "empty website" ? .gray : .primary)

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
                        .sheet(isPresented: self.$isUrlOpen, content: {
                            NavigationView {
                                WebsiteView(websiteUrl: self.$contactWebsiteUrl)
                            }
                        })
                    }
                }).padding(.bottom, 10)

                //MARK: Action Section
                miniHeader(title: "ACTIONS:", doubleIndent: false)
                    .padding(.horizontal, 10)
                
                self.viewModel.styleBuilder(content: {
                    //QR Code button
                    NavigationLink(destination: ShareProfileView(dimissView: self.$dismissView,
                                                                contactID: self.contact.id,
                                                                contactFullName: self.contact.fullName,
                                                                contactAvatar: self.contact.avatar)
                                    .environmentObject(self.auth)) {
                        VStack(alignment: .trailing, spacing: 0) {
                            HStack {
                                Image(systemName: "qrcode")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.primary)
                                    .frame(width: 20, height: 20, alignment: .center)
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
                            .padding(.vertical, 12.5)
                                
                            Divider()
                                .frame(width: Constants.screenWidth - 80)
                        }
                    }.buttonStyle(changeBGButtonStyle())
                    .simultaneousGesture(TapGesture()
                        .onEnded { _ in
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        })
                    
                    //MARK: Fav Btn Section
                    if self.contact.isMyContact {
                        Button(action: {
                            if self.contact.isFavourite {
                                self.viewModel.updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: false)
                            } else {
                                self.viewModel.updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: true)
                            }
                        }) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack(alignment: .center) {
                                    Image(systemName: self.contact.isFavourite ? "star.fill" : "star")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(self.contact.isFavourite ? Color.yellow : Color.primary)
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("Favorite")
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
                                .padding(.vertical, 12.5)
                                
                                Divider()
                                    .frame(width: Constants.screenWidth - 80)
                            }
                        }.buttonStyle(changeBGButtonStyle())
                        .simultaneousGesture(TapGesture()
                            .onEnded { _ in
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            })
                    }
                    
                    Button(action: {
                        self.showForwardContact.toggle()
                    }) {
                        HStack {
                            Image(systemName: "arrowshape.turn.up.left")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .frame(width: 20, height: 20, alignment: .center)
                                .padding(.trailing, 5)
                            
                            Text("Forward Contact")
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
                        .padding(.vertical, 12.5)
                    }.buttonStyle(changeBGButtonStyle())
                    .simultaneousGesture(TapGesture()
                        .onEnded { _ in
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        })
                }).padding(.bottom, 10)
                .sheet(isPresented: self.$showForwardContact, onDismiss: {
                    if self.selectedContact.count > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                            self.forwardContact()
                        }
                    }
                }) {
                    NewConversationView(usedAsNew: false, forwardContact: true, selectedContact: self.$selectedContact, newDialogID: self.$newDialogID)
                        .environmentObject(self.auth)
                }
                
                //MARK: More Section
                miniHeader(title: "MORE:", doubleIndent: false)
                    .padding(.horizontal, 10)
                
                self.viewModel.styleBuilder(content: {
                    Button(action: {
                        self.showingMoreSheet.toggle()
                    }) {
                        HStack {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.primary)
                                .frame(width: 20, height: 20, alignment: .center)
                                .padding(.trailing, 5)
                            
                            Text("more...")
                                .font(.none)
                                .fontWeight(.none)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .resizable()
                                .font(Font.title.weight(.bold))
                                .scaledToFit()
                                .frame(width: 7, height: 15, alignment: .center)
                                .foregroundColor(.secondary)
                        }.padding(.horizontal)
                        .padding(.vertical, 15)
                    }.buttonStyle(changeBGButtonStyle())
                    .frame(minWidth: 100, maxWidth: Constants.screenWidth)
                    .actionSheet(isPresented: $showingMoreSheet) {
                        ActionSheet(title: Text("More..."), message: nil, buttons: [.default(Text(self.contactRelationship == .contact ? "Remove from Contacts" : self.contactRelationship == .pendingRequest ? "Pending..." : self.contactRelationship == .pendingRequestForYou ? "waiting for you..." : "Add Contact"), action: {
                                self.viewModel.actionSheetMoreBtn(contactRelationship: self.contactRelationship, contactId: self.contact.id, completion: { contactState in
                                    self.contactRelationship = contactState
                                })
                        }),
                        .destructive(Text("Block & Report \(self.contact.fullName.components(separatedBy: " ").first ?? " ")"), action: {
                            let privateChatPrivacyItem = PrivacyItem.init(privacyType: .userID, userID: UInt(self.contact.id), allow: false)
                            privateChatPrivacyItem.mutualBlock = true
                            let groupChatPrivacyItem = PrivacyItem.init(privacyType: .groupUserID, userID: UInt(self.contact.id), allow: false)
                            let privacyList = PrivacyList.init(name: "PrivacyList", items: [privateChatPrivacyItem, groupChatPrivacyItem])
                            changeContactsRealmData.shared.deleteContact(contactID: self.contact.id, isMyContact: false, completion: { _ in })
                            Chat.instance.setPrivacyList(privacyList)
                            self.contactRelationship = .unknown
                        }), .cancel(Text("Done"))])
                    }
                }).padding(.bottom, 60)
                
                //MARK: Footer Section
                FooterInformation(middleText: "joined \(self.contact.createdAccount.getFullElapsedInterval())")
                    .padding(.bottom, 30)
            }
            .coordinateSpace(name: "visitContact-scroll")
            .background(Color("bgColor"))
            .popup(isPresented: self.$receivedNotification, type: .floater(), position: .bottom, animation: Animation.spring(), autohideIn: 4, closeOnTap: true) {
                NotificationSection()
                    .environmentObject(self.auth)
            }
            .navigationBarHidden(self.quickSnapViewState == .camera || self.quickSnapViewState == .takenPic)
            .navigationTitle(self.scrollOffset > 152 ? self.contact.fullName : "")
            .navigationBarItems(leading:
                Button(action: {
                    withAnimation {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text(self.fromDialogCell ? "Done" : "")
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }.disabled(self.fromDialogCell ? false : true)
            )

            //MARK: Other Views
            //See profile image
            ZStack(alignment: .center) {
                BlurView(style: .systemUltraThinMaterial)
                    .opacity(self.isProfileImgOpen || self.quickSnapViewState == .camera || self.quickSnapViewState == .takenPic ? Double(150 - abs(self.profileViewSize.height)) / 150 : 0)
                    .animation(.linear(duration: 0.15))
                
                VStack(alignment: .trailing, spacing: 15) {
                    if isProfileImgOpen {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.isProfileImgOpen = false
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(width: 40, height: 40, alignment: .center)
                                    .foregroundColor(Color("bgColor"))
                                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15, alignment: .center)
                                    .foregroundColor(.primary)
                            }
                        }.buttonStyle(ClickButtonStyle())
                        .padding(.horizontal)
                        .opacity(self.isProfileImgOpen ? Double(150 - self.profileViewSize.height) / 150 : 0)
                        .offset(y: self.profileViewSize.height / 3)

                        WebImage(url: URL(string: self.selectedImageUrl))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: Constants.screenWidth - 40, height: Constants.screenWidth - 40, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .cornerRadius(self.isProfileImgOpen ? abs(self.profileViewSize.height) + 15 : 100)
                            .aspectRatio(contentMode: .fit)
                            .transition(.fade(duration: 0.25))
                            .frame(width: Constants.screenWidth - 40, alignment: .center)
                            .frame(minHeight: 150)
                            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 15)
                            .opacity(self.isProfileImgOpen ? Double(225 - self.profileViewSize.height) / 225 : 0)
                            .offset(x: self.profileViewSize.width, y: self.profileViewSize.height)
                            .scaleEffect(self.isProfileImgOpen ? 1 - abs(self.profileViewSize.height) / 500 : 0, anchor: .topLeading)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.spring(response: 0.2, dampingFraction: 0.65, blendDuration: 0)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.14))))
                            .animation(.spring(response: 0.30, dampingFraction: 0.7, blendDuration: 0))
                            .pinchToZoom()
                            .gesture(DragGesture(minimumDistance: self.isProfileImgOpen ? 0 : Constants.screenHeight).onChanged { value in
                                guard value.translation.height < 175 else { return }
                                guard value.translation.height > -175 else { return }
                                print("height: \(value.translation.height)")
                                if self.isProfileImgOpen {
                                    self.profileViewSize = value.translation
                                }
                            }.onEnded { value in
                                if self.profileViewSize.height > 100 {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isProfileImgOpen = false
                                } else if self.profileViewSize.height < -100 {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isProfileImgOpen = false
                                }

                            }.sequenced(before: TapGesture().onEnded({
                                if self.profileViewSize.height == 0 {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.isProfileImgOpen = false
                                } else {
                                    self.profileViewSize = .zero
                                }
                            }))).onAppear(){
                                self.profileViewSize = CGSize.zero
                            }.onDisappear() {
                                self.profileViewSize = CGSize.zero
                            }
                    }
                }
            }
            
            //MARK: Quick Snap View
            QuickSnapStartView(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$contact)
                .environmentObject(self.auth)
                .disabled(self.quickSnapViewState != .closed ? false : true)
        }.onAppear() {
            DispatchQueue.main.async {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                    self.receivedNotification.toggle()
                }
                
                if self.viewState == .fromSearch {
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.connectyContact.id != 0 ? Int(self.connectyContact.id) : self.contact.id) {
                            if foundContact.isMyContact {
                                self.contact = foundContact
                                self.contactWebsiteUrl = self.contact.website
                                if foundContact.instagramAccessToken != "" && foundContact.instagramId != 0 {
                                    self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: foundContact.instagramAccessToken, user_id: foundContact.instagramId))
                                }
                                if self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                                    self.contactRelationship = .unknown
                                } else if self.contact.id != 0 {
                                    self.contactRelationship = .contact
                                }
                            } else {
                                self.contactRelationship = .notContact
                                
                                for i in Chat.instance.contactList?.pendingApproval ?? [] {
                                    if i.userID == self.connectyContact.id {
                                        self.contactRelationship = .pendingRequest
                                        break
                                    }
                                }
                                
                                guard let profile = self.auth.profile.results.first else {
                                    return
                                }

                                if profile.contactRequests.contains(where: { $0 == self.contact.id }) {
                                    self.contactRelationship = .pendingRequestForYou
                                }
                            }
                        } else {
                            //not in realm and not a contact - check if pending
                            self.pullNonContact()
                        }
                    } catch { }
                } else if self.viewState == .fromContacts {
                    self.contactRelationship = .contact
                    changeContactsRealmData.shared.observeFirebaseContact(contactID: self.contact.id)
                    if self.contact.instagramAccessToken != "" && self.contact.instagramId != 0 {
                        self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: self.contact.instagramAccessToken, user_id: self.contact.instagramId))
                    }
                    self.contactWebsiteUrl = self.contact.website
                } else if self.viewState == .fromRequests {
                    print("shuld have everything already...")
                    if self.contact.instagramAccessToken != "" && self.contact.instagramId != 0 {
                        self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: self.contact.instagramAccessToken, user_id: self.contact.instagramId))
                    }
                    self.contactWebsiteUrl = self.contact.website
                } else if self.viewState == .fromGroupDialog {
                    if self.contact.instagramAccessToken != "" && self.contact.instagramId != 0 {
                        self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: self.contact.instagramAccessToken, user_id: self.contact.instagramId))
                    }
                    
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.contact.id) {
                            self.contactRelationship = foundContact.isMyContact ? .contact : .notContact
                            self.contactWebsiteUrl = foundContact.website
                        }
                        
                        if self.contactRelationship == .notContact || (self.contactRelationship == .unknown && self.auth.profile.results.first?.id != self.contact.id) {
                            self.pullNonContact()
                        }
                    } catch {
                        print("error catching realm error")
                    }
                }
                else if self.viewState == .fromDynamicLink {
                    if self.auth.dynamicLinkContactID != 0 {
                        let config = Realm.Configuration(schemaVersion: 1)
                        do {
                            let realm = try Realm(configuration: config)
                            if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.auth.dynamicLinkContactID) {
                                if foundContact.isMyContact {
                                    self.contact = foundContact
                                    self.contactWebsiteUrl = self.contact.website
                                    if foundContact.instagramAccessToken != "" && foundContact.instagramId != 0 {
                                        self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: foundContact.instagramAccessToken, user_id: foundContact.instagramId))
                                    }
                                    
                                    if self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                                        self.contactRelationship = .unknown
                                    } else {
                                        self.contactRelationship = .contact
                                    }
                                    self.auth.dynamicLinkContactID = 0
                                }
                            } else {
                                Request.users(withIDs: [NSNumber(value: self.auth.dynamicLinkContactID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                    for use in users {
                                        if use.id == self.auth.dynamicLinkContactID {
                                            self.connectyContact = use
                                            self.contactWebsiteUrl = use.website ?? ""
                                            if self.connectyContact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                                                self.contactRelationship = .unknown
                                            } else {
                                                self.contactRelationship = .notContact
                                            }
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                for i in Chat.instance.contactList?.pendingApproval ?? [] {
                                                    if i.userID == self.connectyContact.id {
                                                        self.contactRelationship = .pendingRequest
                                                        break
                                                    }
                                                }

                                                if let profile = self.auth.profile.results.first {
                                                    if profile.contactRequests.contains(where: { $0 == self.contact.id }) {
                                                        self.contactRelationship = .pendingRequestForYou
                                                    }
                                                }
                                            }

                                            changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: Int(self.connectyContact.id), completion: { firebaseContact in
                                                let newContact = ContactStruct()
                                                newContact.id = Int(self.connectyContact.id)
                                                newContact.fullName = self.connectyContact.fullName ?? ""
                                                newContact.phoneNumber = self.connectyContact.phone ?? ""
                                                newContact.lastOnline = self.connectyContact.lastRequestAt ?? Date()
                                                newContact.createdAccount = self.connectyContact.createdAt ?? Date()
                                                newContact.avatar = self.connectyContact.avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact) ?? ""
                                                newContact.bio = firebaseContact.bio
                                                newContact.facebook = firebaseContact.facebook
                                                newContact.twitter = firebaseContact.twitter
                                                newContact.instagramAccessToken = firebaseContact.instagramAccessToken
                                                newContact.instagramId = firebaseContact.instagramId
                                                newContact.isPremium = firebaseContact.isPremium
                                                newContact.emailAddress = self.connectyContact.email ?? "empty email address"
                                                newContact.website = self.connectyContact.website ?? "empty website"
                                                newContact.isInfoPrivate = firebaseContact.isInfoPrivate
                                                newContact.isMessagingPrivate = firebaseContact.isMessagingPrivate

                                                self.contact = newContact
                                                if newContact.instagramAccessToken != "" && newContact.instagramId != 0 {
                                                    self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: newContact.instagramAccessToken, user_id: newContact.instagramId))
                                                }
                                                
                                                print("the contact is now: \(self.contact)")
                                                self.auth.dynamicLinkContactID = 0
                                            })
                                            
                                            break
                                        }
                                    }
                                }) { (error) in
                                    print("error pulling user from connectycube: \(error.localizedDescription)")
                                }
                            }
                        } catch {
                            print("error catching realm error")
                        }
                    }
                }
            }
        }
    }

    func forwardContact() {
        for dialog in self.auth.dialogs.results {
            if dialog.dialogType == "private" {
                for id in dialog.occupentsID {
                    if id != self.auth.profile.results.first?.id {
                        print("the user ID is: \(id)")
                        //replace below with selected contact id:
                        if self.selectedContact.contains(id) {
                            if let selectedDialog = self.auth.dialogs.results.filter("id == %@", dialog.id).first {
                                changeMessageRealmData.shared.sendContactMessage(dialog: selectedDialog, contactID: [self.contact.id], occupentID: [NSNumber(value: id), NSNumber(value: Int(self.auth.profile.results.first?.id ?? 0))])
                                
                                if let index = self.selectedContact.firstIndex(of: id) {
                                    self.selectedContact.remove(at: index)
                                }
                            }
                        }
                    }
                }
            }
        }

        //selectedContact
        if self.selectedContact.count == 0 {
            self.auth.notificationtext = "Forwarded contact"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
        } else {
            // does not have a dialog for the selected user so we create one
            for contact in self.selectedContact {
                let dialog = ChatDialog(dialogID: nil, type: .private)
                dialog.occupantIDs = [NSNumber(value: contact), NSNumber(value: Int(self.auth.profile.results.first?.id ?? 0))]  // an ID of opponent

                Request.createDialog(dialog, successBlock: { (dialog) in
                   let attachment = ChatAttachment()
                   attachment["contactID"] = "\(self.contact.id)"
                   
                   let message = ChatMessage.markable()
                   message.markable = true
                   message.text = "Shared contact"
                   message.attachments = [attachment]
                   
                   dialog.send(message) { (error) in
                       changeMessageRealmData.shared.insertMessage(message, completion: {
                           if error != nil {
                               print("error sending message: \(String(describing: error?.localizedDescription))")
                               changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .error)
                           } else {
                               print("Success sending message to ConnectyCube server!")
                               changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                           }
                       })
                   }
                }) { (error) in
                    print("error making dialog: \(error.localizedDescription)")
                }

                changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                    self.selectedContact.removeAll()
                    self.auth.notificationtext = "Forwarded contact"
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)

                })
            }
        }
    }
    
    func pullNonContact() {
        self.contactRelationship = .notContact
        
        for i in Chat.instance.contactList?.pendingApproval ?? [] {
            if i.userID == self.connectyContact.id {
                self.contactRelationship = .pendingRequest
                break
            }
        }
          
        if let result = self.auth.profile.results.first?.contactRequests.contains(self.contact.id) {
            if result {
                self.contactRelationship = .pendingRequestForYou
            }
        }
        
        changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: self.connectyContact.id != 0 ? Int(self.connectyContact.id) : self.contact.id, completion: { firebaseContact in
            let newContact = ContactStruct()
            newContact.id = self.viewState == .fromGroupDialog ? self.contact.id : Int(self.connectyContact.id)
            newContact.fullName = self.viewState == .fromGroupDialog ? self.contact.fullName : self.connectyContact.fullName ?? ""
            newContact.phoneNumber = self.viewState == .fromGroupDialog ? self.contact.phoneNumber : self.connectyContact.phone ?? ""
            newContact.lastOnline = self.viewState == .fromGroupDialog ? self.contact.lastOnline : self.connectyContact.lastRequestAt ?? Date()
            newContact.createdAccount = self.viewState == .fromGroupDialog ? self.contact.createdAccount : self.connectyContact.createdAt ?? Date()
            newContact.avatar = self.contact.avatar
            newContact.bio = firebaseContact.bio
            newContact.facebook = firebaseContact.facebook
            newContact.twitter = firebaseContact.twitter
            newContact.instagramAccessToken = firebaseContact.instagramAccessToken
            newContact.instagramId = firebaseContact.instagramId
            newContact.isPremium = firebaseContact.isPremium
            newContact.emailAddress = self.connectyContact.email ?? "empty email address"
            newContact.website = self.connectyContact.website ?? "empty website"
            newContact.isInfoPrivate = firebaseContact.isInfoPrivate
            newContact.isMessagingPrivate = firebaseContact.isMessagingPrivate
            
            if newContact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                self.contactRelationship = .unknown
            }
            
            self.contact = newContact
            if newContact.instagramAccessToken != "" && newContact.instagramId != 0 {
                self.viewModel.loadInstagramImages(testUser: InstagramTestUser(access_token: newContact.instagramAccessToken, user_id: newContact.instagramId))
            }
            
            print("done loading contact: \(self.contact.id) name: \(self.contact.fullName) relationship: \(self.contactRelationship) vieState: \(self.viewState)")
        })
    }
}

//MARK: Top Header Contact View
struct topHeaderContactView: View {
    @ObservedObject var viewModel: VisitContactViewModel
    @Binding var contact: ContactStruct
    @Binding var quickSnapViewState: QuickSnapViewingState
    @Binding var isProfileImgOpen: Bool
    @Binding var isProfileBioOpen: Bool
    @Binding var selectedImageUrl: String
    @State private var showMoreAction: Bool = false
    @State private var openActionSheet: Bool = false
    @State private var openNetwork: openProfileSocialLink = .none

    var body: some View {
        VStack {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                if self.contact.quickSnaps.count > 0 {
                    self.quickSnapViewState = .viewing
                } else {
                    self.selectedImageUrl = self.contact.avatar
                    self.isProfileImgOpen.toggle()
                }
            }) {
                ZStack {
                    if self.contact.avatar != "" {
                        WebImage(url: URL(string: self.contact.avatar))
                            .resizable()
                            .placeholder{ Image("empty-profile").resizable().frame(width: 110, height: 110, alignment: .center).scaledToFill() }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.25))
                            .scaledToFill()
                            .frame(width: 110, height: 110, alignment: .center)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
                    } else {
                        Circle()
                            .frame(width: 110, height: 110, alignment: .center)
                            .foregroundColor(Color("bgColor"))
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)

                        Text("".firstLeters(text: contact.fullName))
                            .font(.system(size: 52))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    if self.contact.quickSnaps.count > 0 {
                        Circle()
                            .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .foregroundColor(.clear)
                    }
                    
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 16, height: 16)
                        .foregroundColor(.green)
                        .overlay(Circle().stroke(Color("bgColor"), lineWidth: 3))
                        .opacity(self.contact.isOnline ? 1 : 0)
                        .offset(x: 40, y: 40)
                }
            }.buttonStyle(ClickButtonStyle())
            .offset(y: 50)
            .zIndex(2)
            
            self.viewModel.styleBuilderHeader(content: {
                HStack(alignment: .top) {
                    Spacer()
                    VStack(alignment: .center) {
                        Button(action: {
                            if self.contact.quickSnaps.count != 0 {
                                self.isProfileImgOpen.toggle()
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                        }) {
                            VStack(alignment: .center) {
                                HStack(spacing: 5) {
                                    if self.contact.isPremium == true {
                                        Image(systemName: "checkmark.seal")
                                            .resizable()
                                            .scaledToFit()
                                            .font(Font.title.weight(.semibold))
                                            .frame(width: 22, height: 22, alignment: .center)
                                            .foregroundColor(Color("main_blue"))
                                    }

                                    Text(self.contact.fullName)
                                        .font(.system(size: 26))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }.offset(y: contact.isPremium ? 3 : 0)
                                
                                Text(self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") ? "your profile" : (self.contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago"))
                                    .font(.subheadline)
                                    .fontWeight(.none)
                                    .background(self.contact.isInfoPrivate && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") ? Color.secondary : Color.clear)
                                    .foregroundColor(self.contact.isInfoPrivate ? Color.clear : self.contact.isOnline ? Color.green : Color.secondary)
                                    .multilineTextAlignment(.leading)
                                    .offset(y: contact.isPremium ? -3 : 0)
                            }
                        }.buttonStyle(EmptyButtonStyle())
                        .offset(x: self.contact.isMyContact ? 10 : 0)
                        
                        //MARK: Bio Section
                        if self.contact.bio != "" {
                            VStack(alignment: .trailing) {
                                Text(self.contact.bio)
                                    .font(.subheadline)
                                    .fontWeight(.none)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(self.isProfileBioOpen ? 20 : 4)
                                    .onTapGesture {
                                        if showMoreAction {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            withAnimation(.easeOut(duration: 0.25)) {
                                                self.isProfileBioOpen.toggle()
                                            }
                                        }
                                    }
                                    .readSize(onChange: { size in
                                        self.showMoreAction = size.height > 70
                                    })

                                if self.showMoreAction {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            self.isProfileBioOpen.toggle()
                                        }
                                    }, label: {
                                        Text(self.isProfileBioOpen ? "less..." : "more...")
                                            .font(.subheadline)
                                            .fontWeight(.none)
                                            .foregroundColor(.secondary)
                                    }).buttonStyle(ClickButtonStyle())
                                    .offset(y: 2.5)
                                }
                            }.padding(.top, 2)
                            .padding(.bottom, 10)
                            .offset(x: self.contact.isMyContact ? 10 : 0)
                        }
                        
                        //MARK: Social Buttons
                        if self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") || !self.contact.isInfoPrivate || self.contact.isMyContact {
                            HStack(alignment: .center, spacing: 20) {
                                if self.contact.facebook != "" {
                                    Button(action: {
                                        if !self.contact.isInfoPrivate || self.contact.isMyContact {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            self.openNetwork = .facebook
                                            self.openActionSheet.toggle()
                                        } else {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }) {
                                        Image("facebookIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(6)
                                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4), lineWidth: 1.4).frame(width: 32, height: 32).background(Color.secondary.opacity(0.1)))
                                            .cornerRadius(8)
                                    }.buttonStyle(ClickButtonStyle())
                                }
                                
                                if self.contact.twitter != "" {
                                    Button(action: {
                                        if !self.contact.isInfoPrivate || self.contact.isMyContact {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            self.openNetwork = .twitter
                                            self.openActionSheet.toggle()
                                        } else {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }) {
                                        Image("twitterIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(6)
                                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4), lineWidth: 1.4).frame(width: 32, height: 32).background(Color.secondary.opacity(0.1)))
                                            .cornerRadius(8)
                                    }.buttonStyle(ClickButtonStyle())
                                }
                                
                                if self.contact.instagramAccessToken != "" {
                                    Button(action: {
                                        if !self.contact.isInfoPrivate || self.contact.isMyContact {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            self.openNetwork = .instagram
                                            self.openActionSheet.toggle()
                                        } else {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        }
                                    }) {
                                        Image("instagramIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(6)
                                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.4), lineWidth: 1.4).frame(width: 32, height: 32).background(Color.secondary.opacity(0.1)))
                                            .cornerRadius(8)
                                    }.buttonStyle(ClickButtonStyle())
                                }
                            }
                        }
                    }.padding(.top, 40)
                    .actionSheet(isPresented: self.$openActionSheet) {
                        ActionSheet(title: Text("Open \(self.contact.fullName)'s Profile?"), message: Text("Opening will leave the current application."), buttons: [
                            .default(Text("Open " + "\(self.openNetwork == .facebook ? "Facebook" : self.openNetwork == .instagram ? "Instagram" : self.openNetwork == .twitter ? "Twitter" : "Profile")")) {
                                if self.openNetwork == .facebook {
                                    self.viewModel.openFacebookApp(screenName: self.contact.facebook)
                                } else if self.openNetwork == .twitter {
                                    self.viewModel.openTwitterApp(screenName: self.contact.twitter)
                                } else if self.openNetwork == .instagram {
                                    self.viewModel.openInstagramApp()
                                }
                            },
                            .cancel()
                        ])
                    }

                    if self.contact.isMyContact {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            if self.contact.isFavourite {
                                self.viewModel.updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: false)
                            } else {
                                self.viewModel.updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: true)
                            }
                        }) {
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor( self.contact.isFavourite ? .yellow : .gray)
                                .shadow(color: Color.black.opacity(self.contact.isFavourite ? 0.15 : 0.0), radius: 2, x: 0, y: 2)
                        }.buttonStyle(ClickButtonStyle())
                    } else {
                        Spacer()
                    }
                }.padding(.horizontal)
                .padding(.vertical, 15)
            }).zIndex(1)
        }
    }
}

//MARK: Action Button View
struct actionButtonView: View {
    @ObservedObject var viewModel: VisitContactViewModel
    @Binding var contact: ContactStruct
    @Binding var quickSnapViewState: QuickSnapViewingState
    @Binding var contactRelationship: visitContactRelationship
    @Binding var newMessage: Int
    @Binding var dismissView: Bool
    @State var showRemoveRequest: Bool = false
    
    var body: some View {
        HStack(spacing: self.contactRelationship == .contact ? 54 : 30) {
            Spacer()
            
            if self.contact.isMessagingPrivate == false && self.contactRelationship != .unknown && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.newMessage = self.contact.id
                    self.dismissView.toggle()
                }) {
                    HStack(alignment: .center, spacing: 10) {
                        Image("ChatBubble")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 26)
                        
                        if self.contactRelationship == .contact {
                            Text("Chat")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }.background(RoundedRectangle(cornerRadius: 17, style: .circular).frame(width: self.contactRelationship == .contact ? 145 : 58, height: 58).foregroundColor(Constants.baseBlue).shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 6))
                }.buttonStyle(ClickButtonStyle())
                .padding(.vertical, 6)
            }

            if self.contactRelationship == .contact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.quickSnapViewState = .camera
                }) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 36, height: 24)
                        .background(RoundedRectangle(cornerRadius: 17, style: .circular).frame(width: 58, height: 58).foregroundColor(.purple).shadow(color: Color.purple.opacity(0.45), radius: 10, x: 0, y: 6))
                }.buttonStyle(ClickButtonStyle())
            } else if self.contactRelationship == .notContact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                Button(action: {
                    self.viewModel.addContact(contactRelationship: self.contactRelationship, contactId: self.contact.id, completion: { contactState in
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        self.contactRelationship = contactState
                    })
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 24, alignment: .center)
                            .foregroundColor(.white)
                            .padding(3)
                        
                        Text("Add Contact")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }.padding(.all, 15)
                    .padding(.horizontal, 5)
                    .background(Constants.baseBlue)
                    .cornerRadius(17)
                    .shadow(color: Color.blue.opacity(0.30), radius: 8, x: 0, y: 8)
                }.buttonStyle(ClickButtonStyle())
            } else if self.contactRelationship == .pendingRequest && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.showRemoveRequest.toggle()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "alarm")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 26, alignment: .center)
                            .foregroundColor(.secondary)
                            .padding(3)
                        
                        Text("Pending...")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }.padding(.all, 15)
                    .padding(.horizontal, 5)
                    .background(Color("buttonColor"))
                }.cornerRadius(17)
                .buttonStyle(ClickButtonStyle())
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                .actionSheet(isPresented: self.$showRemoveRequest) {
                    ActionSheet(title: Text("Are you sure you want to un-send your contact request?"), message: nil, buttons: [
                        .destructive(Text("Remove Request"), action: {
                            Chat.instance.removeUser(fromContactList: UInt(self.contact.id)) { (error) in
                                changeContactsRealmData.shared.deleteContact(contactID: self.contact.id, isMyContact: false, completion: { _ in
                                    self.contactRelationship = .notContact
                                })
                            }
                        }),
                        .cancel()
                    ])
                }
            }
            else if self.contactRelationship == .pendingRequestForYou && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                HStack {
                    Button(action: {
                        self.viewModel.acceptContactRequest(contactRelationship: self.contactRelationship, contactId: self.contact.id, completion: { contactState in
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            self.contactRelationship = contactState
                        })
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .font(Font.title.weight(.semibold))
                                .frame(width: 22, height: 20, alignment: .center)
                                .foregroundColor(.white)
                                .padding(3)
                            
                            Text("Accept")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }.padding(.all, 15)
                        .padding(.horizontal, 5)
                        .background(Constants.baseBlue)
                        .cornerRadius(17)
                        .shadow(color: Color.blue.opacity(0.30), radius: 8, x: 0, y: 8)
                    }

                    Button(action: {
                        self.viewModel.trashContactRequest(visitContactRelationship: self.contactRelationship, userId: self.contact.id, completion: { contactStatus in
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            self.contactRelationship = contactStatus
                        })
                    }) {
                        Image(systemName: "trash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24, alignment: .center)
                            .foregroundColor(Color.white)
                            .padding(.all, 15)
                            .background(Color("alertRed"))
                            .cornerRadius(17)
                            .shadow(color: Color("alertRed").opacity(0.30), radius: 8, x: 0, y: 8)
                    }
                }
            }

            Spacer()
        }.padding(.vertical, 12.5)
    }
}
