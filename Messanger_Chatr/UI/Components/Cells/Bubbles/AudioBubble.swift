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

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        HStack(spacing: 5) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                 if self.isPlayingAudio {
                    self.stopAudio()
                    print("stop playing")
                 } else {
                    self.playAudio()
                    print("stop??? lolll playing")
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
            self.loadAudio(localPath: self.message.localAttachmentPath, fileId: self.audioKey, completion: { })
        }
    }
    
    func loadAudio(localPath: String, fileId: String, completion: @escaping () -> Void) {
        Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
            print("the progress of the audio download is: \(progress)")
        }, successBlock: { data in
            //self.storage?.async.setObject(data, forKey: fileId, completion: { _ in })
            
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileFolder = path.appendingPathComponent("dialog_audioMsg/\(fileId)")

            let folderExists = (try? fileFolder.checkResourceIsReachable()) ?? false
            if !folderExists {
                try? FileManager.default.createDirectory(at: fileFolder.absoluteURL, withIntermediateDirectories: false)
            }

            //let randomInt = Int.random(in: 1000000..<9999999)
            let fileName = fileFolder.appendingPathComponent("\(fileId).m4a")

            do {
                try data.write(to: fileName)
                //updateMessageVideoURL(messageId: self.message.id, localUrl: fileName.absoluteString)
                print("ayyy saved the audio file rigth at: \(fileName)")
                self.fetchAudioRecording(completion: {  })
            } catch {
                print(error.localizedDescription)
            }
 
            print("successfully saved the audio file from download")
            
            completion()
        }, errorBlock: { error in
            print("the error audiooo is: \(String(describing: error.localizedDescription))")
            completion()
        })
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
        self.recordingsList.removeAll()
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentDirectory.appendingPathComponent("dialog_audioMsg/\(self.audioKey)")

        do {
            print("fetching contents: \(folderURL.absoluteString)")
            let directoryContents = try fileManager.contentsOfDirectory(at: folderURL.absoluteURL, includingPropertiesForKeys: nil)

            for audio in directoryContents {
                let recording = Recording(fileURL: audio, createdAt: self.getCreationDate(for: audio.absoluteURL))
                print("contents: \(audio)")
                self.recordingsList.append(recording)
            }
        } catch { }

        print("the recording count is: \(self.recordingsList.count)")

        completion()
    }
    
    func stopAudio() {
        DispatchQueue.main.async {
            self.isPlayingAudio = false

            guard self.audioPlayer.isPlaying else { return }

            self.audioPlayer.pause()
        }
    }
    
    func playAudio() {
        DispatchQueue.main.async {
            guard let recording = self.recordingsList.first else { return }

            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)

            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
                //self.timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
                //self.audioPlayer.delegate = self
                //self.audioPlayer.prepareToPlay()
                self.audioPlayer.play()
                self.isPlayingAudio = true
             } catch {
                print("Error playing audio")
             }
        }
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
        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
            let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
            return creationDate
        } else {
            return Date()
        }
    }
}
