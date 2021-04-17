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
import Cache

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
    @State var videoSize: CGSize = CGSize.zero
    var namespace: Namespace.ID
    let storageFirebase = Storage.storage()

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()

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
                    .animation(.default)
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
                    }.aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                    .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .padding(.bottom, self.hasPrior ? 0 : 4)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 3).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                    .matchedGeometryEffect(id: self.message.id.description + "png", in: namespace)
                    .animation(.default)
                    .onAppear {
                        print("the found image url: \(self.message.image)")
                    }
            } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {
                ZStack() {
                    if let url = URL(string: self.message.localAttachmentPath) {
                        //ChatrVideoPlayer(player1: self.$player, totalDuration: self.$totalDuration, fileId: self.message.image, videoUrl: url)
                        PlayerView(player: self.$player, totalDuration: self.$totalDuration)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                            .background(Color("bgColor"))
                            .clipShape(CustomGIFShape())
                            
                            //.frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                            //.frame(minHeight: 100, maxHeight: CGFloat(Constants.screenHeight * 0.45))
                            .frame(width: self.videoSize.width <= 0 ? Constants.screenWidth * 0.65 : self.videoSize.width, height: self.videoSize.height <= 0 ? Constants.screenHeight * 0.5 : self.videoSize.height)
                            //.frame(width: self.videoSize.width, height: self.videoSize.height)
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                            .padding(.bottom, self.hasPrior ? 0 : 4)
                            .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                            .matchedGeometryEffect(id: self.message.id.description + "mov", in: namespace)
//                            .onPreferenceChange(SizePreferenceKey.self) { preferences in
//                                self.videoSize = CGSize(width: Int(preferences.width), height: Int(preferences.height))
//                            }
                            .overlay(
                                ZStack {
                                    VideoControlBubble(viewModel: self.viewModel, player: self.$player, play: self.$play, totalDuration: self.$totalDuration, message: self.message, messagePositionRight: messagePosition == .right)

                                    if self.message.messageState == .error {
                                        RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5)
                                            .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                                    }
                                }
                            )
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
                                self.loadVideo(url: url, fileId: self.message.image, completion: {
                                    self.player.isMuted = true

                                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
                                        self.player.seek(to: CMTime.zero)
                                        self.player.play()
                                    }

                                    self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: nil) { time in
                                        guard let item = self.player.currentItem else { return }

                                        self.totalDuration = item.duration.seconds - item.currentTime().seconds
                                    }

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        if let videoAssetTrack = self.player.currentItem?.asset.tracks(withMediaType: AVMediaType.video).first {
                                            let naturalSize = videoAssetTrack.naturalSize.applying(videoAssetTrack.preferredTransform)
                                            let videoRatio = naturalSize.height / naturalSize.width
                                            let width = naturalSize.width > UIScreen.main.bounds.width * 0.65 ? UIScreen.main.bounds.width * 0.65 : naturalSize.width
                                            let heightRatio = naturalSize.height / videoRatio
                                            let height = heightRatio > UIScreen.main.bounds.height * 0.5 ? UIScreen.main.bounds.height * 0.5 : heightRatio
                                            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))
                                            print("the video size: \(rect.size) && \(naturalSize.height) && \(videoRatio)")
                                            self.videoSize = rect.size
                                        }
                                    }
                                })
                            }
                    } else {
                        Text("loading video...")
                            .onAppear() {
                                updateMessageVideoURL(messageId: self.message.id, fileId: self.message.image)
                            }
                    }
                }
            } else if self.message.imageType == "audio/m4a" && self.message.messageState != .deleted {
                //AudioBubble(viewModel: self.viewModel, messageRight: self.messagePosition == .right, audioKey: self.message.image)
                Text("my audio message")
            }
        }
    }
    
    func loadVideo(url: URL, fileId: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            do {
                let result = try storage?.entry(forKey: url.absoluteString)
                // The video is cached.
                let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mp4", fileExtension: "mp4")
                self.player = AVPlayer(playerItem: playerItem)

                completion()
            } catch {
                let videoReference = storageFirebase.reference().child("messageVideo").child(self.message.image)
                videoReference.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if error == nil {
                        guard let videoData = data else { return }

                        let playerItem = CachingPlayerItem(data: videoData, mimeType: "video/mp4", fileExtension: "mp4")
                        self.player = AVPlayer(playerItem: playerItem)

                        self.storage?.async.setObject(videoData, forKey: url.absoluteString, completion: { _ in })

                        completion()
                    } else {
                        print("the error is: \(String(describing: error?.localizedDescription))")
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
