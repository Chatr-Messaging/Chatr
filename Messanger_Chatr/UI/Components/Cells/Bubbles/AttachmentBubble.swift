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
import Uploadcare

struct Resultz: Decodable {
    var encoded: Data
}

struct AttachmentBubble: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel: ChatMessageViewModel
    @Binding var isDetailOpen: Bool
    @Binding var detailMessageModel: MessageStruct
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    var hasPrior: Bool = false
    @Binding var player: AVPlayer
    @State var play: Bool = false
    @State var videoMute: Bool = true
    @Binding var totalDuration: Double
    @Binding var playingVideoId: String
    @State var videoSize: CGSize = CGSize.zero
    @State var videoDownloadProgress: CGFloat = 0.0
    var namespace: Namespace.ID
    let storageFirebase = Storage.storage()

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 50), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        ZStack() {
            if self.message.imageType == "image/gif", self.message.messageState != .deleted {
                AnimatedImage(url: URL(string: self.message.image))
                    .resizable()
                    .frame(width: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75)), height: CGFloat((Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75)) / (self.message.mediaRatio != 0.0 ? self.message.mediaRatio : 1.0)))
                    .scaledToFit()
                    .clipShape(CustomGIFShape())
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    //.padding(.bottom, self.hasPrior ? 0 : 4)
                    //.offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                    .background(
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading GIF...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.bottom, self.hasPrior ? 0 : 4)
                    .matchedGeometryEffect(id: self.message.id.description + "gif", in: namespace)
                    .resignKeyboardOnDragGesture()
            } else if self.message.imageType == "image/png", self.message.messageState != .deleted {
                WebImage(url: URL(string: self.message.image))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(width: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75)), alignment: self.messagePosition == .right ? .trailing : .leading)
                    .frame(idealHeight: CGFloat(self.message.mediaRatio * (Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75))))
                    .frame(maxHeight: Constants.screenHeight * 0.75)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .padding(.bottom, self.hasPrior ? 0 : 4)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 3).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                    .background(
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .matchedGeometryEffect(id: self.message.id.description + "png", in: namespace)
            } else if self.message.imageType == "video/mov", self.message.messageState != .deleted {
                ZStack(alignment: .center) {
                    //VideoPlayer(player: self.player)
                    PlayerView(player: self.$player, totalDuration: self.$totalDuration)
                        .edgesIgnoringSafeArea(.all)
                        //.transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .background(
                            WebImage(url: URL(string: Constants.uploadcareBaseUrl + self.message.placeholderVideoImg + Constants.uploadcareStandardTransform))
                                .resizable()
                                .placeholder {
                                    VStack {
                                        Image(systemName: "video.fill")
                                            .padding(.bottom, 5)
                                        Text("loading...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }.padding(.vertical, 100)
                                }.aspectRatio(contentMode: .fit)
                                .clipShape(CustomGIFShape())
                                .frame(width: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75)), alignment: self.messagePosition == .right ? .trailing : .leading)
                                .frame(height: CGFloat(self.message.mediaRatio * (Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75))))
                        )
                        .clipShape(CustomGIFShape())
                        .frame(width: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75)), alignment: self.messagePosition == .right ? .trailing : .leading)
                        .frame(height: CGFloat(self.message.mediaRatio * (Constants.screenWidth * (self.message.messageState == .error ? 0.65 : 0.75))))
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                        .padding(.bottom, self.hasPrior ? 0 : 4)
                        .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                        .matchedGeometryEffect(id: self.message.id.description + "mov", in: namespace)
                        .overlay(
                            ZStack {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                        .frame(width: 26, height: 26)
                                        .opacity(0.35)

                                    Circle()
                                        .trim(from: 1.0 - self.videoDownloadProgress, to: 1.0)
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                        .frame(width: 26, height: 26)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                                        .rotationEffect(.init(degrees: -90))
                                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                        .animation(Animation.linear(duration: 0.1))
                                }
                                .padding(8)
                                .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(7.5))
                                .opacity(self.videoDownloadProgress == 0.0 || self.videoDownloadProgress == 1.0 ? 0 : 1)
                                .padding(30)

                            VideoControlBubble(viewModel: self.viewModel, player: self.$player, play: self.$play, totalDuration: self.$totalDuration, videoDownload: self.$videoDownloadProgress, isDetailOpen: self.$isDetailOpen, detailMessageModel: self.$detailMessageModel, mute: self.$videoMute, playingVideoId: self.$playingVideoId, message: self.message, messagePositionRight: messagePosition == .right)

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
                            DispatchQueue.main.async {
                                self.loadVideo(fileId: self.message.image, completion: {
                                    self.player.isMuted = true
                                    self.play = false

                                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player.currentItem, queue: .main) { _ in
                                        self.player.seek(to: CMTime.zero)
                                        self.player.play()
                                    }

                                    self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: nil) { time in
                                        guard let item = self.player.currentItem else { return }

                                        self.totalDuration = item.duration.seconds - item.currentTime().seconds
                                    }

                                    //DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
    //                                    if let videoAssetTrack = self.player.currentItem?.asset.tracks(withMediaType: AVMediaType.video).first {
    //                                        let naturalSize = videoAssetTrack.naturalSize.applying(videoAssetTrack.preferredTransform)
    //                                        let width = abs(naturalSize.width) > UIScreen.main.bounds.width * 0.75 ? UIScreen.main.bounds.width * 0.75 : abs(naturalSize.width)
    //                                        let heightRatio = abs(naturalSize.height) * (abs(naturalSize.height) / width)
    //                                        let height = width * (abs(naturalSize.height) / abs(naturalSize.width))
    //                                        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))
    //
    //                                        self.videoSize = rect.size
    //                                    }
                                    //}
                                })
                            }
                        }
                        .onDisappear {
                            self.play = false
                            self.pause()
                        }
                }
            } else if self.message.imageType == "audio/m4a", self.message.messageState != .deleted {
                AudioBubble(viewModel: self.viewModel, message: self.message, namespace: self.namespace, messageRight: self.messagePosition == .right)
                    .resignKeyboardOnDragGesture()
            }
        }
    }
    
    func loadVideo(fileId: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            do {
                print("loading video id: \(fileId)")
                let result = try storage?.entry(forKey: Constants.uploadcareBaseVideoUrl + fileId)
                let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mov", fileExtension: "mov")

                self.player = AVPlayer(playerItem: playerItem)

                completion()
            } catch {
                print("failed so im about to download the file: \(fileId)")

                Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
                    print("the progress of the download is: \(progress)")
                    self.videoDownloadProgress = CGFloat(progress)
                }, successBlock: { data in
                    let playerItem = CachingPlayerItem(data: data as Data, mimeType: "video/mov", fileExtension: "mov")
                    self.player = AVPlayer(playerItem: playerItem)

                    self.storage?.async.setObject(data, forKey: Constants.uploadcareBaseVideoUrl + fileId, completion: { test in
                        print("the testtt data is: \(test)")
                    })
                    
                    completion()
                }, errorBlock: { error in
                    print("the error videoo is: \(String(describing: error.localizedDescription))")
                    completion()
                })
            }
        }
    }
    
    func playVideo() {
        let currentItem = self.player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }
        
        if self.videoMute, !self.viewModel.preferenceVideoMute {
            self.videoMute = false
            self.player.isMuted = false
        } else if self.viewModel.preferenceVideoMute {
            self.videoMute = true
            self.player.isMuted = true
        }

        self.playingVideoId = message.id.description
        self.player.play()
    }

    func pause() {
        self.player.pause()
        self.play = false
    }
}
