//
//  KeyboardCardViewModel.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 2/9/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import Foundation
import SwiftUI
import Photos
import AVKit
import CoreLocation
import Uploadcare
import ConnectyCube
import MapKit

enum LibraryStatus {
    case denied
    case approved
    case limited
}

struct KeyboardMediaAsset: Hashable, Equatable, Identifiable {
    var id = UUID().uuidString
    var asset: AVAsset?
    var image: UIImage
    var progress: CGFloat = 0.0
    var uploadId: String?
    var preparedMessageId: String?
    var selected: Bool = false
}

class KeyboardCardViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    var locationManager: CLLocationManager = CLLocationManager()
    @Published var locationPermission: Bool = false
    @Published var library_status = LibraryStatus.denied
    @Published var allPhotos : PHFetchResult<PHAsset>!
    @Published var selectedImagePreview: UIImage!
    @Published var selectedVideoPreview: AVAsset!
    @Published var fetchedPhotos : [KeyboardMediaAsset] = []
    @Published var selectedPhotos : [KeyboardMediaAsset] = []
    @Published var selectedVideos : [KeyboardMediaAsset] = []
    @Published var imageData: [UIImage] = []
    @Published var videoData: [AVAsset] = []
    @Published var pastedImages: [UIImage] = []
    var auth: AuthModel = AuthModel()
        
    func uploadSelectedImages() {
        DispatchQueue.global(qos: .utility).async {
            for media in self.selectedPhotos {
                guard media.uploadId == nil, media.progress == 0.0, let foundMediaIndex = self.selectedPhotos.firstIndex(of: media), let data = media.image.jpegData(compressionQuality: 1.0) else { return }
                
                let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
                let filename = "\(media.id)" + Date().description.replacingOccurrences(of: " ", with: "")
                let semaphore = DispatchSemaphore(value: 0)
                
                uploadcare.uploadAPI.upload(files: [filename: data], store: .store, { (progress) in
                    DispatchQueue.main.async {
                        self.selectedPhotos[foundMediaIndex].progress = progress
                    }
                }) { (resultDictionary, error) in
                    defer {
                        semaphore.signal()
                    }
                    
                    if let error = error {
                        print("the error uploading direct files: " + error.debugDescription)
                    }

                    guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.selectedPhotos[foundMediaIndex].uploadId = fileId
                        print("success uploading direct file. Here is the data: " + "\(fileId)")
                    }
                }

                semaphore.wait()
            }
        }
    }
    
    func uploadSelectedImage(media: KeyboardMediaAsset) {
        DispatchQueue.global(qos: .utility).async {
            guard media.uploadId == nil, media.progress == 0.0, let foundMediaIndex = self.selectedPhotos.firstIndex(of: media), let data = media.image.jpegData(compressionQuality: 1.0) else { return }
            
            let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
            let filename = "\(media.id)" + Date().description.replacingOccurrences(of: " ", with: "")
            let semaphore = DispatchSemaphore(value: 0)
            
            uploadcare.uploadAPI.upload(files: [filename: data], store: .store, { (progress) in
                if let realmId = self.selectedPhotos[foundMediaIndex].preparedMessageId {
                    changeMessageRealmData.shared.updateMessageMediaProgress(messageID: realmId, progress: progress)
                } else {
                    DispatchQueue.main.async {
                        print("the upload progress is: \(progress)")
                        self.selectedPhotos[foundMediaIndex].progress = progress
                    }
                }
            }) { (resultDictionary, error) in
                defer {
                    semaphore.signal()
                }
                
                if let error = error {
                    print("the error uploading direct files: " + error.debugDescription)
                }

                guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.selectedPhotos[foundMediaIndex].uploadId = fileId
                    print("success uploading direct file. Here is the data: " + "\(fileId)")
                }
            }

            semaphore.wait()
        }
    }
    
    //func uploadSelectedVideo(media: KeyboardMediaAsset) {
        /*
        DispatchQueue.global(qos: .utility).async {
            guard media.uploadId == nil, media.progress == 0.0, let foundMediaIndex = self.selectedVideos.firstIndex(of: media), let data = NSData(contentsOfURL: media.asset) else { return }
            
            let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
            let filename = "\(media.id)" + Date().description.replacingOccurrences(of: " ", with: "")
            let semaphore = DispatchSemaphore(value: 0)
            
            uploadcare.uploadAPI.upload(files: [filename: data], store: .store, { (progress) in
                DispatchQueue.main.async {
                    self.selectedVideos[foundMediaIndex].progress = progress
                }
            }) { (resultDictionary, error) in
                defer {
                    semaphore.signal()
                }
                
                if let error = error {
                    print("the error uploading direct files: " + error.debugDescription)
                }

                guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.selectedVideos[foundMediaIndex].uploadId = fileId
                    print("success uploading direct file video. Here is the data: " + "\(fileId)")
                }
            }

            semaphore.wait()
        }
        */
    //}
    
    func uploadSelectedVideo(vid: KeyboardMediaAsset) {
        DispatchQueue.global(qos: .utility).async {
            guard vid.uploadId == nil, vid.progress == 0.0, let foundMediaIndex = self.selectedVideos.firstIndex(of: vid), let assz = vid.asset as? AVURLAsset, let videoData = try? Data(contentsOf: assz.url) else { return }
            
            let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
            let filename = "\(vid.id)" + Date().description.replacingOccurrences(of: " ", with: "")
            let semaphore = DispatchSemaphore(value: 0)
            
            uploadcare.uploadAPI.upload(files: [filename: videoData], store: .store, { (progress) in
                DispatchQueue.main.async {
                    print("the progress uploading the video is: \(progress * 100)%")
                    self.selectedVideos[foundMediaIndex].progress = progress
                }
            }) { (resultDictionary, error) in
                defer {
                    semaphore.signal()
                }
                
                if let error = error {
                    print("the error uploading direct files: " + error.debugDescription)
                }

                guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.selectedVideos[foundMediaIndex].uploadId = fileId
                    print("success uploading direct video. Here is the data: " + "\(fileId)")
                }
            }
            
            semaphore.wait()
        }
    }
    
    func sendPhotoMessage(dialog: DialogStruct, attachmentImages: [KeyboardMediaAsset], occupentID: [NSNumber]) {
        for attachment in attachmentImages {
            
            guard let uploadedId = attachment.uploadId else {
                let chatAttachment = ChatAttachment()
                chatAttachment["uploadId"] = attachment.id
                
                let message = ChatMessage()
                message.text = "Uploading image attachment..."
                message.attachments = [chatAttachment]
                message.dialogID = dialog.id
                message.senderID = UInt(UserDefaults.standard.integer(forKey: "currentUserID"))
                
                changeMessageRealmData.shared.insertMessage(message, completion: {
                    print("successfully added local message while its uploading!!")
                    guard let idz = message.id, let localMedia = self.selectedPhotos.firstIndex(of: attachment) else { return }
                    
                    self.selectedPhotos[localMedia].preparedMessageId = idz.description
                })
                
                return
            }
            
            let attachment = ChatAttachment()
            attachment["imageURL"] = Constants.uploadcareBaseUrl + uploadedId + Constants.uploadcareStandardTransform
            attachment.type = "image/png"
            
            let pDialog = ChatDialog(dialogID: dialog.id, type: dialog.dialogType == "public" ? .public : occupentID.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupentID
            
            let message = ChatMessage()
            message.text = "Image Attachment"
            message.attachments = [attachment]
            
            pDialog.send(message) { (error) in
                print("SENT image...")
                changeMessageRealmData.shared.insertMessage(message, completion: {
                    if error != nil {
                        print("error sending attachment: \(String(describing: error?.localizedDescription))")
                        changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        print("Success sending attachment to ConnectyCube server!")
                    }
                })
            }
        }
    }
    
    func openImagePicker(completion: @escaping () -> Void) {
        if fetchedPhotos.isEmpty {
            //fetchPhotos(completion: {
                completion()
            //})
        } else {
            completion()
        }
    }
    
//    func fetchPhotos(completion: @escaping () -> Void) {
//        let options = PHFetchOptions()
//        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//        options.includeHiddenAssets = false
//
//        let fetchResults = PHAsset.fetchAssets(with: options)
//        allPhotos = fetchResults
//
//        fetchResults.enumerateObjects { [self] (asset, index, _) in
//            getImageFromAsset(asset: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) { (image) in
//                DispatchQueue.main.async {
//                    fetchedPhotos.append(KeyboardMediaAsset(asset: asset, image: image, imagePicker: self.chatV))
//                }
//            }
//
//            completion()
//        }
//    }

    func setUpAuthStatus() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [self] (status) in
            DispatchQueue.main.async {
                switch status{
                case .denied: library_status = .denied
                case .authorized: library_status = .approved
                case .limited: library_status = .limited
                default : library_status = .denied
                }
            }
        }

        // Registering Observer...
        PHPhotoLibrary.shared().register(self)
    }
        
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photo library did change! \(changeInstance)")
    }
//    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        guard let _ = allPhotos else { return }
//
//        if let updates = changeInstance.changeDetails(for: allPhotos) {
//            let updatedPhotos = updates.fetchResultAfterChanges
//
//            // There is bug in it...
//            // It is not updating the inserted or removed items....
//
////            print(updates.insertedObjects.count)
////            print(updates.removedObjects.count)
//
//            // So were Going to verify All And Append Only No in the list...
//            // To Avoid Of reloading all and ram usage...
//
//            updatedPhotos.enumerateObjects { [self] (asset, index, _) in
//                if !allPhotos.contains(asset) {
//                    getImageFromAsset(asset: asset, size: CGSize(width: 150, height: 150)) { (image) in
//                        DispatchQueue.main.async {
//                            fetchedPhotos.append(KeyboardMediaAsset(asset: asset, image: image))
//                        }
//                    }
//                }
//            }
//
//            // To Remove If Image is removed...
//            allPhotos.enumerateObjects { (asset, index, _) in
//                if !updatedPhotos.contains(asset) {
//                    DispatchQueue.main.async {
//                        self.fetchedPhotos.removeAll { (result) -> Bool in
//                            return result.asset == asset
//                        }
//                    }
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.allPhotos = updatedPhotos
//            }
//        }
//    }
    
    func getImageFromAsset(asset: PHAsset, size: CGSize, completion: @escaping (UIImage)->()) {
        DispatchQueue.global(qos: .utility).async {
            let imageManager = PHCachingImageManager()
            imageManager.allowsCachingHighQualityImages = true
            
            // Your Own Properties For Images...
            let imageOptions = PHImageRequestOptions()
            imageOptions.deliveryMode = .highQualityFormat
            imageOptions.isSynchronous = false
            
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: imageOptions) { (image, _) in
                guard let resizedImage = image else{return}
                
                completion(resizedImage)
            }
        }
    }
    
    // Opening Image Or Video....
    func extractPreviewData(asset: PHAsset, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let manager = PHCachingImageManager()
            self.getImageFromAsset(asset: asset, size: PHImageManagerMaximumSize) { (image) in
                if asset.mediaType == .image {
                    guard let imgRemove = self.imageData.firstIndex(of: image) else {
                        DispatchQueue.main.async {
                            let newMedia = KeyboardMediaAsset(image: image)
                            self.selectedPhotos.append(newMedia)
                            self.imageData.append(image)
                            self.uploadSelectedImage(media: newMedia)

                            completion()
                        }

                        return
                    }

                    DispatchQueue.main.async {
                        self.videoData.remove(at: imgRemove)
                        completion()
                    }
                } else if asset.mediaType == .video {
                    let videoManager = PHVideoRequestOptions()
                    videoManager.deliveryMode = .highQualityFormat
                    videoManager.isNetworkAccessAllowed = true

                    manager.requestAVAsset(forVideo: asset, options: videoManager) { (videoAsset, _, _) in
                        guard let videoUrl = videoAsset else { return }
                        
                        guard let vidRemove = self.videoData.firstIndex(of: videoUrl) else {
                            DispatchQueue.main.async {
                                let newMedia = KeyboardMediaAsset(asset: videoUrl, image: image)
                                self.selectedVideos.append(newMedia)
                                self.videoData.append(videoUrl)
                                self.uploadSelectedVideo(vid: newMedia)

                                completion()
                            }
                            
                            return
                        }

                        self.videoData.remove(at: vidRemove)
                        DispatchQueue.main.async {
                            completion()
                        }
                    }
                }
            }
        }
    }

    func checkLocationPermission() {
        let manager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
                case .notDetermined, .restricted, .denied:
                    print("No access to location")
                    self.locationPermission = false
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Access location true")
                    self.locationPermission = true
                @unknown default:
                break
            }
        } else {
            print("Location services are not enabled")
            self.locationPermission = false
        }
    }

    func requestLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationPermission = true
    }
}

