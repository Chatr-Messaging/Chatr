//
//  PHAssetPicker.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/3/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit
import MobileCoreServices
import PhotosUI
import SwiftUI

struct PHAssetPickerSheet: UIViewControllerRepresentable {
    @Environment(\.presentationMode)
    var presentationMode
    @Binding var isPresented: Bool
    @Binding var hasAttachments: Bool
    @State var imagePicker: KeyboardCardViewModel
    let onMediaPicked: ([KeyboardMediaAsset]) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        @Binding var presentationMode: PresentationMode
        @Binding var isPresented: Bool
        @Binding var hasAttachments: Bool
        @Binding var imagePicker: KeyboardCardViewModel
        private let onMediaPicked: ([KeyboardMediaAsset]) -> Void

        init(presentationMode: Binding<PresentationMode>, isPresented: Binding<Bool>, hasAttachments: Binding<Bool>, imagePicker: Binding<KeyboardCardViewModel>, onMediaPicked: @escaping ([KeyboardMediaAsset]) -> Void) {
            _presentationMode = presentationMode
            _isPresented = isPresented
            _hasAttachments = hasAttachments
            _imagePicker = imagePicker
            self.onMediaPicked = onMediaPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let identifiers = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            var mediaz: [KeyboardMediaAsset] = []
            
            fetchResult.enumerateObjects { [self] (asset, index, _) in
                self.imagePicker.extractPreviewData(asset: asset, completion: {
                    if asset.mediaType == .video {
                        self.imagePicker.getImageFromAsset(asset: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) { (image) in
                            let newMedia = KeyboardMediaAsset(asset: asset, image: image)
                            DispatchQueue.main.async {
                                mediaz.append(newMedia)
                                self.hasAttachments = true
                            }
                            //FIX ME: Still need to upload video...
                            self.imagePicker.uploadSelectedVideo(media: newMedia)
                            print("trying to upload new video!")
                        }
                    } else if asset.mediaType == .image {
                        self.imagePicker.getImageFromAsset(asset: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) { (image) in
                            let newMedia = KeyboardMediaAsset(asset: asset, image: image)
                            self.imagePicker.uploadSelectedImage(media: newMedia)
                            self.imagePicker.selectedPhotos.append(newMedia)
                            mediaz.append(newMedia)
                            print("trying to upload new photo!")
                            self.hasAttachments = true
                        }
                    }
                })
            }
            
            //self.onMediaPicked(mediaz)
            self.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, isPresented: $isPresented, hasAttachments: $hasAttachments, imagePicker: $imagePicker, onMediaPicked: onMediaPicked)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<PHAssetPickerSheet>) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.selectionLimit = 3
        configuration.filter = .any(of: [.images, .videos])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController,
                                context: UIViewControllerRepresentableContext<PHAssetPickerSheet>) {  }
}
