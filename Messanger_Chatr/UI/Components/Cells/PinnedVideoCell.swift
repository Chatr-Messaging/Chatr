//
//  PinnedVideoCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/10/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import AVKit
import SwiftUI
import Cache
import ConnectyCube

struct PinnedVideoCell: View {
    @State var videoUrl: String = ""
    @State var videoImage: UIImage = UIImage()
    @State var videoDownloadProgress: CGFloat = 0.0
    @State var videoDuration: Double = 0.0

    var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage(diskConfig: DiskConfig(name: "DiskCache"), memoryConfig: MemoryConfig(expiry: .date(Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date()), countLimit: 10, totalCostLimit: 50), transformer: TransformerFactory.forData())
    }()

    var body: some View {
        ZStack {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: self.videoImage)
                    .resizable()
                    .scaledToFit()

                Image(systemName: "video.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(5)
                    .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(5))
                    .padding(5)
            }

            ZStack {
                Circle()
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .opacity(0.35)

                Circle()
                    .trim(from: 1.0 - self.videoDownloadProgress, to: 1.0)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                    .rotationEffect(.init(degrees: -90))
                    .animation(Animation.linear(duration: 0.1))
            }.opacity(self.videoDownloadProgress == 0.0 || self.videoDownloadProgress == 1.0 ? 0 : 1)
            .padding(30)
        }.onAppear() {
            self.loadVideo(fileId: self.videoUrl, completion: {  })
        }
    }
    
    func loadVideo(fileId: String, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            do {
                let result = try storage?.entry(forKey: fileId)
                let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mp4", fileExtension: "mp4")

                AVPlayer(playerItem: playerItem).currentItem?.asset.generateThumbnail { image in
                    DispatchQueue.main.async {
                        guard let image = image else { return }
                        self.videoImage = image
                    }
                }

                completion()
            } catch {
                Request.downloadFile(withUID: fileId, progressBlock: { (progress) in
                    self.videoDownloadProgress = CGFloat(progress)
                }, successBlock: { data in
                    self.storage?.async.setObject(data, forKey: fileId, completion: { result in
                        self.pullVideoImage(fileId: fileId)
                    })

                    completion()
                }, errorBlock: { _ in
                    completion()
                })
            }
        }
    }
    
    func pullVideoImage(fileId: String) {
        do {
            let result = try storage?.entry(forKey: fileId)
            let playerItem = CachingPlayerItem(data: result?.object ?? Data(), mimeType: "video/mp4", fileExtension: "mp4")

//            if let duration = AVPlayer(playerItem: playerItem).currentItem?.asset.duration.seconds {
//                DispatchQueue.main.async {
//                    self.videoDuration = duration
//                }
//            }
            AVPlayer(playerItem: playerItem).currentItem?.asset.generateThumbnail { image in
                DispatchQueue.main.async {
                    guard let image = image else { return }
                    self.videoImage = image
                }
            }
        } catch {  }
    }
    
    func formatVideoDuration(second: Int) -> String {
        let (_, m, s) = secondsToHoursMinutesSeconds(seconds: second)

        return "\(m)" + ":" + "\(s)"
    }
    
    func secondsToHoursMinutesSeconds(seconds : Int) -> (Int, Int, Int) {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}
