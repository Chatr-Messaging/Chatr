//
//  SelectableAddressBookContact.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/20/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MessageUI
import ConnectyCube

struct SelectableAddressBookContact: View {
    @State var addressBook: AddressBookStruct
    private let messageComposeDelegate = MessageComposerDelegate()
    @State var presentingModal = false
    
    var body: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .center) {
                Circle()
                    .frame(width: 35, height: 35, alignment: .center)
                    .foregroundColor(Color("bgColor"))
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                
                Text("".firstLeters(text: self.addressBook.name))
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading) {
                Text(addressBook.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.primary)
                
                Text(addressBook.phone.format(phoneNumber: self.addressBook.phone))
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                //self.presentMessageCompose(recipient: self.addressBook.phone)
                self.presentingModal.toggle()
            }) {
                Text("Invite")
                    .font(.body)
                    .foregroundColor(.blue)
            }.sheet(isPresented: $presentingModal) {
                if MFMessageComposeViewController.canSendText() {
                    iMessageCompose(msgDelegate: self.messageComposeDelegate, recipientNumber: self.addressBook.phone)
                }
            }
        }
    }
}

extension SelectableAddressBookContact {
    private class MessageComposerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }
}

struct iMessageCompose: UIViewControllerRepresentable {
    var msgDelegate: MFMessageComposeViewControllerDelegate
    var recipientNumber: String = ""
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self.msgDelegate
        composeVC.body = "Let's chat on Chatr! It's a simple, fun, & secure messaging app we can use to message eachother for FREE! Download at: " + Constants.appStoreLink
        composeVC.recipients = [self.recipientNumber]
        
        return composeVC
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) { }
}
