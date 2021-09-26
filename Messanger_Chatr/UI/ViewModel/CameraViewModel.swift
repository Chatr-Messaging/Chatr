//
//  CameraViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/25/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import AVFoundation

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    @Published var isTaken = false
    @Published var flipCamera = false
    @Published var alert = false
    @Published var isSaved = false
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var preview : AVCaptureVideoPreviewLayer!
    @Published var picData: Data?
    var currentCaptureDevice: AVCaptureDevice?
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()

            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp() {
        do{
            self.session.beginConfiguration()
            currentCaptureDevice = (self.flipCamera ? getFrontCamera() : getBackCamera())

            guard let currentCapture = currentCaptureDevice else { return }

            let input = try AVCaptureDeviceInput(device: currentCapture)
                        
            if self.session.canAddInput(input){
                self.session.addInput(input)
            }
                        
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch { }
    }
    
    func shutDownCamera() {
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()
        }
    }
    
    func startCameraSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func getFrontCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices.first
    }

    func getBackCamera() -> AVCaptureDevice? {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first
    }
        
    func takePic() {
        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        
        DispatchQueue.global(qos: .background).async {
            self.session.stopRunning()

            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func reTake() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{
                    self.isTaken.toggle()
                }
                self.isSaved = false
                self.picData = nil
            }
        }
    }
    
    func flipCameraAction() {
        self.flipCamera.toggle()
        
        do{
            session.removeInput(session.inputs.first!)
            currentCaptureDevice = (self.flipCamera ? getFrontCamera() : getBackCamera())
            
            let captureDeviceInput1 = try AVCaptureDeviceInput(device: currentCaptureDevice!)
            session.addInput(captureDeviceInput1)
        } catch{  }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil{
            return
        }
                
        guard let imageData = photo.fileDataRepresentation() else { return }
        self.picData = imageData
    }
    
    func savePic(){
        guard let imgData = self.picData, let image = UIImage(data: imgData) else{return}
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        self.isSaved = true
    }
}
