//
//  stickyHeaderSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 5/19/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct stickyHeaderSection: View {
    @Binding var dialogModel: DialogStruct
    @State var offset: CGFloat = 0
    let headerHeight = CGFloat(220)
    let scrollBackHeight = CGFloat(110)

    var body: some View {
        //MARK: Sticky Header
        VStack {
            GeometryReader { proxy -> AnyView in
                // Sticky Header...
                let minY = proxy.frame(in: .global).minY
                
                DispatchQueue.main.async {
                    self.offset = minY
                }
                
                return AnyView(
                    ZStack {
                        WebImage(url: URL(string: self.dialogModel.coverPhoto))
                            .resizable()
                            .placeholder{ Image(systemName: "photo.on.rectangle.angled").resizable().frame(width: 35, height: 32, alignment: .center).scaledToFill().offset(y: -20) }
                            .indicator(.activity)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: Constants.screenWidth, height: minY > 0 ? headerHeight + minY : headerHeight, alignment: .center)
                            .clipped()
                            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                            .offset(y: minY > 0 ? -minY : -minY < scrollBackHeight ? 0 : -minY - scrollBackHeight)
                    }
                )
            }
            .frame(height: headerHeight)
            .zIndex(1)
        }
    }
}
