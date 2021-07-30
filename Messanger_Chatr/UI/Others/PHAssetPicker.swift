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
    let onMediaPicked: ([PHPickerResult]) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        @Binding var presentationMode: PresentationMode
        @Binding var isPresented: Bool
        private let onMediaPicked: ([PHPickerResult]) -> Void

        init(presentationMode: Binding<PresentationMode>, isPresented: Binding<Bool>, onMediaPicked: @escaping ([PHPickerResult]) -> Void) {
            _presentationMode = presentationMode
            _isPresented = isPresented
            self.onMediaPicked = onMediaPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onMediaPicked(results)
            self.isPresented = false
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, isPresented: $isPresented, onMediaPicked: onMediaPicked)
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
