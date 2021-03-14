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

enum LibraryStatus {
    case denied
    case approved
    case limited
}

struct KeyboardMediaAsset: Identifiable, Hashable {
    var id = UUID().uuidString
    var asset: PHAsset
    var image: UIImage
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
    
    func openImagePicker(completion: @escaping () -> Void) {
        if fetchedPhotos.isEmpty {
            fetchPhotos(completion: {
              //  DispatchQueue.main.async {
                    completion()
              //  }
            })
        } else {
            //DispatchQueue.main.async {
                completion()
            //}
        }
    }
    
    func fetchPhotos(completion: @escaping () -> Void) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeHiddenAssets = false
        
        let fetchResults = PHAsset.fetchAssets(with: options)
        allPhotos = fetchResults
        
        fetchResults.enumerateObjects { [self] (asset, index, _) in
            getImageFromAsset(asset: asset, size: CGSize(width: 200, height: 200)) { (image) in
                fetchedPhotos.append(KeyboardMediaAsset(asset: asset, image: image))
            }
            
            completion()
        }
    }

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
        guard let _ = allPhotos else { return }
        
        if let updates = changeInstance.changeDetails(for: allPhotos) {
            let updatedPhotos = updates.fetchResultAfterChanges
            
            // There is bug in it...
            // It is not updating the inserted or removed items....
            
//            print(updates.insertedObjects.count)
//            print(updates.removedObjects.count)
            
            // So were Going to verify All And Append Only No in the list...
            // To Avoid Of reloading all and ram usage...
            
            updatedPhotos.enumerateObjects { [self] (asset, index, _) in
                if !allPhotos.contains(asset) {
                    getImageFromAsset(asset: asset, size: CGSize(width: 150, height: 150)) { (image) in
                        DispatchQueue.main.async {
                            fetchedPhotos.append(KeyboardMediaAsset(asset: asset, image: image))
                        }
                    }
                }
            }
            
            // To Remove If Image is removed...
            allPhotos.enumerateObjects { (asset, index, _) in
                if !updatedPhotos.contains(asset) {
                    DispatchQueue.main.async {
                        self.fetchedPhotos.removeAll { (result) -> Bool in
                            return result.asset == asset
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.allPhotos = updatedPhotos
            }
        }
    }
    
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
        let manager = PHCachingImageManager()
        if asset.mediaType == .image {
            getImageFromAsset(asset: asset, size: PHImageManagerMaximumSize) { (image) in
                DispatchQueue.main.async {
                    guard let imgRemove = self.imageData.firstIndex(of: image) else {
                        DispatchQueue.main.async {
                            self.imageData.append(image)
                            completion()
                        }

                        return
                    }

                    DispatchQueue.main.async {
                        self.videoData.remove(at: imgRemove)
                        completion()
                    }
                }
            }
        }

        if asset.mediaType == .video {
            let videoManager = PHVideoRequestOptions()
            videoManager.deliveryMode = .highQualityFormat

            manager.requestAVAsset(forVideo: asset, options: videoManager) { (videoAsset, _, _) in
                guard let videoUrl = videoAsset else{return}
                
                DispatchQueue.main.async {
                    guard let vidRemove = self.videoData.firstIndex(of: videoUrl) else {
                        self.videoData.append(videoUrl)
                        DispatchQueue.main.async {
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

