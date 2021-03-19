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
    @State var isPlaying: Bool = false
    @State var videoSize: CGSize = CGSize.zero
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
                    .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeOut(duration: 0.35)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.25))))
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
                    }.transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
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
                ZStack(alignment: .bottomLeading) {
                    FullScreenVideoUI(player1: self.$player, size: $videoSize,fileId: self.message.image)
                        .transition(.asymmetric(insertion: AnyTransition.scale.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                        .aspectRatio(contentMode: .fill)
                        .background(Color("lightGray"))
                        .clipShape(CustomGIFShape())
                        .frame(width: videoSize.width, height: videoSize.height)
                        //.frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * (self.message.messageState == .error ? 0.55 : 0.65)), alignment: self.messagePosition == .right ? .trailing : .leading)
                        .frame(maxHeight: CGFloat(Constants.screenHeight * 0.65))
                        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 14)
                        .padding(.bottom, self.hasPrior ? 0 : 4)
                        .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.5) : Color.clear, lineWidth: 5).offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0))
                        .matchedGeometryEffect(id: self.message.id.description + "mov", in: namespace)
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.isPlaying.toggle()
                            self.isPlaying ? self.play() : self.pause()
                        }
                        .onAppear {
                            guard let url = URL(string: self.message.image) else { return }
                            self.player = AVPlayer(playerItem: AVPlayerItem(url: url))
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
