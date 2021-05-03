//
//  PinnedSectionView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/2/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import Grid

struct PinnedSectionView: View {
    @Binding var dialog: DialogStruct
    @State var style = StaggeredGridStyle(.horizontal, tracks: .fixed(125), spacing: 2.5)
    @State var testData: [String] = ["AppIcon-Original-Dark", "banner", "AppIcon-PaperAirplane-Dark", "oldHouseWallpaper", "nycWallpaper", "michaelAngelWallpaper"]
    @Namespace var namespace

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PINNED:")
                .font(.caption)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.horizontal)
                .padding(.bottom, 2.5)

            ScrollView(style.axes) {
                Grid(self.dialog.pinMessages, id: \.self) { pinId in
                    if let messagez = self.dialog.messages.first(where: { $0.id == pinId }) {
                        if messagez.image != "" {
                            //Attachment
                        } else if messagez.contactID != 0 {
                            //Contact
                        } else if messagez.longitude != 0 && messagez.latitude != 0 {
                            //Location
                        } else {
                            TextBubble(message: messagez, messagePosition: .right, namespace: self.namespace)
                                .frame(maxHeight: 125)
                                .padding(.horizontal)
                                .background(Color("bgColor_light"))
                        }
                    }
                }.cornerRadius(15)
                .frame(minHeight: 250, alignment: .center)
                .padding(.leading)
                .animation(.easeInOut)
            }.shadow(color: Color.black.opacity(0.2), radius: 12.5, x: 0, y: 8)
            .padding(.bottom, 10)
            .padding(.trailing)
            .gridStyle(self.style)
        }
        .padding(.bottom)
    }
}
