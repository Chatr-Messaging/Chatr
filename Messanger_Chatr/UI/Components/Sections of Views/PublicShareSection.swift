//
//  PublicShareSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 6/18/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube

struct PublicShareSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dismissView: Bool
    @Binding var newDialogID: String
    @Binding var notiType: String
    @Binding var notiText: String
    @Binding var showAlert: Bool
    @State var dialogModel: DialogStruct
    @State var showForwardChannel: Bool = false
    @State var selectedContact: [Int] = []

    var body: some View {
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

        styleBuilder(content: {
            //QR Code button
            NavigationLink(destination: ShareProfileView(dimissView: self.$dismissView,
                                                         contactID: 0,
                                                         dialogID: self.dialogModel.id,
                                                         contactFullName: self.dialogModel.fullName,
                                                         contactAvatar: self.dialogModel.avatar,
                                                         isPublicDialog: true,
                                                         totalMembers: self.dialogModel.publicMemberCount)
                            .environmentObject(self.auth)) {
                VStack(alignment: .trailing, spacing: 0) {
                    HStack {
                        Image(systemName: "qrcode")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color.primary)
                            .frame(width: 20, height: 20, alignment: .center)
                            .padding(.trailing, 5)
                        
                        Text("Share Chat")
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
            
            Button(action: {
                self.showForwardChannel.toggle()
            }) {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.primary)
                        .frame(width: 20, height: 20, alignment: .center)
                        .padding(.trailing, 5)
                    
                    Text("Forward Chat")
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
        .sheet(isPresented: self.$showForwardChannel, onDismiss: {
            guard !self.selectedContact.isEmpty else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                self.forwardContact()
            }
        }) {
            NewConversationView(usedAsNew: false, forwardContact: true, selectedContact: self.$selectedContact, newDialogID: self.$newDialogID)
                .environmentObject(self.auth)
        }
    }
    
    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center, spacing: 0) {
            content()
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .padding(.bottom, 5)
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
                                changeMessageRealmData.shared.sendPublicChannel(dialog: selectedDialog, contactID: [self.dialogModel.id], occupentID: [NSNumber(value: id), NSNumber(value: Int(self.auth.profile.results.first?.id ?? 0))])
                                
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.notiType = "success"
            self.notiText = "Successfully forwarded chat"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.showAlert = true
            }
        } else {
            // does not have a dialog for the selected user so we create one
            for contact in self.selectedContact {
                let dialog = ChatDialog(dialogID: nil, type: .private)
                dialog.occupantIDs = [NSNumber(value: contact), NSNumber(value: Int(self.auth.profile.results.first?.id ?? 0))]  // an ID of opponent

                Request.createDialog(dialog, successBlock: { (dialog) in
                   let attachment = ChatAttachment()
                   attachment["channelID"] = "\(self.dialogModel.id)"
                   
                   let message = ChatMessage.markable()
                   message.markable = true
                    message.text = "Shared channel \(self.dialogModel.fullName)"
                   message.attachments = [attachment]
                   
                   dialog.send(message) { (error) in
                       changeMessageRealmData.shared.insertMessage(message, completion: {
                           if error != nil {
                               print("error sending message: \(String(describing: error?.localizedDescription))")
                               changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .error)
                           } else {
                               print("Success sending message to ConnectyCube server!")
                           }
                       })
                   }
                }) { (error) in
                    print("error making dialog: \(error.localizedDescription)")
                }

                changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                    self.selectedContact.removeAll()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.notiType = "success"
                    self.notiText = "Successfully forwarded \(self.dialogModel.fullName)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self.showAlert = true
                    }
                })
            }
        }
    }
}
