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
import WKView

struct VisitContactView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    var fromDialogCell: Bool = false
    @Binding var newMessage: Int
    @Binding var dismissView: Bool
    @State var viewState: visitUserState = .unknown
    @State var contactRelationship: visitContactRelationship = .unknown
    @State var contact: ContactStruct = ContactStruct()
    @State var connectyContact: User = User()
    @State var isProfileImgOpen: Bool = false
    @State var isProfileBioOpen: Bool = false
    @State var isUrlOpen: Bool = false
    @State private var showingMoreSheet = false
    @State var profileViewSize = CGSize.zero
    @State var quickSnapViewState: QuickSnapViewingState = .closed

    @State var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false

    var body: some View {
        ZStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    //MARK: Top Profile
                    VStack {
                        VStack {
                            HStack(alignment: .top) {
                                HStack(alignment: self.contact.bio == "" ? .center : .top) {
                                    Button(action: {
                                        print("profile image")
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if self.contact.quickSnaps.count > 0 {
                                            print("quickSnaps avalible")
                                            self.quickSnapViewState = .viewing
                                        } else {
                                            self.isProfileImgOpen.toggle()
                                        }
                                    }) {
                                        ZStack {
                                            WebImage(url: URL(string: contact.avatar))
                                                .resizable()
                                                .placeholder{ Image(systemName: "person.fill") }
                                                .indicator(.activity)
                                                .transition(.fade(duration: 0.25))
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .frame(width: 80, height: 80, alignment: .center)
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)
                                            
                                            if self.contact.quickSnaps.count > 0 {
                                                Circle()
                                                    .stroke(Constants.quickSnapGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                                    .frame(width: 88, height: 88)
                                                    .foregroundColor(.clear)
                                            }
                                            
                                            RoundedRectangle(cornerRadius: 5)
                                                .frame(width: 12, height: 12)
                                                .foregroundColor(.green)
                                                .opacity(contact.isOnline ? 1 : 0)
                                                .offset(x: 28, y: 28)
                                        }
                                    }.buttonStyle(ClickButtonStyle())
                                    .offset(x: -5, y: -5)

                                    VStack(alignment: .leading) {
                                        Button(action: {
                                            if self.contact.quickSnaps.count != 0 {
                                                self.isProfileImgOpen.toggle()
                                            }
                                        }) {
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 5) {
                                                    if self.contact.isPremium == true {
                                                        Image(systemName: "checkmark.seal")
                                                            .resizable()
                                                            .scaledToFit()
                                                            .font(Font.title.weight(.semibold))
                                                            .frame(width: 22, height: 22, alignment: .center)
                                                            .foregroundColor(Color("main_blue"))
                                                    }
                                                    
                                                    Text(contact.fullName)
                                                        .font(.system(size: 22))
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(2)
                                                        .multilineTextAlignment(.leading)
                                                }.offset(y: contact.isPremium ? 3 : 0)
                                                
                                                Text(contact.isOnline ? "online now" : "last online \(contact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                                    .font(.subheadline)
                                                    .fontWeight(.none)
                                                    .background(self.contact.isInfoPrivate ? Color.secondary : Color.clear)
                                                    .foregroundColor(self.contact.isInfoPrivate ? Color.clear : Color.secondary)
                                                    .multilineTextAlignment(.leading)
                                                    .offset(y: contact.isPremium ? -3 : 0)
                                            }
                                        }.buttonStyle(EmptyButtonStyle())
                                        
                                        //MARK: Bio Section
                                        if self.contact.bio != "" {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(self.contact.bio)
                                                        .font(.subheadline)
                                                        .fontWeight(.none)
                                                        .multilineTextAlignment(.leading)
                                                        .lineLimit(self.isProfileBioOpen ? 20 : 5)
                                                    
                                                    if self.contact.bio.count > 220 {
                                                        Button(action: {
                                                            print("more...")
                                                            self.isProfileBioOpen.toggle()
                                                        }, label: {
                                                            Text(self.isProfileBioOpen ? "less..." : "more...")
                                                                .font(.subheadline)
                                                                .fontWeight(.none)
                                                                .foregroundColor(.secondary)
                                                        }).buttonStyle(ClickButtonStyle())
                                                        .offset(y: -2)
                                                    }
                                                }
                                                
                                                Spacer()
                                            }.padding(.vertical, 3)
                                        }
                                    }
                                    Spacer()
                                }
                                if self.contact.isMyContact {
                                    Button(action: {
                                        print("Favourite tap")
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        if self.contact.isFavourite {
                                            changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: false)
                                        } else {
                                            changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: true)
                                        }
                                    }) {
                                        Image(systemName: "star.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .foregroundColor( self.contact.isFavourite ? .yellow : .secondary)
                                            .shadow(color: Color.black.opacity(self.contact.isFavourite ? 0.15 : 0.0), radius: 2, x: 0, y: 2)
                                    }.buttonStyle(ClickButtonStyle())
                                }
                            }
                            
                            //MARK: Action Buttons
                            HStack(spacing: self.contactRelationship == .contact ? 40 : 20) {
                                Spacer()
                                
                                if self.contact.isMessagingPrivate == false && self.contactRelationship != .unknown && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    Button(action: {
                                        print("chat... \(self.contact.id)")
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.newMessage = self.contact.id
                                        self.dismissView.toggle()
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(width: 46, height: 46, alignment: .center)
                                                .foregroundColor(.clear)
                                                .background(Constants.purpleGradient)
                                                .cornerRadius(10)
                                                .shadow(color: Color(.sRGB, red: 44 / 255, green: 0 / 255, blue: 255 / 255, opacity: 0.35), radius: 8, x: 0, y: 5)
                                            
                                            Image("ChatBubble")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 34, height: 23, alignment: .center)
                                                .foregroundColor(.primary)
                                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                                .padding(3)
                                        }
                                    }.buttonStyle(ClickButtonStyle())
                                }

                                if self.contactRelationship == .contact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.quickSnapViewState = .camera
                                        print("camera...")
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(width: 45, height: 45, alignment: .center)
                                                .foregroundColor(.clear)
                                                .background(Constants.quickSnapGradient)
                                                .cornerRadius(10)
                                                .shadow(color: Color(.sRGB, red: 255 / 255, green: 34 / 255, blue: 169 / 255, opacity: 0.35), radius: 8, x: 0, y: 5)

                                            Image(systemName: "camera.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 26, height: 23, alignment: .center)
                                                .foregroundColor(.white)
                                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                                .padding(3)
                                        }
                                    }.buttonStyle(ClickButtonStyle())
                                } else if self.contactRelationship == .notContact && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        Chat.instance.addUser(toContactListRequest: UInt(self.contact.id)) { (error) in
                                            if error != nil {
                                                print("error adding user: \(String(describing: error?.localizedDescription))")
                                            } else {
                                                self.contactRelationship = .pendingRequest
                                                print("add contact button")
                                                
                                                let event = Event()
                                                event.notificationType = .push
                                                event.usersIDs = [NSNumber(value: self.contact.id)]
                                                event.type = .oneShot

                                                var pushParameters = [String : String]()
                                                pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") sent you a contact request."
                                                pushParameters["ios_sound"] = "app_sound.wav"


                                                if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                                                            options: .prettyPrinted) {
                                                  let jsonString = String(bytes: jsonData,
                                                                          encoding: String.Encoding.utf8)

                                                  event.message = jsonString

                                                  Request.createEvent(event, successBlock: {(events) in
                                                    print("sent push notification to user \(self.contact.id)")
                                                  }, errorBlock: {(error) in
                                                    print("error in sending push noti: \(error.localizedDescription)")
                                                  })
                                                }
                                                
                                            }
                                        }
                                    }) {
                                        HStack(alignment: .center) {
                                            Image(systemName: "person.crop.circle.badge.plus")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 24, alignment: .center)
                                                .foregroundColor(.blue)
                                                .padding(3)
                                            
                                            Text("Add Contact")
                                                .font(.none)
                                                .fontWeight(.medium)
                                                .foregroundColor(.blue)
                                        }.padding(.all, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.blue, lineWidth: 1)
                                        )
                                    }.buttonStyle(ClickButtonStyle())
                                } else if self.contactRelationship == .pendingRequest && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    HStack(alignment: .center) {
                                        Image(systemName: "alarm")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 24, alignment: .center)
                                            .foregroundColor(.secondary)
                                            .padding(3)
                                        
                                        Text("Pending...")
                                            .font(.none)
                                            .fontWeight(.regular)
                                            .foregroundColor(.secondary)
                                    }.padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary, lineWidth: 1)
                                    )
                                } else if self.contactRelationship == .pendingRequestForYou && self.contact.id != UserDefaults.standard.integer(forKey: "currentUserID") {
                                    HStack {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            Chat.instance.rejectAddContactRequest(UInt(self.contact.id)) { (error) in
                                                if error != nil {
                                                    print("error rejecting contact: \(String(describing: error?.localizedDescription))")
                                                } else {
                                                    print("rejected contact")
                                                    self.contactRelationship = .unknown
                                                    self.auth.profile.removeContactRequest(userID: UInt(self.contact.id))

                                                }
                                            }
                                        }) {
                                            Image(systemName: "person.crop.circle.badge.xmark")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 28, height: 24, alignment: .center)
                                                .foregroundColor(Color("alertRed"))
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, 9)
                                                .background(Color("alertRed").opacity(0.1))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(Color("alertRed"), lineWidth: 1)
                                                )
                                        }

                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            Chat.instance.confirmAddContactRequest(UInt(self.contact.id)) { (error) in
                                                print("accepted new contact:")
                                                self.contactRelationship = .contact
                                                self.auth.profile.removeContactRequest(userID: UInt(self.contact.id))
                                                
                                                let event = Event()
                                                event.notificationType = .push
                                                event.usersIDs = [NSNumber(value: self.contact.id)]
                                                event.type = .oneShot

                                                var pushParameters = [String : String]()
                                                pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") accepted your contact request."
                                                pushParameters["ios_sound"] = "app_sound.wav"


                                                if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                                                            options: .prettyPrinted) {
                                                  let jsonString = String(bytes: jsonData,
                                                                          encoding: String.Encoding.utf8)

                                                  event.message = jsonString

                                                  Request.createEvent(event, successBlock: {(events) in
                                                    print("sent push notification to user")
                                                  }, errorBlock: {(error) in
                                                    print("error in sending push noti: \(error.localizedDescription)")
                                                  })
                                                }
                                            }
                                        }) {
                                            HStack(alignment: .center) {
                                                Image(systemName: "person.crop.circle.badge.checkmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 28, height: 24, alignment: .center)
                                                    .foregroundColor(.blue)
                                                    .padding(3)
                                                
                                                Text("Accept")
                                                    .font(.none)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.blue)
                                            }.padding(.all, 8)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.blue, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                        }.padding(.horizontal)
                        .padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 5)
                    .padding(.horizontal)
                    .padding(.vertical)
                    .padding(.top, 50)
                    
                   
                    
                    //MARK: Phone Number Section
                    HStack {
                        Text("INFO:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center) {
                        VStack(spacing: 0) {
                            VStack(alignment: .trailing, spacing: 0) {
                                HStack {
                                    Image(systemName: "phone")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.primary)
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text(contact.phoneNumber.format(phoneNumber: String(contact.phoneNumber.dropFirst())))
                                        .font(.none)
                                        .fontWeight(.none)
                                        .background(self.contact.isInfoPrivate ? Color.secondary : Color.clear)
                                        .foregroundColor(self.contact.isInfoPrivate ? .clear : .primary)
                                        
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
                                        WebView(url: self.contact.website,
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
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    //MARK: Action Section
                    HStack {
                        Text("ACTIONS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center) {
                        VStack(spacing: 0) {
                            //QR Code button
                            NavigationLink(destination:
                                            ShareProfileView(dimissView: self.$dismissView,
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
                            
                            //MARK: Fav Btn Section
                            if self.contact.isMyContact {
                                Button(action: {
                                    //add to fav button
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if self.contact.isFavourite {
                                        changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: false)
                                    } else {
                                        changeContactsRealmData().updateContactFavouriteStatus(userID: UInt(self.contact.id), favourite: true)
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
                            }
                            
                            Button(action: {
                                print("Forward Contact")
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
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    //MARK: Social Section
                    if self.contact.facebook != "" || self.contact.twitter != "" {
                        HStack {
                            Text("SOCIAL:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .offset(y: 2)
                            Spacer()
                        }
                        
                        VStack(alignment: .center) {
                            VStack {
                                HStack(alignment: .center, spacing: 40) {
                                    Spacer()
                                    
                                    if self.contact.facebook != "" {
                                        Button(action: {
                                            print("faceboook tap")
                                            
                                            let screenName =  self.contact.facebook
                                            let appURL = URL(string: "fb://profile/\(screenName)")!
                                            let application = UIApplication.shared

                                            if application.canOpenURL(appURL) {
                                                application.open(appURL)
                                            } else {
                                                // if Instagram app is not installed, open URL inside Safari
                                                let webURL = URL(string: "https://facebook.com/\(screenName)")!
                                                application.open(webURL)
                                            }
                                        }, label: {
                                            Image("facebookIcon")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.primary)
                                                .frame(width: 11, height: 24, alignment: .center)
                                                .padding(.trailing, 5)
                                        })
                                    }
                                    
                                    if self.contact.twitter != "" {
                                        Button(action: {
                                            print("twitter tap")
                                            let screenName =  self.contact.twitter
                                            let appURL = NSURL(string: "twitter://user?screen_name=\(screenName)")!
                                            let webURL = NSURL(string: "https://twitter.com/\(screenName)")!
                                            let application = UIApplication.shared

                                            if application.canOpenURL(appURL as URL) {
                                                 application.open(appURL as URL)
                                            } else {
                                                 application.open(webURL as URL)
                                            }
                                        }, label: {
                                            Image("twitterIcon")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.primary)
                                                .frame(width: 23, height: 20, alignment: .center)
                                                .padding(.trailing, 5)
                                        })
                                    }
                                    Spacer()
                                }.padding(.horizontal)
                            }.padding(.vertical, 12.5)
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    
                    //MARK: More Section
                    HStack {
                        Text("MORE:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center) {
                        VStack {
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
                                    
                                    Text("More...")
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
                            .frame(minWidth: 100, maxWidth: .infinity)
                            .actionSheet(isPresented: $showingMoreSheet) {
                                ActionSheet(title: Text("More..."), message: nil, buttons: [.default(Text(self.contactRelationship == .contact ? "Remove from Contacts" : self.contactRelationship == .pendingRequest ? "Pending..." : self.contactRelationship == .pendingRequestForYou ? "waiting for you..." : "Add Contact"), action: {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                if self.contactRelationship == .contact {
                                                    Chat.instance.removeUser(fromContactList: UInt(self.contact.id)) { (error) in
                                                        changeContactsRealmData().deleteContact(contactID: self.contact.id, isMyContact: false, completion: { _ in
                                                            //changeContactsRealmData().updateContacts(contactList: (Chat.instance.contactList?.contacts)!, completion: { _ in })
                                                            self.contactRelationship = .notContact
                                                        })
                                                    }
                                                } else if self.contactRelationship == .notContact {
                                                    Chat.instance.addUser(toContactListRequest: UInt(self.contact.id)) { (error) in
                                                        if error != nil {
                                                            print("error adding user: \(String(describing: error?.localizedDescription))")
                                                        } else {
                                                            self.contactRelationship = .pendingRequest
                                                            print("add contact button")
                                                            
                                                            let event = Event()
                                                            event.notificationType = .push
                                                            event.usersIDs = [NSNumber(value: self.contact.id)]
                                                            event.type = .oneShot

                                                            var pushParameters = [String : String]()
                                                            pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") sent you a contact request."
                                                            pushParameters["ios_sound"] = "app_sound.wav"


                                                            if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters,
                                                                                                        options: .prettyPrinted) {
                                                              let jsonString = String(bytes: jsonData,
                                                                                      encoding: String.Encoding.utf8)

                                                              event.message = jsonString

                                                              Request.createEvent(event, successBlock: {(events) in
                                                                print("sent push notification to user \(self.contact.id)")
                                                              }, errorBlock: {(error) in
                                                                print("error in sending push noti: \(error.localizedDescription)")
                                                              })
                                                            }
                                                            
                                                        }
                                                    }
                                                }
                                            }),
                                .destructive(Text("Block & Report \(self.contact.fullName.components(separatedBy: " ").first ?? " ")"), action: {
                                    let privateChatPrivacyItem = PrivacyItem.init(privacyType: .userID, userID: UInt(self.contact.id), allow: false)
                                    privateChatPrivacyItem.mutualBlock = true
                                    let groupChatPrivacyItem = PrivacyItem.init(privacyType: .groupUserID, userID: UInt(self.contact.id), allow: false)
                                    let privacyList = PrivacyList.init(name: "PrivacyList", items: [privateChatPrivacyItem, groupChatPrivacyItem])
                                    changeContactsRealmData().deleteContact(contactID: self.contact.id, isMyContact: false, completion: { _ in })
                                    Chat.instance.setPrivacyList(privacyList)
                                    self.contactRelationship = .unknown
                                }), .cancel(Text("Done"))])
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 60)
                    
                    Spacer()
                    
                    //MARK: Footer Section
                    FooterInformation(middleText: "joined \(self.contact.createdAccount.getFullElapsedInterval())")
                        .padding(.bottom, 30)

                }.navigationBarItems(leading:
                    Button(action: {
                        print("Done btn tap")
                        withAnimation {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text(self.fromDialogCell ? "Done" : "")
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }.disabled(self.fromDialogCell ? false : true)
                )
            }.background(Color("bgColor"))
            .navigationBarHidden(self.quickSnapViewState == .camera || self.quickSnapViewState == .takenPic)

            //MARK: Other Views
            //See profile image
            ZStack {
                BlurView(style: .systemUltraThinMaterial)
                    .opacity(self.isProfileImgOpen || self.quickSnapViewState == .camera || self.quickSnapViewState == .takenPic ? Double(150 - abs(self.profileViewSize.height)) / 150 : 0)
                    .animation(.linear(duration: 0.15))
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                        .padding(.horizontal, 20)
                        .opacity(self.isProfileImgOpen ? Double(150 - self.profileViewSize.height) / 150 : 0)
                        .offset(y: self.profileViewSize.height / 3)
                        .offset(y: -50)
                    }
                                        
                    WebImage(url: URL(string: contact.avatar))
                        .resizable()
                        .placeholder{ Image(systemName: "person.fill") }
                        .indicator(.activity)
                        .aspectRatio(contentMode: .fill)
                        .transition(.fade(duration: 0.25))
                        .frame(width: Constants.screenWidth - 40, height: Constants.screenWidth - 40, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: self.isProfileImgOpen ? abs(self.profileViewSize.height) + 25 : 100))
                        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 15)
                        .opacity(self.isProfileImgOpen ? 1 : 0)
                        .offset(x: self.profileViewSize.width, y: self.profileViewSize.height)
                        .offset(y: -50)
                        .scaleEffect(self.isProfileImgOpen ? 1 - abs(self.profileViewSize.height) / 500 : 0, anchor: .topLeading)
                        .animation(.spring(response: 0.30, dampingFraction: 0.7, blendDuration: 0))
                        .gesture(DragGesture(minimumDistance: self.isProfileImgOpen ? 0 : Constants.screenHeight).onChanged { value in
                            guard value.translation.height < 175 else { return }
                            guard value.translation.height > -175 else { return }
                            print("height: \(value.translation.height)")
                            if self.isProfileImgOpen {
                                self.profileViewSize = value.translation
                            }
                        }.onEnded { value in
                            if self.profileViewSize.height > 100 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.isProfileImgOpen = false
                            } else if self.profileViewSize.height < -100 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.isProfileImgOpen = false
                            }

                        }.sequenced(before: TapGesture().onEnded({
                            if self.profileViewSize.height == 0 {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                self.isProfileImgOpen = false
                            } else {
                                self.profileViewSize = .zero
                            }
                        })))
                }
            }
            
            //MARK: Quick Snap View
            QuickSnapStartView(viewState: self.$quickSnapViewState, selectedQuickSnapContact: self.$contact)
                .environmentObject(self.auth)
                .disabled(self.quickSnapViewState != .closed ? false : true)
        }.onAppear() {
            if self.viewState == .fromSearch {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.connectyContact.id != 0 ? Int(self.connectyContact.id) : self.contact.id) {
                        if foundContact.isMyContact {
                            self.contact = foundContact
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
                            
                            for request in ChatrApp.dialogs.contactRequestIDs {
                                if request == self.connectyContact.id {
                                    self.contactRelationship = .pendingRequestForYou
                                    break
                                }
                            }
                            //self.pullNonContact()
                        }
                    } else {
                        //not in realm and not a contact - check if pending
                        self.pullNonContact()
                    }
                } catch {
                    
                }
            } else if self.viewState == .fromContacts {
                self.contactRelationship = .contact
                changeContactsRealmData().observeFirebaseContact(contactID: self.contact.id)
                
            } else if self.viewState == .fromRequests {
                print("shuld have everything already...")
            } else if self.viewState == .fromDynamicLink {
                print("from Dynamic link: \(self.auth.dynamicLinkContactID)")
                if self.auth.dynamicLinkContactID != 0 {
                    print("ayy dynamic profile")
                    
                    let config = Realm.Configuration(schemaVersion: 1)
                    do {
                        let realm = try Realm(configuration: config)
                        if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.auth.dynamicLinkContactID) {
                            if foundContact.isMyContact {
                                self.contact = foundContact
                                
                                if self.contact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                                    self.contactRelationship = .unknown
                                } else {
                                    self.contactRelationship = .contact
                                }
                                print("the found contactt id is: \(self.contact.id)")
                                self.auth.dynamicLinkContactID = 0
                            }
                        } else {
                            Request.users(withIDs: [NSNumber(value: self.auth.dynamicLinkContactID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                                for use in users {
                                    if use.id == self.auth.dynamicLinkContactID {
                                        self.connectyContact = use
                                        print("the pullled connecty id is: \(self.connectyContact)")
                                        
                                        if self.connectyContact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                                            self.contactRelationship = .unknown
                                        } else {
                                            self.contactRelationship = .notContact
                                        }
                                        
                                        for i in Chat.instance.contactList?.pendingApproval ?? [] {
                                            if i.userID == self.connectyContact.id {
                                                self.contactRelationship = .pendingRequest
                                                break
                                            }
                                        }
                                        
                                        for request in ChatrApp.dialogs.contactRequestIDs {
                                            if request == self.connectyContact.id {
                                                self.contactRelationship = .pendingRequestForYou
                                                break
                                            }
                                        }
                                        
                                        changeContactsRealmData().observeFirebaseContactReturn(contactID: Int(self.connectyContact.id), completion: { firebaseContact in
                                            let newContact = ContactStruct()
                                            newContact.id = Int(self.connectyContact.id)
                                            newContact.fullName = self.connectyContact.fullName ?? ""
                                            newContact.phoneNumber = self.connectyContact.phone ?? ""
                                            newContact.lastOnline = self.connectyContact.lastRequestAt ?? Date()
                                            newContact.createdAccount = self.connectyContact.createdAt ?? Date()
                                            newContact.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact) ?? ""
                                            newContact.bio = firebaseContact.bio
                                            newContact.facebook = firebaseContact.facebook
                                            newContact.twitter = firebaseContact.twitter
                                            newContact.isPremium = firebaseContact.isPremium
                                            newContact.emailAddress = self.connectyContact.email ?? "empty email address"
                                            newContact.website = self.connectyContact.website ?? "empty website"
                                            newContact.isInfoPrivate = firebaseContact.isInfoPrivate
                                            newContact.isMessagingPrivate = firebaseContact.isMessagingPrivate

                                            self.contact = newContact
                                            
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
    
    func pullNonContact() {
        print("not in realm visit")
        self.contactRelationship = .notContact
        
        for i in Chat.instance.contactList?.pendingApproval ?? [] {
            if i.userID == self.connectyContact.id {
                self.contactRelationship = .pendingRequest
                break
            }
        }
        
        for request in ChatrApp.dialogs.contactRequestIDs {
            if request == self.connectyContact.id {
                self.contactRelationship = .pendingRequestForYou
                break
            }
        }
        
        changeContactsRealmData().observeFirebaseContactReturn(contactID: self.connectyContact.id != 0 ? Int(self.connectyContact.id) : self.contact.id, completion: { firebaseContact in
            let newContact = ContactStruct()
            newContact.id = Int(self.connectyContact.id)
            newContact.fullName = self.connectyContact.fullName ?? ""
            newContact.phoneNumber = self.connectyContact.phone ?? ""
            newContact.lastOnline = self.connectyContact.lastRequestAt ?? Date()
            newContact.createdAccount = self.connectyContact.createdAt ?? Date()
            newContact.avatar = PersistenceManager.shared.getCubeProfileImage(usersID: self.connectyContact) ?? ""
            newContact.bio = firebaseContact.bio
            newContact.facebook = firebaseContact.facebook
            newContact.twitter = firebaseContact.twitter
            newContact.isPremium = firebaseContact.isPremium
            newContact.emailAddress = self.connectyContact.email ?? "empty email address"
            newContact.website = self.connectyContact.website ?? "empty website"
            newContact.isInfoPrivate = firebaseContact.isInfoPrivate
            newContact.isMessagingPrivate = firebaseContact.isMessagingPrivate
            
            if newContact.id == UserDefaults.standard.integer(forKey: "currentUserID") {
                self.contactRelationship = .unknown
            }
            
            self.contact = newContact
            
            print("done loading contact: \(self.contact.id) name: \(self.contact.fullName) relationship: \(self.contactRelationship) vieState: \(self.viewState)")
        })
    }
}
