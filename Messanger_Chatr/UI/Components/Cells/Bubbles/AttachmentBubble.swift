//
//  AttachmentBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/21/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import ConnectyCube
import RealmSwift

struct AttachmentBubble: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var viewModel: ChatMessageViewModel
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State var subText: String = ""
    var hasPrior: Bool = false
    @State var avatar: String = ""
    
    var body: some View {
        ZStack {
            if self.message.imageType == "image/gif" && self.message.messageState != .deleted {
                AnimatedImage(url: URL(string: self.message.image))
                    .resizable()
                    .placeholder {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading GIF...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    //.frame(minHeight: 100, maxHeight: CGFloat(self.message.imgHeight))
                    //.frame(minWidth: 100, maxWidth: CGFloat(Constants.screenWidth * 0.7))
                    .frame(height: CGFloat(Constants.screenWidth * 0.6))
                    .frame(minWidth: 100)
                    .padding(.leading, self.messagePosition == .right ? 35 : 0)
                    .padding(.trailing, self.messagePosition == .right ? 0 : 35)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
            } else if self.message.imageType == "image/png" && self.message.messageState != .deleted {
                WebImage(url: URL(string: self.message.image))
                    .resizable()
                    .placeholder {
                        VStack {
                            Image(systemName: "photo.on.rectangle.angled")
                                .padding(.bottom, 5)
                            Text("loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }.transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                    .aspectRatio(contentMode: .fit)
                    .clipShape(CustomGIFShape())
                    .frame(height: CGFloat(Constants.screenWidth * 0.6))
                    .frame(minWidth: 100)
                    .padding(.leading, self.messagePosition == .right ? 35 : 0)
                    .padding(.trailing, self.messagePosition == .right ? 0 : 35)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 14)
                    .offset(x: self.hasPrior ? (self.messagePosition == .right ? -5 : 5) : 0)
            } else if self.message.messageState == .deleted {
                ZStack {
                    Text("deleted")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(self.message.messageState != .deleted ? messagePosition == .right ? .white : .primary : .secondary)
                        .padding(.vertical, 8)
                        .lineLimit(nil)
                }.padding(.horizontal, 15)
                .background(self.messagePosition == .right && self.message.messageState != .deleted ? LinearGradient(
                    gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                    startPoint: .top, endPoint: .bottom) : LinearGradient(
                        gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                .shadow(color: self.messagePosition == .right && self.message.messageState != .deleted ? Color.blue.opacity(0.2) : Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                
            }
        }
    }
}
