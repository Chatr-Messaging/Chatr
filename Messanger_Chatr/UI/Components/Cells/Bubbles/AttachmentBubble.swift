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
import AVKit

struct AttachmentBubble: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    @State var avatar: String = ""
    @State var localVideoURL: URL?
    var hasPrior: Bool = false
    @State var player: AVPlayer = AVPlayer()
    @State var isPlaying: Bool = false

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
                    }
                    .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeOut(duration: 0.35)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.25))))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * 0.65))
                    .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
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
                    }.transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.8 : 0.85)))
                    .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 3).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
            } else if self.message.imageType == "video/mov" && self.message.messageState != .deleted {
                ZStack(alignment: .bottomLeading) {
                    //PlayerContainerView(player: self.$player, gravity: .resize)
                    VideoPlayer(player: self.player)
                        .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .aspectRatio(contentMode: .fit)
                        .clipShape(CustomGIFShape())
                        .frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * 0.75))
                        .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                        .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.isPlaying.toggle()
                            self.isPlaying ? self.play() : self.pause()
                        }
                        .onAppear {
                            CacheManager.shared.getFileWith(stringUrl: self.message.image) { result in
                              switch result {
                              case .success(let url):
                                let fileURL = Blob.privateUrl(forFileUID: self.message.image)
                                print("the found: \(String(describing: fileURL)) saved \(self.message.image) url is: \(url.description)")

                                self.localVideoURL = url
                                self.player = AVPlayer(playerItem: AVPlayerItem(url: url))

    //                            Request.backgroundDownloadFile(withUID: self.message.image, progressBlock: { (progress) in
    //                                print("the download progress is: \(progress)")
    //                            }, successBlock: { (blob) in
    //                                //let ig = blob
    //
    //                            }, errorBlock: { error in
    //                                print("error somehow downloading...\(error.localizedDescription)")
    //                            })

                                  break
                              case .failure(let error):
                                  print(error, "failure in the Cache of video")
                                  break
                              }
                            }
                        }
                    
                    HStack {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.isPlaying.toggle()
                            self.isPlaying ? self.play() : self.pause()
                        }, label: {
                            Image(systemName: self.isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.all)
                        })

//                        Text("\(self.player.currentItem?.asset.duration.stringFromTimeInterval())")
//                            .font(.caption)
//                            .fontWeight(.medium)
//                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    func play() {
        let currentItem = self.player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }
        
        self.player.play()
    }
    
    func pause() {
        player.pause()
    }

    func formatVideoDuration(second: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad

        return formatter.string(from: second) ?? "0:00"
    }
}
