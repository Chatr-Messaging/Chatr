//
//  AudioDetailView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/15/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVFoundation
import SwiftUI
import Cache
import ConnectyCube

struct AudioDetailView: View {
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    var namespace: Namespace.ID
    @State var isPlayingAudio: Bool = false
    @State var durationString: String = "0:00"
    @State var audioProgress: CGFloat = 0
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 50), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        VStack(alignment: .center) {
            HStack(alignment: .center, spacing: 5) {
                Text(self.durationString)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 36)
                    .padding(.horizontal, 5)
                    .onReceive(self.timer) { time in
                        guard self.viewModel.audio.playingBubbleId == self.message.id.description else {
                            print("not the correct cell to play from: \(self.message.id.description)")
                            self.isPlayingAudio = false
                            self.timer.upstream.connect().cancel()

                            return
                        }

                        print("the time is: \(time) for: \(self.message.id.description)")
                        self.durationString = self.viewModel.audio.getTotalPlaybackDurationString()
                        self.audioProgress = CGFloat(self.viewModel.audio.audioPlayer.currentTime / self.viewModel.audio.audioPlayer.duration) * CGFloat(Constants.screenWidth * 0.6)
                    }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .frame(width: Constants.screenWidth * 0.6, height: 5)
                        .foregroundColor(Color("progressSlider").opacity(0.85))
                    
                    RoundedRectangle(cornerRadius: 2.5)
                        .frame(width: self.audioProgress, height: 5)
                        .foregroundColor(.blue)
                }
            }
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                if self.isPlayingAudio {
                    self.viewModel.audio.stopAudioRecording()
                    self.timer.upstream.connect().cancel()
                    self.isPlayingAudio = false
                    print("stop playing")
                 } else {
                     self.timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
                     self.loadAudio(fileId: self.message.image)
                     print("stop??? lolll playing")
                 }
            }) {
                HStack(alignment: .center, spacing: 15) {
                    if self.isPlayingAudio {
                        AudioIndicatorView(isBlue: true, isPlaying: self.$isPlayingAudio)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28, alignment: .center)
                            .font(Font.title.weight(.regular))
                            .foregroundColor(.blue)
                    }

                    Text(self.isPlayingAudio ? "Pause Audio" : "Play Audio")
                        .foregroundColor(.blue)
                        .font(.body)
                        .fontWeight(.bold)
                }.frame(width: (Constants.screenWidth * 0.6) + 50, height: 58, alignment: .center)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(15)
            }.buttonStyle(ClickMiniButtonStyle())
            .padding(.top, 10)
        }.matchedGeometryEffect(id: self.message.id.description + "audio", in: namespace)
        .onAppear(perform: {
            guard self.viewModel.audio.playingBubbleId == self.message.id.description else { return }

            self.durationString = self.viewModel.audio.getTotalPlaybackDurationString()
            self.audioProgress = CGFloat(self.viewModel.audio.audioPlayer.currentTime / self.viewModel.audio.audioPlayer.duration) * CGFloat(Constants.screenWidth * 0.4)
        })
    }
    
    func loadAudio(fileId: String) {
        DispatchQueue.main.async {
            guard self.viewModel.audio.playingBubbleId != self.message.id.description else {
                self.viewModel.audio.audioPlayer.play()
                self.isPlayingAudio = true

                return
            }

            self.viewModel.audio.playingBubbleId = self.message.id.description

            do {
                print("the audio cashed id is: \(fileId)")
                let result = try storage?.entry(forKey: fileId)
                if let objectData = result?.object {
                    self.viewModel.audio.audioPlayer = try AVAudioPlayer(data: objectData)
                    print("got it and now going to play it222")
                    self.viewModel.audio.audioPlayer.play()
                    self.isPlayingAudio = true
                    print("successfully added cached audio data \(String(describing: result?.object))")
                } else {
                    print("error setting audio")
                }
            } catch {
                print("could not find cached audio... downloading now..")
                Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
                    print("the progress of the audio download is: \(progress)")
                }, successBlock: { data in
                    self.storage?.async.setObject(data, forKey: fileId, completion: { _ in })
                    
                    do {
                        self.viewModel.audio.audioPlayer = try AVAudioPlayer(data: data)
                        self.isPlayingAudio = true
                        self.viewModel.audio.audioPlayer.play()
                    } catch {
                        print("failed to set new audio")
                    }
                }, errorBlock: { error in
                    print("the error audiooo is: \(String(describing: error.localizedDescription))")
                })
            }
        }
    }
}

