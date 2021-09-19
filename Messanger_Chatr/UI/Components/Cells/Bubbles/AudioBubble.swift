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
import ConnectyCube
import Cache

struct BarView: View {
    var value: CGFloat
    let numberOfSamples = 8
    var messageRight: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(self.messageRight ? Color.white : Color.primary)
                .frame(width: (60 - CGFloat(numberOfSamples) * 4) / CGFloat(numberOfSamples), height: value)
        }
    }
}

struct AudioIndicatorView: View {
    var messageRight: Bool = false
    var isBlue: Bool = false
    @Binding var isPlaying: Bool
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    @State private var yScaleIndicator1: CGFloat = 5
    @State private var yScaleIndicator2: CGFloat = 5
    @State private var yScaleIndicator3: CGFloat = 5
    @State private var yScaleIndicator4: CGFloat = 5
    @State private var yScaleIndicator5: CGFloat = 5
    @State private var yScaleIndicator6: CGFloat = 5

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
           RoundedRectangle(cornerRadius: 1)
                .frame(width: 3, height: self.yScaleIndicator1)
                .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                //.scaleEffect(x: 1, y: self.yScaleIndicator1 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                .animation(Animation.easeInOut(duration: 0.2))
            
            RoundedRectangle(cornerRadius: 1)
                 .frame(width: 3, height: self.yScaleIndicator2)
                 .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                 //.scaleEffect(x: 1, y: self.yScaleIndicator2 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                 .animation(Animation.easeInOut(duration: 0.2))
            
            RoundedRectangle(cornerRadius: 1)
                 .frame(width: 3, height: self.yScaleIndicator3)
                 .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                 //.scaleEffect(x: 1, y: self.yScaleIndicator3 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                 .animation(Animation.easeInOut(duration: 0.2))
            
            RoundedRectangle(cornerRadius: 1)
                 .frame(width: 3, height: self.yScaleIndicator4)
                 .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                 //.scaleEffect(x: 1, y: self.yScaleIndicator4 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                 .animation(Animation.easeInOut(duration: 0.2))
            
            RoundedRectangle(cornerRadius: 1)
                 .frame(width: 3, height: self.yScaleIndicator5)
                 .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                 //.scaleEffect(x: 1, y: self.yScaleIndicator5 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                 .animation(Animation.easeInOut(duration: 0.2))
            
            RoundedRectangle(cornerRadius: 1)
                 .frame(width: 3, height: self.yScaleIndicator6)
                 .foregroundColor(self.isBlue ? .blue : self.messageRight ? .white : .primary)
                 //.scaleEffect(x: 1, y: self.yScaleIndicator6 ? Double.random(in: 0.6...0.92) : 1.0, anchor: .center)
                 .animation(Animation.easeInOut(duration: 0.2))
        }.onReceive(self.timer) { time in
            guard self.isPlaying else { return }

            self.yScaleIndicator1 = CGFloat.random(in: 5..<18)
            self.yScaleIndicator2 = CGFloat.random(in: 5..<18)
            self.yScaleIndicator3 = CGFloat.random(in: 5..<18)
            self.yScaleIndicator4 = CGFloat.random(in: 5..<18)
            self.yScaleIndicator5 = CGFloat.random(in: 5..<18)
            self.yScaleIndicator6 = CGFloat.random(in: 5..<18)
        }
    }
}

struct AudioBubble: View {
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    var namespace: Namespace.ID
    @State var messageRight: Bool = false
    @State var audioProgress: CGFloat = 0
    @State var isPlayingAudio: Bool = false
    @State var durationString: String = "0:00"
    @State var timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 50), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 0)
                .frame(width: self.audioProgress)
                .foregroundColor(Color("bgColor_opposite").opacity(0.25))

            HStack(alignment: .center, spacing: 5) {
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
                    Image(systemName: self.isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32, alignment: .center)
                        .font(Font.title.weight(.regular))
                        .foregroundColor(self.messageRight ? .white : .blue)
                }
                
                Text(self.durationString)
                    .foregroundColor(self.messageRight ? .white : .primary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 40)
                    .padding(.trailing, 5)
                    .onReceive(self.timer) { time in
                        guard self.viewModel.audio.playingBubbleId == self.message.id.description else {
                            print("not the correct cell to play from: \(self.message.id.description)")
                            self.isPlayingAudio = false
                            self.timer.upstream.connect().cancel()

                            return
                        }

                        print("the time is: \(time) for: \(self.message.id.description)")
                        self.durationString = self.viewModel.audio.getTotalPlaybackDurationString()
                        self.audioProgress = CGFloat(self.viewModel.audio.audioPlayer.currentTime / self.viewModel.audio.audioPlayer.duration) * CGFloat(Constants.screenWidth * 0.4)
                    }

                AudioIndicatorView(messageRight: self.messageRight, isPlaying: self.$isPlayingAudio)
            }.padding(.horizontal)
            .padding(.vertical, 10)
            .onDisappear {
                self.viewModel.audio.playingBubbleId = ""
            }
        }
        //.transition(AnyTransition.scale)
        .frame(width: Constants.screenWidth * 0.4)
        .background(self.messageRight ? LinearGradient(
        gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
        startPoint: .top, endPoint: .bottom) : LinearGradient(
            gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .shadow(color: self.messageRight ? Color.blue.opacity(0.15) : Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
        .matchedGeometryEffect(id: self.message.id.description + "audio", in: namespace)
    }
    
    func loadAudio(fileId: String) {
        DispatchQueue.main.async {
            guard self.viewModel.audio.playingBubbleId != self.message.id.description else {
                self.viewModel.audio.audioPlayer.prepareToPlay()
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
                    self.viewModel.audio.audioPlayer.prepareToPlay()
                    self.viewModel.audio.audioPlayer.play()
                    self.isPlayingAudio = true
                    print("successfully added cached audio data \(String(describing: result?.object))")
                } else {
                    print("error setting audio")
                }
                
                //self.audioPlayer = try AVAudioPlayer(data: result?.object ?? Data())
            } catch {
                print("could not find cached audio... downloading now..")
                Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
                    print("the progress of the audio download is: \(progress)")
                }, successBlock: { data in
                    //self.storage?.async.setObject(data, forKey: fileId, completion: { _ in })
                    self.storage?.async.setObject(data, forKey: fileId, completion: { test in
                        print("the testtt data is: \(data)")
                    })
                    
                    do {
                        self.viewModel.audio.audioPlayer = try AVAudioPlayer(data: data)
                        print("got it and now going to play it")
                        self.isPlayingAudio = true
                        self.viewModel.audio.audioPlayer.play()
                    } catch {
                        print("failed to set new audio")
                    }
         
                    print("successfully saved the audio file from download")
                }, errorBlock: { error in
                    print("the error audiooo is: \(String(describing: error.localizedDescription))")
                })
            }
        }
    }
    
//    func updateMessageVideoURL(messageId: String, localUrl: String) {
//        let config = Realm.Configuration(schemaVersion: 1)
        //let storage = Storage.storage()

//        do {
//            let realm = try Realm(configuration: config)
//            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
//                if realmContact.localAttachmentPath == "" {
//                    do {
//                        try realm.safeWrite {
//                            realmContact.localAttachmentPath = localUrl
//                            realm.add(realmContact, update: .all)
//                        }
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                    let videoReference = storage.reference().child("messageVideo").child(fileId)
//                    videoReference.downloadURL { url, error in
//
//                    }
//                }
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
    
//    func fetchAudioRecording(completion: @escaping () -> (Void)) {
//        self.viewModel.audio.recordingsList.removeAll()
//
//        let documentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
//
//        let folderString = documentDirectory.appending("/dialog_audioMsg/\(self.audioKey)/\(self.audioKey).m4a")
//        let folderUrl = URL(fileURLWithPath: folderString)
//
//        let recording = Recording(fileURL: folderUrl, createdAt: self.getCreationDate(for: folderUrl))
//        print("contents: \(folderString)")
//        self.viewModel.audio.recordingsList.append(recording)
//
//        print("the recording count is: \(self.viewModel.audio.recordingsList.count)")
//
//        completion()
//    }

//    func stopAudio() {
//        DispatchQueue.main.async {
//            self.isPlayingAudio = false
//
//            guard self.viewModel.audio.audioPlayer.isPlaying else { return }
//
//            self.viewModel.audio.audioPlayer.pause()
//        }
//    }
    
    //func playAudio() {
        //DispatchQueue.main.async {
            //if let recording = self.viewModel.audio.recordingsList.first {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)
//        } catch {
//
//        }

        //print("trying to play")
        //self.viewModel.audio.audioPlayer = self.audioPlayer
        //self.timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
        //self.audioPlayer.delegate = self
        //self.audioPlayer.prepareToPlay()
        //self.viewModel.audio.audioPlayer.play()
        //self.viewModel.audio.isPlayingAudio = true
                //}
        //}
    //}
    
//    func prepAudio() {
//        guard let recording = self.recordingsList.first else { return }
//
//        do {
//            self.audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
//            self.audioPlayer.prepareToPlay()
//         } catch {
//            print("Error preping audio")
//         }
//    }
    
    //func getCreationDate(for file: URL) -> Date {
//        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
//            let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
//            return creationDate
//        } else {
            //return Date()
        //}
    //}
}
