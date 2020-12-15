//
//  CameraViewController.swift
//  SwiftUI-CameraApp
//
//  Created by Gaspard Rosay on 28.01.20.
//  Copyright © 2020 Gaspard Rosay. All rights reserved.
//

import AVFoundation
import SwiftUI

struct CameraViewController : UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var cameraState: QuickSnapViewingState
    @Binding var didTapCapture: Bool
    @Binding var isCameraUsingFront: Bool
    @Binding var cameraFocusPoint: CGPoint

    
     func makeUIViewController(context: Context) -> CustomCameraController {
         let controller = CustomCameraController()
         controller.delegate = context.coordinator
        
         return controller
     }
     
     func updateUIViewController(_ cameraViewController: CustomCameraController, context: Context) {
        if self.cameraState == .camera {
            print("camera sate is alive! From ViewContreoller")
            if !cameraViewController.captureSession.isRunning {
                let loadingTxt = UILabel(frame: CGRect(x: Constants.screenWidth / 2 - 75, y: Constants.screenHeight / 2 - 75, width: 150, height: 50))
                loadingTxt.textAlignment = NSTextAlignment.center
                loadingTxt.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
                loadingTxt.text = "loading camera..."
                loadingTxt.textColor = UIColor.white
                cameraViewController.view.addSubview(loadingTxt)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    cameraViewController.captureSession.startRunning()
                    loadingTxt.removeFromSuperview()
                }
            }
            
            if self.didTapCapture {
                cameraViewController.didTapRecord()
            }
           
           if self.isCameraUsingFront {
               cameraViewController.cameraSwitchAction()
           } else {
               cameraViewController.cameraSwitchAction()
           }
           
           let image: UIImage = UIImage(named: "FocusIcon")!
           let focusView = UIImageView(image: image)
           focusView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
           focusView.center = cameraFocusPoint
           focusView.tintColor = .white
           focusView.layer.shadowColor = UIColor.black.cgColor
           focusView.layer.shadowOpacity = 0.4
           focusView.layer.shadowOffset = CGSize.zero
           focusView.layer.shadowRadius = 4
           focusView.alpha = 0.0
           cameraViewController.view.addSubview(focusView)
           
           UIView.animate(withDuration: 0.20, delay: 0.0, options: .curveEaseInOut, animations: {
               focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
           }, completion: { (success) in
               UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                   focusView.alpha = 0.0
                   focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
               }, completion: { (success) in
                   focusView.removeFromSuperview()
               })
           })
           
           if let device = cameraViewController.currentCamera {
                do {
                    try device.lockForConfiguration()
                    if device.isFocusPointOfInterestSupported {
                       device.focusPointOfInterest = cameraFocusPoint
                       device.focusMode = AVCaptureDevice.FocusMode.autoFocus
                    }
                    if device.isExposurePointOfInterestSupported {
                       device.exposurePointOfInterest = cameraFocusPoint
                       device.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
                    }
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        device.focusMode = .continuousAutoFocus
                    }
                    if device.isExposureModeSupported(.continuousAutoExposure) {
                        device.exposureMode = .continuousAutoExposure
                    }
                    device.unlockForConfiguration()
                } catch {
                    // Handle errors here
                }
            }
        } else {
            if cameraViewController.captureSession.isRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if self.cameraState != .camera {
                        cameraViewController.captureSession.stopRunning()
                    }
                }
            }
        }
     }
    
     func makeCoordinator() -> Coordinator {
         Coordinator(self)
     }
     
     class Coordinator: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
         let parent: CameraViewController
         
         init(_ parent: CameraViewController) {
             self.parent = parent
         }
         
         func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
             parent.didTapCapture = false

            guard let imageData = photo.cgImageRepresentation() else {
                print("Can't take image from output")
                return
            }
            let cgimage = imageData.takeUnretainedValue()
            let orientation: UIImage.Orientation = .right
            let image = UIImage(cgImage: cgimage, scale: 0.75, orientation: orientation)
            if let data = image.jpegData(compressionQuality: 0.1) {
                parent.image = UIImage(data: data)?.fixedOrientation()
            }
         }
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

