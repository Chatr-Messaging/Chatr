//
//  Microphone.swift
//  SoundVisualizer
//
//  Created by Brandon Baars on 1/22/20.
//  Copyright © 2020 Brandon Baars. All rights reserved.
//

import Foundation
import AVFoundation

class AudioVisualizeObserver: ObservableObject {
    
    // 1
    //private var audioPlayer: AVAudioPlayer
    private var timer: Timer?
    
    private var currentSample: Int
    private let numberOfSamples: Int
    
    var viewModel: ChatMessageViewModel?
    
    // 2
    @Published public var soundSamples: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples // In production check this is > 0.
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
    }
    
    func startObservingViz() {
        guard let viewModelz = self.viewModel else {
            return
        }

        viewModelz.audio.audioPlayer.isMeteringEnabled = true
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
            viewModelz.audio.audioPlayer.updateMeters()
            self.soundSamples[self.currentSample] = viewModelz.audio.audioPlayer.averagePower(forChannel: 0)
            self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        })
    }
    
    func stopObservingViz() {
        self.timer?.invalidate()
    }
    
    // 8
    deinit {
        timer?.invalidate()
    }
}
