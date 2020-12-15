//
//  GIFController.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/21/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import GiphyUISDK
import GiphyCoreSDK

struct GIFController : UIViewControllerRepresentable {
    @Binding var url: String
    @Binding var present: Bool
    
    func makeCoordinator() -> Coordinator {
        return GIFController.Coordinator(parent: self)
    }
    func makeUIViewController(context: Context) -> some GiphyViewController {
        Giphy.configure(apiKey: "ZeBVD7S60sCcampPx2iQDVO8SwLvG00P")
        let controller = GiphyViewController()
        controller.mediaTypeConfig = [.emoji, .gifs, .stickers]
        controller.delegate = context.coordinator
        controller.theme = GPHTheme(type: .automatic)
        GiphyViewController.trayHeightMultiplier = 1.05
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    class Coordinator: NSObject, GiphyDelegate {
        var parent: GIFController
        
        init(parent: GIFController) {
            self.parent = parent
        }
        
        func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
            let url = media.url(rendition: .fixedWidth, fileType: .gif)
            parent.url = url ?? ""
            parent.present.toggle()
        }
        
        func didDismiss(controller: GiphyViewController?) {
            
        }
    }
}

struct CustomGIFShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 20, height: 20))
        
        return Path(path.cgPath)
    }
}
