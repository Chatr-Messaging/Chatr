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
import Cache

enum LibraryStatus {
    case denied
    case approved
    case limited
}

struct GIFMediaAsset: Hashable, Identifiable {
    var id = UUID().uuidString
    var url: String
    var mediaRatio: CGFloat
}

struct KeyboardMediaAsset: Hashable, Identifiable {
    var id = UUID().uuidString
    var asset: AVAsset?
    var image: UIImage
    var progress: CGFloat = 0.0
    var uploadId: String?
    var placeholderId: String?
    var mediaRatio: Double?
    var canSend: Bool = false
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

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 50, totalCostLimit: 100), transformer: TransformerFactory.forData())
    }()
    
    private lazy var uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
        
    func uploadSelectedImages() {
        DispatchQueue.global(qos: .utility).async {
            for media in self.selectedPhotos {
                guard media.uploadId == nil, media.progress == 0.0, let foundMediaIndex = self.selectedPhotos.firstIndex(of: media), let data = media.image.jpegData(compressionQuality: 1.0) else { return }
                
                //let uploadcare = Uploadcare(withPublicKey: Constants.uploadcarePublicKey, secretKey: Constants.uploadcareSecretKey)
                let filename = "\(media.id)" + Date().description.replacingOccurrences(of: " ", with: "")
                let semaphore = DispatchSemaphore(value: 0)
                
                self.uploadcare.uploadAPI.upload(files: [filename: data], store: .store, { (progress) in
                    DispatchQueue.main.async {
                        self.selectedPhotos[foundMediaIndex].progress = CGFloat(progress)
                    }
                }) { (resultDictionary, error) in
                    defer {
                        semaphore.signal()
                    }

                    guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.selectedPhotos[foundMediaIndex].uploadId = fileId
                    }
                }

                semaphore.wait()
            }
        }
    }
    
    func uploadSelectedImage(media: KeyboardMediaAsset, auth: AuthModel) {
        DispatchQueue.global(qos: .utility).async {
            guard media.uploadId == nil, media.progress == 0.0, let foundMediaIndex = self.selectedPhotos.firstIndex(of: media), let data = media.image.jpegData(compressionQuality: 1.0) else { return }
            
            let filename = "\(media.id)" + Date().description.replacingOccurrences(of: " ", with: "")
            let semaphore = DispatchSemaphore(value: 0)
            
            self.uploadcare.uploadAPI.upload(files: [filename: data], store: .doNotStore, { (progress) in
                DispatchQueue.main.async {
                    self.selectedPhotos[foundMediaIndex].progress = CGFloat(progress)
                }
            }) { (resultDictionary, error) in
                defer {
                    semaphore.signal()
                }

                DispatchQueue.main.async {
                    guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                        return
                    }
                
                    let imageRatio = media.image.size.height / media.image.size.width
                
                    self.selectedPhotos[foundMediaIndex].uploadId = fileId
                    self.selectedPhotos[foundMediaIndex].mediaRatio = Double(imageRatio)

                    if self.selectedPhotos[foundMediaIndex].canSend {
                        DispatchQueue.main.async {
                            self.sendPhotoMessage(attachment: self.selectedPhotos[foundMediaIndex], auth: auth, completion: {  })
                        }
                    }
                }
            }

            semaphore.wait()
        }
    }
    
    func uploadSelectedVideo(vid: KeyboardMediaAsset, auth: AuthModel) {
        DispatchQueue.global(qos: .utility).async {
            guard vid.uploadId == nil, vid.progress == 0.0, let foundMediaIndex = self.selectedVideos.firstIndex(of: vid), let assz = vid.asset as? AVURLAsset, let videoData = try? Data(contentsOf: assz.url, options: [.alwaysMapped , .uncached]) else { return }
            
            let filename = vid.id + assz.url.lastPathComponent
            
            Request.uploadFile(with: videoData, fileName: filename, contentType: "video/mov", isPublic: true, progressBlock: { (progress) in
                DispatchQueue.main.async {
                    self.selectedVideos[foundMediaIndex].progress = CGFloat(progress)
                }
            }, successBlock: { (blob) in
                DispatchQueue.main.async {
                    guard let blobUid = blob.uid else { return }
                    
                    self.storage?.async.setObject(videoData, forKey: Constants.uploadcareBaseVideoUrl + blobUid, completion: { test in
                        
                        self.selectedVideos[foundMediaIndex].uploadId = blobUid
                        if self.selectedVideos[foundMediaIndex].canSend {
                            DispatchQueue.main.async {
                                self.sendVideoMessage(auth: auth)
                            }
                        }
                    })
                }
            })
            
            /*
            let semaphore = DispatchSemaphore(value: 0)
            
            DispatchQueue.main.async {
                self.uploadcare.uploadAPI.upload(files: [filename: videoData], store: .doNotStore, { (progress) in
                    DispatchQueue.main.async {
                        self.selectedVideos[foundMediaIndex].progress = CGFloat(progress)
                        print("the progress uploading the video is: \(progress * 100)%")
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
                    print("success uploading direct video. Here is the data: " + "\(fileId)")
                    
     
                }
            }
            
            semaphore.wait()
            
            */
        }
    }
    
    func uploadVideoImage(media: KeyboardMediaAsset, auth: AuthModel) {
        DispatchQueue.global(qos: .utility).async {
            guard let foundMediaIndex = self.selectedVideos.firstIndex(of: media), let data = media.image.jpegData(compressionQuality: 1.0) else { return }
            
            let filename = "\(media.id)_videoImage_" + Date().description.replacingOccurrences(of: " ", with: "")
            let semaphore = DispatchSemaphore(value: 0)
            
            self.uploadcare.uploadAPI.upload(files: [filename: data], store: .doNotStore, { _ in
//                DispatchQueue.main.async {
//                    print("the upload video image progress is: \(progress)")
//                }
            }) { (resultDictionary, error) in
                defer {
                    semaphore.signal()
                }
                
                guard let uploadData = resultDictionary, let fileId = uploadData.first?.value else {
                    return
                }
                
                let imageRatio = media.image.size.height / media.image.size.width
                
                DispatchQueue.main.async {
                    self.selectedVideos[foundMediaIndex].placeholderId = fileId
                    self.selectedVideos[foundMediaIndex].mediaRatio = Double(imageRatio)

                    if self.selectedVideos[foundMediaIndex].canSend {
                        DispatchQueue.main.async {
                            self.sendVideoMessage(auth: auth)
                        }
                    }
                }
            }

            semaphore.wait()
        }
    }
    
    func sendPhotoMessage(attachment: KeyboardMediaAsset, auth: AuthModel, completion: @escaping () -> Void) {
        guard let selectedDialog = auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first else { return }
        
        guard let uploadedId = attachment.uploadId, let ratio = attachment.mediaRatio else {
            if let index = self.selectedPhotos.firstIndex(of: attachment) {
                self.selectedPhotos[index].canSend = true
            }
            completion()
            
            return
        }
        
        let attachmentz = ChatAttachment()
        attachmentz["imageURL"] = Constants.uploadcareBaseUrl + uploadedId + Constants.uploadcareStandardTransform
        attachmentz["mediaRatio"] = "\(ratio)"
        attachmentz.type = "image/png"
        
        let occupants = auth.selectedConnectyDialog?.occupantIDs ?? []
        let pDialog = ChatDialog(dialogID: selectedDialog.id, type: selectedDialog.dialogType == "public" ? .public : occupants.count > 2 ? .group : .private)
        pDialog.occupantIDs = occupants
        
        let message = ChatMessage()
        message.text = "Image attachment"
        message.attachments = [attachmentz]
        
        pDialog.send(message) { (error) in
            changeMessageRealmData.shared.insertMessage(message, completion: {
                if error != nil {
                    changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    completion()
                } else {
                    changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                    if let index = self.selectedPhotos.firstIndex(of: attachment), let storeId = self.selectedPhotos[index].uploadId {
                        self.selectedPhotos.remove(at: index)
                        self.storeUploadMedia(id: storeId)
                    }
                    completion()
                }
            })
        }
    }
    
    func sendVideoMessage(auth: AuthModel) {
        guard let selectedDialog = auth.dialogs.results.filter("id == %@", UserDefaults.standard.string(forKey: "selectedDialogID") ?? "").first else { return }

        for attachment in self.selectedVideos {
            guard let uploadedId = attachment.uploadId, let placeholderId = attachment.placeholderId, let ratio = attachment.mediaRatio else {
                if let index = self.selectedVideos.firstIndex(of: attachment) {
                    self.selectedVideos[index].canSend = true
                }

                continue
            }
            
            let attachmentz = ChatAttachment()
            attachmentz["videoURL"] = uploadedId
            attachmentz["placeholderURL"] = placeholderId
            attachmentz["mediaRatio"] = "\(ratio)"
            attachmentz.type = "video/mov"
            
            let occupants = auth.selectedConnectyDialog?.occupantIDs ?? []
            let pDialog = ChatDialog(dialogID: selectedDialog.id, type: selectedDialog.dialogType == "public" ? .public : occupants.count > 2 ? .group : .private)
            pDialog.occupantIDs = occupants
            
            let message = ChatMessage()
            message.markable = true
            message.text = "Video attachment"
            message.attachments = [attachmentz]
            
            pDialog.send(message) { (error) in
                changeMessageRealmData.shared.insertMessage(message, completion: {
                    if error != nil {
                        changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .error)
                    } else {
                        self.storeUploadMedia(id: placeholderId)
                        if let index = self.selectedVideos.firstIndex(of: attachment) {
                            self.selectedVideos.remove(at: index)
                        }
                        changeMessageRealmData.shared.updateMessageState(messageID: message.id ?? "", messageState: .delivered)
                    }
                })
            }
        }
    }

    func storeUploadMedia(id: String) {
        uploadcare.storeFile(withUUID: id) { (_, _) in }
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
        //print("photo library did change! \(changeInstance)")
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
    func extractPreviewData(asset: PHAsset, auth: AuthModel, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let manager = PHCachingImageManager()
            self.getImageFromAsset(asset: asset, size: PHImageManagerMaximumSize) { (image) in
                if asset.mediaType == .image {
                    guard let imgRemove = self.imageData.firstIndex(of: image) else {
                        DispatchQueue.main.async {
                            let newMedia = KeyboardMediaAsset(image: image)
                            self.selectedPhotos.append(newMedia)
                            self.imageData.append(image)
                            self.uploadSelectedImage(media: newMedia, auth: auth)

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
                                self.uploadVideoImage(media: newMedia, auth: auth)
                                self.uploadSelectedVideo(vid: newMedia, auth: auth)

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
                    self.locationPermission = false
                case .authorizedAlways, .authorizedWhenInUse:
                    self.locationPermission = true
                @unknown default:
                break
            }
        } else {
            self.locationPermission = false
        }
    }

    func requestLocationPermission() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationPermission = true
    }
}

