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
    @State var message: MessageStruct
    @State var mute: Bool = true
    @State var progressBar: CGFloat = 200
    var messagePositionRight: Bool

    var body: some View {
        ZStack(alignment: .center) {
            VStack(alignment: messagePositionRight ? .trailing : .leading) {
                if play || self.player.currentTime().seconds > 0.1 {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.mute.toggle()
                        self.player.isMuted = self.mute
                    }, label: {
                        Image(systemName: self.mute ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .foregroundColor(.white)
                            .padding(.vertical)
                            .padding(.horizontal, 20)
                    }).zIndex(1)
                }
             
                Spacer()
                if play || self.player.currentTime().seconds > 0.1 {
                    HStack(spacing: 10) {
                        Text(self.getTotalDurationString())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                        
                        //Progress Bar
                        ZStack() {
                            Capsule()
                                .foregroundColor(.white)
                                .opacity(0.25)

                            Capsule()
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
                                .padding(.trailing, self.progressBar)
                                //.trim(from: 0, to: self.totalDuration / (player.currentItem?.duration.seconds ?? 1))
                                .frame(height: 4)
                        }.frame(height: 4)
                        .onChange(of: self.totalDuration) { newValue in
                            let progressWidth = Double(165)
                            self.progressBar = CGFloat((newValue / (player.currentItem?.duration.seconds ?? 1)) * progressWidth)
                            //print("the width is: \(geo.size.width) && \(self.progressBar)")
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            self.player.pause()
                            self.viewModel.message = self.message
                            self.viewModel.player = self.player
                            self.viewModel.totalDuration = self.totalDuration
                            withAnimation {
                                self.viewModel.isDetailOpen.toggle()
                            }
                        }, label: {
                            Image(systemName: self.viewModel.isDetailOpen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor(.white)
                                .padding(.vertical)
                        })
                    }
                    .padding(.horizontal)
                    .transition(.asymmetric(insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.spring()), removal: AnyTransition.move(edge: .bottom).combined(with: .opacity).animation(.easeOut(duration: 0.1))))
                }
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
                        BlurView(style: .systemUltraThinMaterial)
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
                    }
                }.padding(.vertical, 100)
                .transition(.asymmetric(insertion: AnyTransition.scale.animation(.spring(response: 0.2, dampingFraction: 0.65, blendDuration: 0)), removal: AnyTransition.scale.animation(.easeOut(duration: 0.14))))
                .zIndex(1)
            }
        }
    }
    
    func getTotalDurationString() -> String {
        let m = Int(abs(totalDuration) / 60)
        let s = Int(totalDuration.truncatingRemainder(dividingBy: 60))
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
