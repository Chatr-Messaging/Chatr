//
//  MultilineTextView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/16/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.text = self.text
        view.font = .systemFont(ofSize: 18)
        view.textColor = UIColor(named: "textColor")
        
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        DispatchQueue.main.async {
            self.height = uiView.contentSize.height
        }
    }
}
