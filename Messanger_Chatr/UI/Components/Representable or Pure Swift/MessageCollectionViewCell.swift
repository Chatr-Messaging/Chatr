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
    var text: String = "hello world!"
    var isMine: Bool = false
    
     var body: some View {
         ZStack(alignment: isMine ? .bottomTrailing : .bottomLeading) {
             Text(text)
                 .font(.body)
                 .foregroundColor(isMine ? .white : .black)
                 .padding(10)
                 .background(isMine ? Color.blue : Color("lightGray"))
                 .cornerRadius(15)
                 .padding(.bottom, 12)
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
  let marginBottom: CGFloat = 32
  let marginContainer: CGFloat = 32
  let margin: CGFloat = 0
    var child = UIHostingController(rootView: MsgBubble())
    var parent = UIViewController()


  let container: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 16
    view.layer.masksToBounds = false

      
    return view
  }()

  let textView: UITextView = {
    let label = UITextView()
    label.textColor = .label
    label.backgroundColor = .clear
    label.isScrollEnabled = false
    label.isUserInteractionEnabled = false
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    return label
  }()

  let userImage: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "user0")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.layer.cornerRadius = 10
    imageView.clipsToBounds = true
    return imageView
  }()

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
      contentView.addSubviews([container, textView, userImage, child.view])
      
      // First, add the view of the child to the view of the parent
      // Then, add the child to the parent
  }

  override func layoutSubviews() {
    super.layoutSubviews()
  }
}

extension UIColor {
  static var random: UIColor {
    return .init(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 1)
  }
}

extension UIView {
  func addSubviews(_ subViews: [UIView]) {
    subViews.forEach { self.addSubview($0) }
  }
}

