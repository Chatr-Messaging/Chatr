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

struct AudioBubble: View {
    @ObservedObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    @State var messageRight: Bool = false
    @State var audioKey: String = ""
    @State var audioProgress: CGFloat = 0
    @State var isPlayingAudio: Bool = false
    @State var durationString: String = "0:00"
    @State var recordingsList: [Recording] = []
    @State var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State var time = 0

    @State var audioPlayer: AVAudioPlayer = AVAudioPlayer()
    @State var player: AVPlayer = AVPlayer()
    
    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        HStack(spacing: 5) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                if self.isPlayingAudio {
                    self.viewModel.audio.stopAudioRecording()
                    print("stop playing")
                 } else {
                    //self.playAudio()
                     self.loadAudio(fileId: self.audioKey)
                    print("stop??? lolll playing")
                 }
            }) {
                Image(systemName: self.isPlayingAudio ? "pause.fill" : "play.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20, alignment: .center)
                    .font(Font.title.weight(.regular))
                    .foregroundColor(self.messageRight ? .white : .blue)
                    .padding(.leading, 15)
            }
            
            Text(self.viewModel.audio.durationString)
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
                        //.frame(width: self.audioProgress)
                }.frame(width: Constants.screenWidth * 0.25, height: 4)
                .padding(.trailing, 2.5)
        }.padding(.horizontal, 15)
        .padding(.vertical, 10)
        //.transition(AnyTransition.scale)
        .background(self.messageRight ? LinearGradient(
        gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
        startPoint: .top, endPoint: .bottom) : LinearGradient(
            gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .shadow(color: self.messageRight ? Color.blue.opacity(0.15) : Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
    }
    
    func loadAudio(fileId: String) {
        DispatchQueue.main.async {
            do {
                print("the audio cashed id is: \(fileId)")
                let result = try storage?.entry(forKey: fileId)
                if let objectData = result?.object {
                    self.viewModel.audio.audioPlayer = try AVAudioPlayer(data: objectData)
                    print("got it and now going to play it222")
                    self.viewModel.audio.audioPlayer.play()
                    self.viewModel.audio.isPlayingAudio = true
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
                        self.viewModel.audio.audioPlayer.play()
                        self.isPlayingAudio = true
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
    
    func updateMessageVideoURL(messageId: String, localUrl: String) {
        let config = Realm.Configuration(schemaVersion: 1)
        //let storage = Storage.storage()

        do {
            let realm = try Realm(configuration: config)
            if let realmContact = realm.object(ofType: MessageStruct.self, forPrimaryKey: messageId) {
                if realmContact.localAttachmentPath == "" {
                    do {
                        try realm.safeWrite {
                            realmContact.localAttachmentPath = localUrl
                            realm.add(realmContact, update: .all)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
//                    let videoReference = storage.reference().child("messageVideo").child(fileId)
//                    videoReference.downloadURL { url, error in
//
//                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func fetchAudioRecording(completion: @escaping () -> (Void)) {
        self.viewModel.audio.recordingsList.removeAll()
        
        let documentDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]

        let folderString = documentDirectory.appending("/dialog_audioMsg/\(self.audioKey)/\(self.audioKey).m4a")
        let folderUrl = URL(fileURLWithPath: folderString)

        let recording = Recording(fileURL: folderUrl, createdAt: self.getCreationDate(for: folderUrl))
        print("contents: \(folderString)")
        self.viewModel.audio.recordingsList.append(recording)

        print("the recording count is: \(self.viewModel.audio.recordingsList.count)")

        completion()
    }

    func stopAudio() {
        DispatchQueue.main.async {
            self.viewModel.audio.isPlayingAudio = false

            guard self.viewModel.audio.audioPlayer.isPlaying else { return }

            self.viewModel.audio.audioPlayer.pause()
        }
    }
    
    func playAudio() {
        //DispatchQueue.main.async {
            //if let recording = self.viewModel.audio.recordingsList.first {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)
        } catch {
            
        }

        print("trying to play")
        self.viewModel.audio.audioPlayer = self.audioPlayer
        //self.timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
        //self.audioPlayer.delegate = self
        //self.audioPlayer.prepareToPlay()
        self.viewModel.audio.audioPlayer.play()
        self.viewModel.audio.isPlayingAudio = true
                //}
        //}
    }
    
    func prepAudio() {
        guard let recording = self.recordingsList.first else { return }

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            self.audioPlayer.prepareToPlay()
         } catch {
            print("Error preping audio")
         }
    }
    
    func getCreationDate(for file: URL) -> Date {
//        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
//            let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
//            return creationDate
//        } else {
            return Date()
        //}
    }
}
