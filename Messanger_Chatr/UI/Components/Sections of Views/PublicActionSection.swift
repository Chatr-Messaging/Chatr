//
//  PublicActionSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/18/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import Firebase
import FirebaseDynamicLinks
import MobileCoreServices

struct PublicActionSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dialogRelationship: visitDialogRelationship
    @Binding var dialogModel: DialogStruct
    @Binding var currentUserIsPowerful: Bool
    @Binding var dismissView: Bool
    @Binding var notiType: String
    @Binding var notiText: String
    @Binding var showAlert: Bool
    @Binding var notificationsOn: Bool
    @Binding var dialogModelAdmins: [Int]
    @Binding var openNewDialogID: Int

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Button(action: {
                if self.dialogRelationship != .subscribed {
                    Request.subscribeToPublicDialog(withID: self.dialogModel.id, successBlock: { dialogz in
                        changeDialogRealmData.shared.toggleFirebaseMemberCount(dialogId: dialogz.id ?? "", isJoining: true, totalCount: Int(dialogz.occupantsCount), onSuccess: { _ in
                            changeDialogRealmData.shared.insertDialogs([dialogz], completion: {
                                changeDialogRealmData.shared.updateDialogDelete(isDelete: false, dialogID: self.dialogModel.id)
                                changeDialogRealmData.shared.addPublicMemberCountRealmDialog(count: Int(dialogz.occupantsCount), dialogId: self.dialogModel.id)
                                UserDefaults.standard.set(self.dialogModel.id, forKey: "visitingDialogId")
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                self.dismissView.toggle()
                            })
                        }, onError: { err in
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            self.dialogRelationship = .error
                            self.notiType = "error"
                            self.notiText = "Error fetching \(dialogModel.fullName)'s info: \(err ?? "no error")"
                            self.showAlert.toggle()
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.dialogRelationship = .error
                        self.notiType = "error"
                        self.notiText = "Error fetching \(dialogModel.fullName)'s info: \(error.localizedDescription)"
                        self.showAlert.toggle()
                    }
                } else if self.dialogRelationship == .subscribed {
                    UserDefaults.standard.set(self.dialogModel.id, forKey: "openingDialogId")
                    self.dismissView.toggle()
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }
            }) {
                HStack {
                    Image("ChatBubble")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 26)

                    if self.dialogRelationship == .subscribed {
                        Text("Chat")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }.padding(.horizontal, 7.5)
                .padding(.all, self.dialogRelationship != .notSubscribed ? 15 : 0)
                .padding(.horizontal, self.dialogRelationship != .notSubscribed ? 5 : 0)
                .background(RoundedRectangle(cornerRadius: 17, style: .circular).frame(minWidth: 54).frame(height: 54).foregroundColor(Constants.baseBlue).shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 6))
            }.buttonStyle(ClickButtonStyle())

            if self.dialogRelationship == .notSubscribed || self.dialogRelationship == .error {
                Button(action: {
                    Request.subscribeToPublicDialog(withID: self.dialogModel.id, successBlock: { dialogz in
                        changeDialogRealmData.shared.toggleFirebaseMemberCount(dialogId: dialogz.id ?? "", isJoining: true, totalCount: Int(dialogz.occupantsCount), onSuccess: { _ in
                            changeDialogRealmData.shared.insertDialogs([dialogz], completion: {
                                changeDialogRealmData.shared.updateDialogDelete(isDelete: false, dialogID: dialogz.id ?? "")
                                changeDialogRealmData.shared.addPublicMemberCountRealmDialog(count: Int(dialogz.occupantsCount), dialogId: dialogz.id ?? "")
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                withAnimation {
                                    self.dialogRelationship = .subscribed
                                    self.dialogModelAdmins.append(UserDefaults.standard.integer(forKey: "currentUserID"))
                                }
                                self.auth.sendPushNoti(userIDs: [NSNumber(value: self.dialogModel.owner)], title: "New Member joined \(dialogz.name ?? "no name")", message: "\(self.auth.profile.results.first?.fullName ?? "No Name") joined your channel \(self.dialogModel.fullName)")
                                self.notiType = "success"
                                self.notiText = "Successfully joined \(dialogModel.fullName)"
                                self.showAlert.toggle()
                            })
                        }, onError: { err in
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            self.dialogRelationship = .error
                            self.notiType = "error"
                            self.notiText = "Error joining \(dialogModel.fullName): \(err ?? "no error")"
                            self.showAlert.toggle()
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.dialogRelationship = .error
                        self.notiType = "error"
                        self.notiText = "Error joining \(dialogModel.fullName): \(error.localizedDescription)"
                        self.showAlert.toggle()
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 24, alignment: .center)
                            .foregroundColor(.white)
                            .padding(2.5)
                        
                        Text("Join Channel")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }.padding(.all, 15)
                    .padding(.horizontal, 5)
                    .background(self.dialogRelationship == .error ? Color("alertRed") : Constants.baseBlue)
                    .cornerRadius(17)
                    .shadow(color: Color.blue.opacity(0.30), radius: 8, x: 0, y: 8)
                }.buttonStyle(ClickButtonStyle())
            }
            
            Menu {
                if self.dialogModel.owner != UserDefaults.standard.integer(forKey: "currentUserID") && self.dialogRelationship == .subscribed {
                    Button(action: {
                        self.toggleNotifications()
                    }) {
                        Label("Turn Notifications \(self.notificationsOn ? "Off" : "On")", systemImage: self.notificationsOn ? "bell.slash" : "bell")
                    }
                }
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    copyChannelURL()
                }) {
                    Label("Copy Channel URL", systemImage: "doc.on.doc")
                }
                
                if self.dialogModel.owner != UserDefaults.standard.integer(forKey: "currentUserID") {
                    Button(action: {
                        self.reportPublicDialog()
                    }) {
                        Label("Report Channel", systemImage: "exclamationmark.octagon")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.primary)
                    .frame(width: 38, height: 26)
                    .background(RoundedRectangle(cornerRadius: 17, style: .circular).frame(width: 54, height: 54).foregroundColor(Color("buttonColor")).shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6))
            }.buttonStyle(ClickButtonStyle())
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }.padding(.bottom)
    }
    
    
    func reportPublicDialog() {
        changeDialogRealmData.shared.reportFirebasePublicDialog(dialogId: self.dialogModel.id, onSuccess: { _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.auth.sendPushNoti(userIDs: [NSNumber(value: self.dialogModel.owner)], title: "\(self.dialogModel.fullName) Reported", message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") reported your channel \(self.dialogModel.fullName)")
            self.notiType = "report"
            self.notiText = "Successfully reported \(self.dialogModel.fullName)"
            self.showAlert.toggle()
        }, onError: { err in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.notiType = "error"
            self.notiText = "Error reporting channel: \(String(describing: err))"
            self.showAlert.toggle()
        })
    }
    
    func toggleNotifications() {
        self.notificationsOn.toggle()
        Request.updateNotificationsSettings(forDialogID: self.dialogModel.id, enable: self.notificationsOn, successBlock: { result in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.notificationsOn = result
            self.notiType = !result ? "notiOn" : "notiOff"
            self.notiText = "Successfully turned notifications \(!result ? "on" : "off")"
            self.showAlert.toggle()
        }, errorBlock: { error in
            self.notificationsOn.toggle()
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.notiType = "error"
            let errMsg = error.localizedDescription == "Request failed: forbidden (403)" ? "Not enough permission to update notification settings" : "Error updating notification settings: \(error.localizedDescription)"
            self.notiText = errMsg
            self.showAlert.toggle()
        })
    }
    
    func copyChannelURL() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.chatr-messaging.com"
        components.path = "/publicDialog"
        
        let recipeIDQueryItem = URLQueryItem(name: "publicDialogID", value: self.dialogModel.id)
        components.queryItems = [recipeIDQueryItem]
                
        guard let shareLink = DynamicLinkComponents.init(link: (components.url ?? URL(string: ""))!, domainURIPrefix: "https://chatrmessaging.page.link") else {
            return
        }
        if let myBundleId = Bundle.main.bundleIdentifier {
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        //shareLink.iOSParameters?.appStoreID = ""
        shareLink.socialMetaTagParameters?.title = "\(self.dialogModel.fullName)'s Channel"
        shareLink.socialMetaTagParameters?.descriptionText = "\(self.dialogModel.bio)"
        shareLink.socialMetaTagParameters?.imageURL = URL(string: self.dialogModel.avatar)
        
        //let longurl = shareLink.url
        //print("the long dynamic link is: \(String(describing: longurl?.absoluteString))")
        
        shareLink.shorten(completion: { (url, _, _) in
//            if error != nil {
//                print("oh no we have an error: \(String(describing: error?.localizedDescription))")
//            }
//            if let warnings = warnings {
//                for warning in warnings {
//                    print("FDL warning: \(warning)")
//                }
//            }
            guard let url = url else { return }
            //print("I have a short URL to share: \(url.absoluteString)")
            
            UIPasteboard.general.setValue(url.absoluteString, forPasteboardType: kUTTypePlainText as String)
            self.notiType = "success"
            self.notiText = "Copied channel URL"
            self.showAlert.toggle()
        })
    }
}
