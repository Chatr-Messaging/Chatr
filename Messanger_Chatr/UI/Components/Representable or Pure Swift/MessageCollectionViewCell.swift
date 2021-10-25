//
//  MessageCollectionViewCell.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/24/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI

struct MsgBubble: View {
    var text: String = ""
    var isMine: Bool = false

    var body: some View {
        ZStack(alignment: isMine ? .bottomTrailing : .bottomLeading) {
            Text(text)
                .font(.body)
                .foregroundColor(isMine ? .white : .black)
                .padding(10)
                .padding(.leading, isMine ? 0 : 4)
                .padding(.trailing, isMine ? 4 : 0)
                .background(isMine ? Color.blue : Color("lightGray"))
                .cornerRadius(20)
                .padding(.bottom, 12)
                .padding(.leading, isMine ? 0 : 12)
                .padding(.trailing, isMine ? 12 : 0)
                .font(.system(size: 14, weight: .regular, design: .default))

            Image("discoverBackground")
                .resizable()
                .scaledToFill()
                .frame(width: Constants.smallAvitarSize, height: Constants.smallAvitarSize, alignment: .center)
                .clipped()
                .cornerRadius(Constants.smallAvitarSize / 2)
        }
    }
}

final class MessageCollectionViewCell: UICollectionViewCell {
    var child = UIHostingController(rootView: MsgBubble())

    override init(frame: CGRect) {
        super.init(frame: frame)
        makeUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        makeUI()
    }
    
    func makeUI() {
        contentView.backgroundColor = .clear
        child.view.backgroundColor = .clear
        contentView.addSubviews([child.view])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension UIView {
    func addSubviews(_ subViews: [UIView]) {
        subViews.forEach { self.addSubview($0) }
    }
}

