//
//  AttachmentBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/21/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct AttachmentBubble: View {
    @EnvironmentObject var auth: AuthModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    var hasPrior: Bool = false
    @State var avatar: String = "https://is5-ssl.mzstatic.com/image/thumb/Purple123/v4/09/d2/6b/09d26bc2-4a87-d8a0-032f-a537aec233a7/source/60x60bb.jpg"
    
    var body: some View {
        ZStack(alignment: self.messagePosition == .right ? .bottomTrailing : .bottomLeading) {
            if self.message.imageType == "image/gif" && self.message.messageState != .deleted {
                AnimatedImage(url: URL(string: self.message.image))
                    .resizable()
                    .placeholder {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading GIF...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .clipShape(CustomGIFShape())
                    //.frame(minHeight: 100, maxHeight: CGFloat(self.message.imgHeight))
                    //.frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * 0.7))
                    .frame(idealWidth: CGFloat(Constants.screenWidth * 0.60), idealHeight: CGFloat(Constants.screenWidth * 0.6))
                    .frame(minWidth: 100)
                    .padding(.leading, self.messagePosition == .right ? 35 : 0)
                    .padding(.trailing, self.messagePosition == .right ? 0 : 35)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .contextMenu {
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
                                print("Save GIF")
                            }) { HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Text") }
                            }
    //                            Button(action: {
    //                                print("Like Message")
    //                            }) { HStack {
    //                                Image(systemName: "heart")
    //                                Text("Like") }
    //                            }
                        }
                    }
            } else if self.message.imageType == "image/png" && self.message.messageState != .deleted {
                WebImage(url: URL(string: self.message.image))
                    .resizable()
                    .placeholder {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .aspectRatio(contentMode: .fit)
                    .scaledToFit()
                    .frame(idealWidth: CGFloat(Constants.screenWidth * 0.60), idealHeight: CGFloat(Constants.screenWidth * 0.6))
                    .frame(minWidth: 100)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .contextMenu {
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
                                print("Forward Message")
                            }) { HStack {
                                Image(systemName: "arrowshape.turn.up.left")
                                Text("Forward Image") }
                            }
                        }
                    }
            } else if self.message.messageState == .deleted {
                ZStack {
                    Text("deleted")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(self.message.messageState != .deleted ? messagePosition == .right ? .white : .primary : .secondary)
                        .padding(.vertical, 8)
                        .lineLimit(nil)
                }.padding(.horizontal, 15)
                .background(self.messagePosition == .right && self.message.messageState != .deleted ? LinearGradient(
                    gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                    startPoint: .top, endPoint: .bottom) : LinearGradient(
                        gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: self.messagePosition == .right && self.message.messageState != .deleted ? Color.blue.opacity(0.2) : Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                
            }
            
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
                .transition(.fade(duration: 0.05))
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: self.hasPrior ? 0 : Constants.smallAvitarSize, height: self.hasPrior ? 0 : Constants.smallAvitarSize, alignment: .bottom)
                .shadow(color: Color("buttonShadow"), radius: 5, x: 0, y: 0)
                .offset(x: messagePosition == .right ? (Constants.smallAvitarSize / 2) : -(Constants.smallAvitarSize / 2), y: (Constants.smallAvitarSize / 2) + 5)
                .opacity(self.hasPrior ? 0 : 1)
        }.onAppear() {
            print("the image type is: \(self.message.imageType)")
            if self.message.senderID == UserDefaults.standard.integer(forKey: "currentUserID") {
                //get profile image
                self.avatar = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.avatar ?? ""
            } else {
                let config = Realm.Configuration(schemaVersion: 1)
                do {
                    let realm = try Realm(configuration: config)
                    if let foundContact = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.message.senderID) {
                        self.avatar = foundContact.avatar
                    } else {
                        Request.users(withIDs: [NSNumber(value: self.message.senderID)], paginator: Paginator.limit(1, skip: 0), successBlock: { (paginator, users) in
                            self.avatar = PersistenceManager().getCubeProfileImage(usersID: users.first!) ?? ""
                        })
                    }
                } catch {
                    
                }
            }
        }
    }
}
