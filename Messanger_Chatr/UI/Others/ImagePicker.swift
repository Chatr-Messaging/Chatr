//
//  ImagePicker.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/15/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import UIKit
import MobileCoreServices
import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode)
    var presentationMode
    var imageOnly: Bool = true

    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate {

        @Binding var presentationMode: PresentationMode
        @Binding var image: UIImage?

        init(presentationMode: Binding<PresentationMode>, image: Binding<UIImage?>) {
            _presentationMode = presentationMode
            _image = image
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let identifiers = results.compactMap(\.assetIdentifier)
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
            print("the fetchedresult is now: \(fetchResult.count)")
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString

            switch mediaType {
            case kUTTypeImage:
                image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                print("Selected media is image \(image)")

            case kUTTypeMovie:
                let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as! URL
                print("Selected media is video: \(videoUrl.absoluteString)")

            default:
                print("unknown/unusable type")
            }
            presentationMode.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, image: $image)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        //if !self.imageOnly {
            picker.sourceType = .photoLibrary
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) ?? []
        //}
        //picker.allowsEditing = imageOnly
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {  }
}
