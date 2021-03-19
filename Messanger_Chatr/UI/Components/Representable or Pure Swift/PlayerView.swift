//
//  PlayerView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/20/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import SwiftUI
import Firebase
import AVKit

enum PlayerGravity {
    case aspectFill
    case resize
}

struct PlayerContainerView: UIViewRepresentable {
    @Binding var player: AVPlayer
    var gravity: PlayerGravity

    func makeUIView(context: UIViewRepresentableContext<PlayerContainerView>) -> UIView {
        return PlayerView(player: player, gravity: gravity)
    }

    func updateUIView(_ uiView: UIView,
                      context: UIViewRepresentableContext<PlayerContainerView>) {

    }
}

//class PlayerContainerView: UIViewRepresentable {
//    @Binding var player: AVPlayer
//    var gravity: PlayerGravity
//
//    func makeUIView(context: Context) -> PlayerView {
//        return PlayerView(player: player, gravity: gravity)
//    }
//
//    func updateUIView(_ uiView: PlayerView, context: Context) { }
//}

class PlayerView: UIView {
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    let gravity: PlayerGravity
    
    init(player: AVPlayer, gravity: PlayerGravity) {
        self.gravity = gravity
        super.init(frame: .zero)
        self.player = player
        self.backgroundColor = .black

        setupLayer()
    }
    
    func setupLayer() {
        switch gravity {
    
        case .aspectFill:
            playerLayer.contentsGravity = .resizeAspectFill
            playerLayer.videoGravity = .resizeAspectFill
            
        case .resize:
            playerLayer.contentsGravity = .resize
            playerLayer.videoGravity = .resize
            
        }
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}



struct FullScreenVideoUI: UIViewControllerRepresentable {
    let storage = Storage.storage()
    @Binding var player1: AVPlayer
    @Binding var size: CGSize
    @State var fileId: String = ""

    func makeUIViewController(context: Context) -> UIViewController {
        let videoReference = storage.reference().child("messageVideo").child(fileId)
        let view = UIViewController()

        videoReference.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if error == nil {
                let tmpFileURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("video" + fileId).appendingPathExtension("mp4")
                do {
                    try data!.write(to: tmpFileURL, options: [.atomic])
                } catch { }

                let videoAsset = AVURLAsset(url: tmpFileURL)
                let videoAssetTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first
                let playerItem = AVPlayerItem(asset: videoAsset)
                self.player1 = AVPlayer(playerItem: playerItem)
                let controller = AVPlayerLayer(player: self.player1)
                let naturalSize = videoAssetTrack?.naturalSize
                let videoRatio = (naturalSize?.height ?? 0) / (naturalSize?.width ?? 0)
                let width = naturalSize?.width ?? 0 > UIScreen.main.bounds.width * 0.65 ? UIScreen.main.bounds.width * 0.65 : naturalSize?.width ?? 75
                let widthDelta = width / (naturalSize?.width ?? 0)
                let height = (naturalSize?.height ?? 0) * widthDelta
                let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: width, height: UIScreen.main.bounds.height * 0.65))

                self.size = rect.size
                print("the size of the video is: \(naturalSize) && rect: \(rect.size) ratio: \(widthDelta)")

                controller.player = self.player1
                self.player1.isMuted = false

                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback)
                } catch  { }
                
                controller.videoGravity = AVLayerVideoGravity.resizeAspect
                controller.frame = rect
                view.view.layer.addSublayer(controller)
                view.preferredContentSize = rect.size
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player1.currentItem, queue: .main) { _ in
                    self.player1.seek(to: CMTime.zero)
                    self.player1.play()
                }
            } else {
                print("the error is: \(error?.localizedDescription)")
            }
        }
        return view
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
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
