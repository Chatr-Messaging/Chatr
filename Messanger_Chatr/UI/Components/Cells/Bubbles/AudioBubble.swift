//
//  AudioBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/30/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVFoundation
import SwiftUI
import RealmSwift
import Cache

struct AudioBubble: View {
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var messageRight: Bool = false
    @State var audioKey: String = ""
    @State var audioProgress: CGFloat = 0
    @State var isPlayingAudio: Bool = false
    @State var durationString: String = "0:00"
    @State var timer: Timer
    @State var time = 0

    var audioPlayer: AVAudioPlayer = AVAudioPlayer()

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        HStack(spacing: 5) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                 if self.isPlayingAudio {
                    //self.stopAudioRecording()
                    print("stop playing")
                 } else {
                    //self.playAudioRecording()
                    print("stop playing")
                 }
            }) {
                Image(systemName: self.isPlayingAudio ? "pause.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .center)
                    .font(Font.title.weight(.regular))
                    .foregroundColor(.blue)
                    .padding(.leading, 15)
            }
            
            Text(self.durationString)
                .foregroundColor(.secondary)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 40)
//                .onReceive(self.timer) { time in
//                    self.viewModel.getTotalPlaybackDurationString()
//                    self.audioProgress = CGFloat(self.viewModel.audioPlayer.currentTime / self.viewModel.audioPlayer.duration) * CGFloat(Constants.screenWidth * 0.25)
//                }

                //Progress Bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .foregroundColor(.primary)
                        .opacity(0.25)

                    Capsule()
                        .foregroundColor(.primary)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .frame(width: self.audioProgress)
                }.frame(width: Constants.screenWidth * 0.25, height: 4)
                .padding(.trailing, 2.5)
        }.padding(.horizontal, 15)
        .padding(.vertical, 10)
        .transition(AnyTransition.scale)
        .background(self.messageRight ? LinearGradient(
        gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
        startPoint: .top, endPoint: .bottom) : LinearGradient(
            gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .shadow(color: self.messageRight ? Color.blue.opacity(0.15) : Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
        .onAppear() {
            self.updateAudioURL()
        }
    }

    func updateAudioURL() {
        do {
            let result = try storage?.entry(forKey: audioKey)

            guard let url = URL(string: result?.filePath ?? "") else { return }

            //audioPlayer = try AVAudioPlayer(contentsOf: url)
            //self.audioPlayer.prepareToPlay()
            //self.audioPlayer.play()
            print("found the url needed: \(url)")

        } catch {
            downloadFile(withUrl: URL(string: audioKey) ?? URL(fileURLWithPath: ""), key: audioKey, completion: { data in
                print("done downloading the audio!!!")
            })
        }
    }
    
    func downloadFile(withUrl url: URL, key: String, completion: @escaping (Data) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data.init(contentsOf: url)
                
                self.storage?.async.setObject(data, forKey: key, completion: { _ in
                    DispatchQueue.main.async {
                        completion(data)
                    }
                })
            } catch {
                print("an error happened while downloading or saving the file")
            }
        }
    }
}
