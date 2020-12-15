//
//  CameraController.swift
//  SwiftUI-CameraApp
//
//  Created by Gaspard Rosay on 28.01.20.
//  Copyright © 2020 Gaspard Rosay. All rights reserved.
//

import UIKit
import AVFoundation

class CustomCameraController: UIViewController {
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //DELEGATE
    var delegate: AVCapturePhotoCaptureDelegate?
    
    func didTapRecord() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: delegate!)
    }
    
    func setFrontCamera() {
        print("set front camera")
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.front)
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case AVCaptureDevice.Position.front:
                self.frontCamera = device
            case AVCaptureDevice.Position.back:
                self.backCamera = device
            default:
                break
            }
        }
        self.currentCamera = self.frontCamera
    }
    
    func setBackCamera() {
        print("set back camera")
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case AVCaptureDevice.Position.front:
                self.frontCamera = device
            case AVCaptureDevice.Position.back:
                self.backCamera = device
            default:
                break
            }
        }
        self.currentCamera = self.backCamera
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    
        let tapFlip = UITapGestureRecognizer(target: self, action: #selector(cameraSwitchAction))
        tapFlip.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapFlip)
    }
    
    func setup() {
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        //startRunningCaptureSession()
    }
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.unspecified)
        for device in deviceDiscoverySession.devices {
            switch device.position {
            case AVCaptureDevice.Position.front:
                self.frontCamera = device
            case AVCaptureDevice.Position.back:
                self.backCamera = device
            default:
                break
            }
        }
        
        self.currentCamera = self.backCamera
    }
    
    
    func setupInputOutput() {
        do {
            if let currentCam = currentCamera {
                let captureDeviceInput = try AVCaptureDeviceInput(device: currentCam)
                captureSession.addInput(captureDeviceInput)
                photoOutput = AVCapturePhotoOutput()
                photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
                captureSession.addOutput(photoOutput!)
            }
        } catch {
            print(error)
        }
        
    }
    
    func setupPreviewLayer() {
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(cameraPreviewLayer!, at: 0)
    }
    
    func startRunningCaptureSession() {
        captureSession.startRunning()
    }
    
    @objc func cameraSwitchAction() {
        print("camera switch action...")
        if self.currentCamera == self.frontCamera {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
            
            for device in deviceDiscoverySession.devices {
                switch device.position {
                case AVCaptureDevice.Position.front:
                    self.frontCamera = device
                case AVCaptureDevice.Position.back:
                    self.backCamera = device
                default:
                    break
                }
            }
            
            self.currentCamera = self.backCamera
        } else {
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front)
            
            for device in deviceDiscoverySession.devices {
                switch device.position {
                case AVCaptureDevice.Position.front:
                    self.frontCamera = device
                case AVCaptureDevice.Position.back:
                    self.backCamera = device
                default:
                    break
                }
            }
            
            self.currentCamera = self.frontCamera
        }
    }
}
