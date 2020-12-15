//
//  TextBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct TextBubble: View {
    @EnvironmentObject var auth: AuthModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    var hasPrior: Bool = true
    @State var avatar: String = ""
    @State private var typingOpacity: CGFloat = 1.0
    @State private var URLStrings: [NSURL] = [NSURL]()
    
    var repeatingAnimation: Animation {
        Animation
            .easeInOut(duration: 0.66)
            .repeatForever(autoreverses: true)
    }
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
            //VStack(alignment: self.messagePosition == .right ? .trailing : .leading) {
                // chack if there are 4 or more emoji's in text
                //if self.message.text.containsEmoji && self.message.text.count <= 4 {
//                    HStack() {
//                        //converts string to image and loops through
//                        ForEach(self.message.text.emojiToImage(text: self.message.text), id: \.self) { text in
//                            Image(uiImage: text ?? UIImage())
//                                .resizable()
//                                .frame(width: 55, height: 55, alignment: .center)
//                                .foregroundColor(.clear)
//                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 10)
//                                .padding(.horizontal, 2.5)
//                        }
//                    }
                //} else {
                ZStack {
                    if self.message.messageState != .isTyping || self.message.messageState == .deleted {
                        Text(self.message.messageState == .deleted ? "deleted" : self.message.text)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(self.message.messageState != .deleted ? messagePosition == .right ? .white : .primary : .secondary)
                            .padding(.vertical, 8)
                            .lineLimit(nil)
                    } else if self.message.messageState == .isTyping {
                        HStack(spacing: 6) {
                            ForEach(0..<3) { type in
                                Image("typingDot")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaledToFit()
                                    .frame(width: 10, height: 10, alignment: .center)
                                    .background(Color.secondary)
                                    .clipShape(Circle())
                                    .opacity(Double(self.typingOpacity))
                                    .animation(Animation.easeInOut(duration: 0.66).repeatForever(autoreverses: true).delay(Double(type + 1) * 0.22))
                                    .onAppear() {
                                        withAnimation(self.repeatingAnimation) {
                                            self.typingOpacity = 0.20
                                        }
                                    }
                            }
                        }.padding(.vertical, 12.5)
                    }
                }.padding(.horizontal, 15)
                .transition(AnyTransition.scale)
                .background(self.messagePosition == .right && self.message.messageState != .deleted ? LinearGradient(
                    gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                    startPoint: .top, endPoint: .bottom) : LinearGradient(
                        gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: self.messagePosition == .right && self.message.messageState != .deleted ? Color.blue.opacity(0.25) : Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
                .contextMenu {
                    if self.message.messageState != .isTyping {
                        VStack {
                            if messagePosition == .right {
                                if self.message.messageState != .deleted {
                                    Button(action: {
                                        print("Delete Message")
                                        self.auth.selectedConnectyDialog?.removeMessage(withID: self.message.id) { (error) in
                                            if error != nil {
                                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                            } else {
                                                changeMessageRealmData().updateMessageState(messageID: self.message.id, messageState: .deleted)
                                            }
                                        }
                                    }) { HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                            .foregroundColor(.red) }
                                    }
                                }
                                Button(action: {
                                    print("Edit Message")
                                }) { HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit") }
                                }
                            }
                            Button(action: {
                                print("Share Message")
                            }) { HStack {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("Share") }
                            }
                            Button(action: {
                                print("Copy Message")
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                UIPasteboard.general.setValue(self.message.text,
                                            forPasteboardType: kUTTypePlainText as String)
                            }) { HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Text") }
                            }
                            
                            ForEach(self.URLStrings, id: \.self) { link in
                                Button(action: {
                                    print("Open \(link)")
                                    UIApplication.shared.open(link as URL)
                                }) { HStack {
                                    Image(systemName: "safari")
                                    Text("Open \(link)") }
                                }
                            }
                        }
                    }
                }
                //}
            HStack {
                if messagePosition == .right { Spacer() }
                
                Text(self.subText.messageStatusText(message: self.message, positionRight: messagePosition == .right))
                    .foregroundColor(self.message.messageState == .error ? .red : .gray)
                    .font(.caption)
                    .lineLimit(1)
                    .offset(y: 15)
                    .padding(.horizontal)
                    .multilineTextAlignment(messagePosition == .right ? .trailing : .leading)
                    .opacity(self.hasPrior && self.message.messageState != .error ? 0 : 1)
                
                if messagePosition == .left { Spacer() }
            }
            
            WebImage(url: URL(string: self.avatar))
                .resizable()
                .placeholder{ Image(systemName: "person.fill") }
                .indicator(.activity)
                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: self.hasPrior ? 1 : Constants.smallAvitarSize, height: self.hasPrior ? 1 : Constants.smallAvitarSize, alignment: .bottom)
                .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2), y: (Constants.smallAvitarSize / 2) + 5)
                .opacity(self.hasPrior ? 0 : 1)
        }.onAppear() {
            self.fetchURLText(text: self.message.text)
            if self.message.senderID == UserDefaults.standard.integer(forKey: "currentUserID") {
                self.avatar = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.avatar ?? ""
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                        self.avatar = foundContact.avatar
                    } else {
                        Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            if let firstUser = users.first {
                                self.avatar = PersistenceManager().getCubeProfileImage(usersID: firstUser) ?? ""
                            }
                        })
                    }
                } catch {
                    
                }
            }
        }
    }
    
    func fetchURLText(text: String) {
        self.URLStrings.removeAll()
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        let matches = detector!.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
        
        for match in matches {
            print(match.url!)
            self.URLStrings.append(match.url! as NSURL)
        }
    }
}
