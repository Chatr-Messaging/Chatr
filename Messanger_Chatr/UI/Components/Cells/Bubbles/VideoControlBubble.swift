//
//  VideoControlBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/21/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI

struct VideoControlBubble: View {
    @ObservedObject var viewModel: ChatMessageViewModel
    @Binding var player: AVPlayer
    @Binding var play: Bool
    @Binding var totalDuration: Double
    @Binding var videoDownload: CGFloat
    @Binding var isDetailOpen: Bool
    @Binding var detailMessageModel: MessageStruct
    @State var message: MessageStruct
    @State var mute: Bool = true
    @State var progressBar: CGFloat = 1.0
    var messagePositionRight: Bool

    var body: some View {
        ZStack(alignment: .center) {
            VStack(alignment: messagePositionRight ? .trailing : .leading) {
                HStack(alignment: .center) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.mute.toggle()
                        self.player.isMuted = self.mute
                    }, label: {
                        Image(systemName: self.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18, alignment: .center)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(7.5))
                            .overlay(RoundedRectangle(cornerRadius: 7.5).stroke(Color.black.opacity(0.15), lineWidth: 2))
                    }).buttonStyle(ClickButtonStyle())
                    .zIndex(1)

                    Spacer()
                    if self.totalDuration > 25.0 {
                        Text(self.getTotalDurationString())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(7.5))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                            .padding(.trailing, 7.5)
                    } else if self.totalDuration != 0.0 {
                        ZStack {
                            Circle()
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .frame(width: 18, height: 18)
                                .opacity(0.35)

                            Circle()
                                .trim(from: 0.0, to: self.progressBar)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .frame(width: 18, height: 18)
                                .rotationEffect(.init(degrees: 90))
                                .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                .animation(Animation.linear(duration: 0.1))
                        }
                        .padding(7.5)
                        .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(7.5))
                        .overlay(RoundedRectangle(cornerRadius: 7.5).stroke(Color.black.opacity(0.15), lineWidth: 2))
                        .padding(.trailing, 7.5)
                        .onChange(of: self.totalDuration) { newValue in
                            self.progressBar = CGFloat(newValue / (player.currentItem?.duration.seconds ?? 1))
                        }
                    }
                }.padding(.top, 7.5)
                .padding(.horizontal, 7.5)
             
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    self.player.pause()
                    self.play = false
                    self.detailMessageModel = self.message
                    self.viewModel.player = self.player
                    self.viewModel.playVideoo = true
                    withAnimation {
                        self.isDetailOpen.toggle()
                    }
                }, label: {
                    Image(systemName: self.viewModel.isDetailOpen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 17, height: 17, alignment: .center)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(7.5))
                        .overlay(RoundedRectangle(cornerRadius: 7.5).stroke(Color.black.opacity(0.15), lineWidth: 2))
                }).buttonStyle(ClickButtonStyle())
                .transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.spring()), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.1))))
                .padding(.bottom, 7.5)
                .padding(.horizontal, 15)
            }
            
            //Big Play Button
            if !play {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.play.toggle()
                    }
                    self.play ? self.playVideo() : self.pause()
                }) {
                    ZStack {
                        BlurView(style: .systemUltraThinMaterialDark)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                        Image(systemName: self.play ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25, alignment: .center)
                            .offset(x: 2.5)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
                            .padding(.all)
                    }.overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.black.opacity(0.15), lineWidth: 2))
                }.buttonStyle(ClickButtonStyle())
                .padding(.vertical, self.videoDownload != 0 || self.videoDownload != 1.0 ? 20 : 125)
                .opacity(self.videoDownload == 0.0 || self.videoDownload == 1.0 ? 1 : 0)
                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.spring(response: 0.2, dampingFraction: 0.65, blendDuration: 0)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.14))))
                .zIndex(1)
            }
        }
    }
    
    func getTotalDurationString() -> String {
        guard !(self.totalDuration.isNaN || self.totalDuration.isInfinite) else { return "" }

        let m = Int(abs(self.totalDuration) / 60)
        let s = Int(self.totalDuration.truncatingRemainder(dividingBy: 60))

        return String(format: "%d:%02d", arguments: [m, s])
    }
    
    func playVideo() {
        let currentItem = player.currentItem
        if currentItem?.currentTime() == currentItem?.duration {
            currentItem?.seek(to: .zero, completionHandler: nil)
        }

        player.play()
    }

    func pause() {
        player.pause()
    }
}
