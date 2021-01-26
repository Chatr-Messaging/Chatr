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
    var photoOutput = AVCapturePhotoOutput()
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //DELEGATE
    var delegate: AVCapturePhotoCaptureDelegate?
    
    func didTapRecord() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate!)
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
        checkDevicePermission()
    
        let tapFlip = UITapGestureRecognizer(target: self, action: #selector(cameraSwitchAction))
        tapFlip.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapFlip)
    }
    
    func checkDevicePermission(){
        
        // first checking camerahas got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupDevice()
            return
            // Setting Up Session
        case .notDetermined:
            // retusting for permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status{
                    self.setupDevice()
                }
            }
        case .denied:
            print("error denied camera")
            return
            
        default:
            return
        }
    }
    
    func setup() {
        setupCaptureSession()
        setupDevice()
        //setupInputOutput()
        setupPreviewLayer()
        startRunningCaptureSession()
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        do{
            self.captureSession.beginConfiguration()
            
            currentCamera = getFrontCamera()

            let input = try AVCaptureDeviceInput(device: currentCamera!)

            if self.captureSession.canAddInput(input){
                self.captureSession.addInput(input)
            }
                        
            if self.captureSession.canAddOutput(self.photoOutput){
                self.captureSession.addOutput(self.photoOutput)
            }
            
            self.captureSession.commitConfiguration()
            
            setupPreviewLayer()
        }
        catch{
            print(error.localizedDescription)
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
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    @objc func cameraSwitchAction() {
        do{
            captureSession.removeInput(captureSession.inputs.first!)

            currentCamera = (self.currentCamera?.position == .back ? getFrontCamera() : getBackCamera())
            
            let captureDeviceInput1 = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.addInput(captureDeviceInput1)
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func getFrontCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }

    func getBackCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
}
