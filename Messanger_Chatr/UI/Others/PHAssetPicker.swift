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

    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        @Binding var presentationMode: PresentationMode
        @Binding var isPresented: Bool
        @Binding var hasAttachments: Bool
        @Binding var imagePicker: KeyboardCardViewModel

        init(presentationMode: Binding<PresentationMode>, isPresented: Binding<Bool>, hasAttachments: Binding<Bool>, imagePicker: Binding<KeyboardCardViewModel>) {
            _presentationMode = presentationMode
            _isPresented = isPresented
            _hasAttachments = hasAttachments
            _imagePicker = imagePicker
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let identifiers = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)

            fetchResult.enumerateObjects { [self] (asset, index, _) in
                self.imagePicker.extractPreviewData(asset: asset, completion: {
                    if asset.mediaType == .video {
                        self.imagePicker.getImageFromAsset(asset: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) { (image) in
                            let newMedia = KeyboardMediaAsset(asset: asset, image: image)
                            self.imagePicker.selectedVideos.append(newMedia)
                            self.imagePicker.uploadSelectedVideo(media: newMedia)
                            self.hasAttachments = true
                        }
                    } else if asset.mediaType == .image {
                        self.imagePicker.getImageFromAsset(asset: asset, size: CGSize(width: asset.pixelWidth, height: asset.pixelHeight)) { (image) in
                            let newMedia = KeyboardMediaAsset(asset: asset, image: image)
                            self.imagePicker.selectedPhotos.append(newMedia)
                            self.imagePicker.uploadSelectedImage(media: newMedia)
                            self.hasAttachments = true
                        }
                    }
                })
            }

            isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, isPresented: $isPresented, hasAttachments: $hasAttachments, imagePicker: $imagePicker)
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
