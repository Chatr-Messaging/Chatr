//
//  RemoteImageView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/28/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

final class ImageLoader: ObservableObject {
    
    @Published var image: Image? = nil
    
    func load(fromURL url: String) {
        ImageNetworkManager.shared.downloadImage(from: url) { uiImage in
            guard let uiImage = uiImage else { return }
            DispatchQueue.main.async {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}


struct RemoteImage: View {
    
    var image: Image?
    
    var body: some View {
        image?.resizable() ?? Image(systemName: "person.fill").resizable()
    }
}


struct RemoteImageView: View {
    @StateObject private var imageLoader = ImageLoader()
    var url: String
    
    var body: some View {
        RemoteImage(image: imageLoader.image)
            .onAppear { imageLoader.load(fromURL: url) }
    }
}
