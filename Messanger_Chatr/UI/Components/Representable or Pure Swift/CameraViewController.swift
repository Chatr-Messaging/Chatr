//
//  CameraViewController.swift
//  SwiftUI-CameraApp
//
//  Created by Gaspard Rosay on 28.01.20.
//  Copyright © 2020 Gaspard Rosay. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftUI
import AgoraUIKit_iOS

struct AgoraVideo: UIViewRepresentable {
    typealias UIViewType = AgoraVideoViewer

    func makeUIView(context: Context) -> AgoraVideoViewer {
        let agview = AgoraVideoViewer(connectionData: AgoraConnectionData(appId: "404feedfd57c4ed2a3b7e3d5780c5114", appToken: "006404feedfd57c4ed2a3b7e3d5780c5114IAAfjGAKg27oySoIq2rAZoeYgTqVvDFUEVIsSbLnG9g6MumVuToAAAAAEAB9PQWkGn5iYQEAAQAZfmJh"))
        agview.join(channel: "testChannel1")
        
        return agview
    }
    
    func updateUIView(_ uiView: AgoraVideoViewer, context: Context) {
    
    }
}

struct CameraViewController : UIViewRepresentable {
    @ObservedObject var camera: CameraViewModel
    
    func makeUIView(context: Context) ->  UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

extension UIImage {
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != UIImage.Orientation.up else {
                // This is default orientation, don't need to do anything
                return self.copy() as? UIImage
            }

            guard let cgImage = self.cgImage else {
                // CGImage is not available
                return nil
            }

            guard let colorSpace = cgImage.colorSpace, let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return nil // Not able to create CGContext
            }

            var transform: CGAffineTransform = CGAffineTransform.identity

            switch imageOrientation {
            case .down, .downMirrored:
                transform = transform.translatedBy(x: size.width, y: size.height)
                transform = transform.rotated(by: CGFloat.pi)
            case .left, .leftMirrored:
                transform = transform.translatedBy(x: size.width, y: 0)
                transform = transform.rotated(by: CGFloat.pi / 2.0)
            case .right, .rightMirrored:
                transform = transform.translatedBy(x: 0, y: size.height)
                transform = transform.rotated(by: CGFloat.pi / -2.0)
            case .up, .upMirrored:
                break
            @unknown default:
                break
            }

            // Flip image one more time if needed to, this is to prevent flipped image
            switch imageOrientation {
            case .upMirrored, .downMirrored:
                transform = transform.translatedBy(x: size.width, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .leftMirrored, .rightMirrored:
                transform = transform.translatedBy(x: size.height, y: 0)
                transform = transform.scaledBy(x: -1, y: 1)
            case .up, .down, .left, .right:
                break
            @unknown default:
                break
            }

            ctx.concatenate(transform)

            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            default:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                break
            }

            guard let newCGImage = ctx.makeImage() else { return nil }
            
            return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
        }
}
