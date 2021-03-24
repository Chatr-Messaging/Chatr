//
//  PlayerView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/20/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI
import RealmSwift
import Cache
import Firebase

struct PlayerView: UIViewRepresentable {
    @Binding var player: AVPlayer
    @Binding var totalDuration: Double

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
        (uiView as? PlayerUIView)?.updatePlayer(player: player)
    }

    func makeUIView(context: Context) -> UIView {
        return PlayerUIView(player: player)
    }
}

class PlayerUIView: UIView {
    private let playerLayer = AVPlayerLayer()

    init(player: AVPlayer) {
        super.init(frame: .zero)

        playerLayer.player = player
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    func updatePlayer(player: AVPlayer) {
        DispatchQueue.main.async {
            self.playerLayer.player = player
        }
    }
}

struct ChatrVideoPlayer: UIViewControllerRepresentable {
    @Binding var player1: AVPlayer
    @Binding var totalDuration: Double
    @State var fileId: String = ""
    @State var videoUrl: URL?
    let storageFirebase = Storage.storage()

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 10), transformer: TransformerFactory.forData())
    }()
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = UIViewController()
        let controller = AVPlayerLayer()

        DispatchQueue.main.async {
            do {
                let result = try storage?.entry(forKey: videoUrl?.absoluteString ?? "")
                // The video is cached.
                print("this video is saved so pulling from local")
                let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mp4", fileExtension: "mp4")
                self.player1 = AVPlayer(playerItem: playerItem)
            } catch {
                let videoReference = storageFirebase.reference().child("messageVideo").child(fileId)
                videoReference.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    if error == nil {
                        guard let videoData = data else { return }

                        print("video done downloading... now saving video to cache!")
                        let playerItem = CachingPlayerItem(data: videoData, mimeType: "video/mp4", fileExtension: "mp4")
                        self.player1 = AVPlayer(playerItem: playerItem)

                        self.storage?.async.setObject(videoData, forKey: videoUrl?.absoluteString ?? "", completion: { _ in })
                        
//                        let tmpFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("video" + fileId).appendingPathExtension("mp4")
//                        do {
//                            try videoData.write(to: tmpFileURL, options: [.atomic])
//                        } catch { }
//
//                        let videoAsset = AVURLAsset(url: tmpFileURL)
//                        let playerItem = AVPlayerItem(asset: videoAsset)
//                        self.player1 = AVPlayer(playerItem: playerItem)
                    } else {
                        print("the error is: \(String(describing: error?.localizedDescription))")
                    }
                }
            }

            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.main.bounds.width * 0.65, height: UIScreen.main.bounds.height * 0.55))

            controller.player = self.player1
            self.player1.isMuted = true

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch  { }
            
            controller.videoGravity = AVLayerVideoGravity.resizeAspect
            controller.frame = rect
            view.view.layer.addSublayer(controller)
            view.preferredContentSize = controller.frame.size

            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player1.currentItem, queue: .main) { _ in
                self.player1.seek(to: CMTime.zero)
                self.player1.play()
            }

            self.player1.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: nil) { time in
                guard let item = self.player1.currentItem else { return }

                self.totalDuration = item.duration.seconds - item.currentTime().seconds
            }
        }
        
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}

struct DetailVideoPlayer: UIViewControllerRepresentable {
    @ObservedObject var viewModel: ChatMessageViewModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        let view = UIViewController()
        let controller = AVPlayerLayer(player: self.viewModel.player)

        DispatchQueue.main.async {
            let videoAssetTrack = self.viewModel.player.currentItem?.asset.tracks(withMediaType: AVMediaType.video).first
            let naturalSize = videoAssetTrack?.naturalSize
            let videoRatio = (naturalSize?.height ?? 0) / (naturalSize?.width ?? 0)
            let width = naturalSize?.width ?? 0 > UIScreen.main.bounds.width - 20 ? UIScreen.main.bounds.width - 20 : naturalSize?.width ?? 75
            let heightRatio = (naturalSize?.height ?? 0) / videoRatio
            let height = heightRatio > UIScreen.main.bounds.height * 0.65 ? UIScreen.main.bounds.height * 0.65 : heightRatio
            let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: height))

            self.viewModel.player.isMuted = false
            self.viewModel.player.play()
            self.viewModel.videoSize = rect.size
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch  { }

            controller.videoGravity = AVLayerVideoGravity.resizeAspect
            controller.frame = rect
            view.view.layer.addSublayer(controller)
            view.preferredContentSize = rect.size

            self.viewModel.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: nil) { time in
                guard let item = self.viewModel.player.currentItem else { return }

                self.viewModel.totalDuration = item.duration.seconds - item.currentTime().seconds
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

extension AVAsset {
    func videoSize() -> CGSize {
        let tracks = self.tracks(withMediaType: AVMediaType.video)
        if (tracks.count > 0){
            let videoTrack = tracks[0]
            let size = videoTrack.naturalSize
            let txf = videoTrack.preferredTransform
            let realVidSize = size.applying(txf)
            print(videoTrack)
            print(txf)
            print(size)
            print(realVidSize)
            return realVidSize
        }
        return CGSize(width: 0, height: 0)
    }

}
