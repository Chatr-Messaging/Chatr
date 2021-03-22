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
import Firebase
import RealmSwift
import AVKit

struct Resultz: Decodable {
    var encoded: Data
}

struct AttachmentBubble: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = false
    @State var player: AVPlayer = AVPlayer()
    @State var play: Bool = false
    @State var totalDuration: Double = 0
    var namespace: Namespace.ID

    var body: some View {
        ZStack() {
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
                    }.matchedGeometryEffect(id: message.id, in: namespace)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                    .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                    .padding(.bottom, self.hasPrior ? 0 : 4)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                    .matchedGeometryEffect(id: self.message.id.description + "gif", in: namespace)
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
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                    .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .padding(.bottom, self.hasPrior ? 0 : 4)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 3).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                    .matchedGeometryEffect(id: self.message.id.description + "png", in: namespace)
                    .onAppear {
                        print("the found image url: \(self.message.image)")
                    }
            } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {
                ZStack() {
                    if let url = URL(string: self.message.localAttachmentPath) {
                        ChatrVideoPlayer(player1: self.$player, totalDuration: self.$totalDuration, fileId: self.message.image, videoUrl: url)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .background(Color("lightGray"))
                            .clipShape(CustomGIFShape())
                            .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                            .frame(minHeight: 100, maxHeight: CGFloat(Constants.screenHeight * 0.55))
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                            .padding(.bottom, self.hasPrior ? 0 : 4)
                            .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                            .overlay(
                                ZStack {
                                    VideoControlBubble(viewModel: self.viewModel, player: self.$player, play: self.$play, totalDuration: self.$totalDuration, message: self.message, messagePositionRight: messagePosition == .right)

                                    if self.message.messageState == .error {
                                        RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5)
                                            .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                                    }
                                }
                            )
                            .matchedGeometryEffect(id: self.message.id.description + "mov", in: namespace)
                            .onTapGesture {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation {
                                    self.play.toggle()
                                }
                                self.play ? self.playVideo() : self.pause()
                            }
                            .onAppear {
                                print("the message url is: \(url.absoluteString)")
                                //self.player = VideoPlayerWorker().play(with: url, fileId: self.message.image)
                            }
                    } else {
                        Text("URL Invalid")
                            .onAppear() {
                                print("the video url is: \(self.message.image)")
                                updateMessageVideoURL(messageId: self.message.id, fileId: self.message.image)
                            }
                    }
                }
            }
        }
    }
    
    func playVideo() {
        let currentItem = self.player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }

        self.player.play()
    }

    func pause() {
        player.pause()
    }

    func updateMessageVideoURL(messageId: String, fileId: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        let storage = Storage.storage()

        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                if realmContact.localAttachmentPath == "" {
                    let videoReference = storage.reference().child("messageVideo").child(fileId)
                    videoReference.downloadURL { url, error in
                        do {
                            try realm.safeWrite {
                                realmContact.localAttachmentPath = url?.absoluteString ?? ""
                                realm.add(realmContact, update: .all)
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
