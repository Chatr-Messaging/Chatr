//
//  VoiceViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/22/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import AVFoundation

struct Recording {
    let fileURL: URL
    let createdAt: Date
}

class VoiceViewModel: NSObject , ObservableObject , AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder = AVAudioRecorder()
    var audioPlayer: AVAudioPlayer = AVAudioPlayer()

    @Published var isRecording: Bool = false
    @Published var isPlayingAudio: Bool = false
    @Published var recordingsList: [Recording] = []
    @Published var durationString: String = "0:00"
    @Published var playingBubbleId: String = ""
    @Published var timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @Published var time = 0

    override init(){
        super.init()
    }
    
    func playAudioRecording() {
        guard let recording = self.recordingsList.first else { return }

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            self.timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
            self.audioPlayer.delegate = self
            self.audioPlayer.prepareToPlay()
            self.audioPlayer.play()
            self.isPlayingAudio = true
         } catch {  }
    }
    
    func prepAudio() {
        guard let recording = self.recordingsList.first else { return }

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            self.audioPlayer.prepareToPlay()
         } catch {  }
    }
    
    func stopAudioRecording() {
        guard self.audioPlayer.isPlaying else { return }

        self.audioPlayer.pause()
    }
   
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {  }

        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileFolder = path.appendingPathComponent("voiceMessageRecordings")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let folderExists = (try? fileFolder.checkResourceIsReachable()) ?? false
        if !folderExists {
            try? FileManager.default.createDirectory(at: fileFolder.absoluteURL, withIntermediateDirectories: false)
        }
        
        do {
            let randomInt = Int.random(in: 1000000..<9999999)

            let fileName = fileFolder.appendingPathComponent("\(randomInt).m4a")

            self.audioRecorder = try AVAudioRecorder(url: fileName, settings: settings)
            self.audioRecorder.prepareToRecord()
            self.audioRecorder.record()
            self.isRecording = true
            self.timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
        } catch {  }
    }

    func stopRecording() {
        DispatchQueue.main.async {
            self.audioRecorder.stop()
            self.isRecording = false
            self.timer.upstream.connect().cancel()

            self.fetchAudioRecording(completion: { _ in })
        }
    }

    func fetchAudioRecording(completion: @escaping (Recording) -> (Void)) {
        recordingsList.removeAll()
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentDirectory.appendingPathComponent("voiceMessageRecordings")

        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: folderURL.absoluteURL, includingPropertiesForKeys: nil)

            for audio in directoryContents {
                let recording = Recording(fileURL: audio, createdAt: getCreationDate(for: audio.absoluteURL))
                recordingsList.append(recording)
            }
        } catch { }

        recordingsList.sort(by: { $0.createdAt.compare($1.createdAt) == .orderedAscending})

        guard let firstRecording = self.recordingsList.first else { return }

        completion(firstRecording)
    }

    func deleteAudioFile() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationPath = documentsURL.appendingPathComponent("voiceMessageRecordings")
        //let directoryContents = try! fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        
        do {
            for audio in self.recordingsList {
                try fileManager.removeItem(at: audio.fileURL)
                if let index = self.recordingsList.firstIndex(where: { $0.fileURL == audio.fileURL }) {
                    self.recordingsList.remove(at: index)
                    self.time = 0
                }
            }
        } catch {  }
    }
    
    func getCreationDate(for file: URL) -> Date {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path) as [FileAttributeKey: Any],
            let creationDate = attributes[FileAttributeKey.creationDate] as? Date {
            return creationDate
        } else {
            return Date()
        }
    }

    func getTotalPlaybackDurationString() -> String {
        let (_, m, s) = secondsToHoursMinutesSeconds(seconds: (Int(self.audioPlayer.duration) - Int(self.audioPlayer.currentTime)))

        return String(format: "%d:%02d", arguments: [m, s])
    }

    func getTotalDurationString() -> String {
        let (_, m, s) = secondsToHoursMinutesSeconds(seconds: self.time)

        return String(format: "%d:%02d", arguments: [m, s])
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    //MARK: Delegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            self.stopAudioRecording()
            self.time = 0
        }
    }
}
