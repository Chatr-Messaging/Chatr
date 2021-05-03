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
    @State var style = StaggeredGridStyle(.horizontal, tracks: .count(2), spacing: 2.5)
    @State var testData: [String] = ["AppIcon-Original-Dark", "AppIcon-PaperAirplane-Dark", "oldHouseWallpaper", "nycWallpaper", "michaelAngelWallpaper", "banner"]

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text("PINNED:")
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.horizontal)
                    .offset(y: 2)
                Spacer()
            }

            ScrollView(style.axes) {
                Grid(self.testData, id: \.self) { index in
                    Image("\(index)")
                        .resizable()
                        .scaledToFit()
                }.cornerRadius(10)
                .padding()
                .frame(minHeight: 250, maxHeight: 265, alignment: .center)
                .animation(.easeInOut)
            }.shadow(color: Color.black.opacity(0.2), radius: 12.5, x: 0, y: 8)
            .gridStyle(self.style)
        }
    }
}
