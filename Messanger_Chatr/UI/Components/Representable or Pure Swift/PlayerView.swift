//
//  PlayerView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/20/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import SwiftUI
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
