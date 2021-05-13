//
//  TextBubble.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import MobileCoreServices
import SDWebImageSwiftUI
import ConnectyCube
import Firebase
import RealmSwift
import WKView

struct TextBubble: View {
    @State var message: MessageStruct
    @State var messagePosition: messagePosition
    @State private var typingOpacity: CGFloat = 1.0
    var namespace: Namespace.ID
    var isPinned: Bool = false

    var body: some View {
        ZStack {
            if self.message.messageState != .isTyping {
                if self.message.text.containsEmoji && self.message.text.count <= 4 {
                    Text(self.message.text)
                        .font(.system(size: self.isPinned ? 32 : 66))
                        .offset(x: self.messagePosition == .right ? -10 : 10, y: -5)
                        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 5)
                        .matchedGeometryEffect(id: self.message.id.description + "text", in: namespace)
                } else {
                    LinkedText(self.message.text, messageRight: self.messagePosition == .right, messageState: self.message.messageState)
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(self.message.messageState == .error ? Color.red.opacity(0.8) : Color.clear, lineWidth: 1.5))
                        .matchedGeometryEffect(id: self.message.id.description + "text", in: namespace)
                }
            } else if self.message.messageState == .isTyping {
                ZStack {
                    Capsule()
                        .frame(width: 65, height: 45, alignment: .center)
                        .foregroundColor(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 6)

                    HStack(spacing: 6) {
                        ForEach(0..<3) { type in
                            Circle()
                                .frame(width: 10, height: 10, alignment: .center)
                                .foregroundColor(.secondary)
                                .opacity(Double(self.typingOpacity))
                                .animation(Animation.easeInOut(duration: 0.66).repeatForever(autoreverses: true).delay(Double(type + 1) * 0.22))
                                .onAppear() {
                                    DispatchQueue.main.async {
                                        withAnimation(Animation.easeInOut(duration: 0.66).repeatForever(autoreverses: true)) {
                                            self.typingOpacity = 0.20
                                        }
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}
