//
//  PlayerView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/20/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI
import RealmSwift
import Cache
import ConnectyCube

struct PlayerView: UIViewRepresentable {
    @Binding var player: AVPlayer
    @Binding var totalDuration: Double

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
        (uiView as? PlayerUIView)?.updatePlayer(player: player)
    }

    func makeUIView(context: Context) -> UIView {
        let playerView = PlayerUIView(player: player)

        return playerView
    }
}

class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playerLayer.removeAllAnimations()
    }

    func updatePlayer(player: AVPlayer) {
        DispatchQueue.main.async {
            self.playerLayer.player = player
        }
    }
}

struct DetailVideoPlayer: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ChatMessageViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = UIViewController()
        let controller = AVPlayerLayer(player: self.viewModel.player)

        DispatchQueue.main.async {
            if let videoAssetTrack = self.viewModel.player.currentItem?.asset.tracks(withMediaType: AVMediaType.video).first {
                let naturalSize = videoAssetTrack.naturalSize.applying(videoAssetTrack.preferredTransform)
                let height3 = abs(naturalSize.width) > UIScreen.main.bounds.width ? UIScreen.main.bounds.width : abs(naturalSize.width)
                let width3 = (height3 * abs(naturalSize.width) / abs(naturalSize.height))
                let mainRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width3, height: height3))

                self.viewModel.player.isMuted = false
                self.viewModel.player.play()
                self.viewModel.videoSize = mainRect.size

                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback)
                } catch  { }

                controller.videoGravity = AVLayerVideoGravity.resizeAspect
                controller.frame = mainRect
                view.view.layer.addSublayer(controller)
                view.preferredContentSize = mainRect.size

                self.viewModel.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: nil) { time in
                    guard let item = self.viewModel.player.currentItem else { return }

                    self.viewModel.totalDuration = item.duration.seconds - item.currentTime().seconds
                }
            }
        }
        
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct CustomProgressBar : UIViewRepresentable {
    @Binding var value : Float
    @Binding var player : AVPlayer
    @Binding var isPlaying : Bool

    func makeCoordinator() -> CustomProgressBar.Coordinator {
        return CustomProgressBar.Coordinator(parent1: self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<CustomProgressBar>) -> UISlider {
        let slider = UISlider()
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = UIColor(named: "blurBorder")
        slider.thumbTintColor = .white
        slider.setThumbImage(UIImage(named: "thumb"), for: .normal)
        slider.value = value
        slider.addTarget(context.coordinator, action: #selector(context.coordinator.changed(slider:)), for: .valueChanged)

        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: UIViewRepresentableContext<CustomProgressBar>) {
        uiView.value = value
    }
    
    class Coordinator : NSObject{
        var parent : CustomProgressBar
        
        init(parent1 : CustomProgressBar) {
            parent = parent1
        }

        @objc func changed(slider : UISlider){
            if slider.isTracking{
                parent.player.pause()
                let sec = Double(slider.value * Float((parent.player.currentItem?.duration.seconds)!))
                parent.player.seek(to: CMTime(seconds: sec, preferredTimescale: 1))
            } else {
                let sec = Double(slider.value * Float((parent.player.currentItem?.duration.seconds)!))

                parent.player.seek(to: CMTime(seconds: sec, preferredTimescale: 1))
                if parent.isPlaying {
                    parent.player.play()
                }
            }
        }
    }
}
