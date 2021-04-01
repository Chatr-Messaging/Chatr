//
//  SwipableSegment.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 4/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct SwipableSegment<Content: View>: UIViewRepresentable {
    @Binding var offset: CGFloat

    var content: Content
    var rect: CGRect
    var tabs: [Any]
    let scrollView = UIScrollView()

    init(tabs: [Any],rect: CGRect,offset: Binding<CGFloat>,@ViewBuilder content: ()->Content) {
        self.content = content()
        self._offset = offset
        self.rect = rect
        self.tabs = tabs
    }
    
    func makeCoordinator() -> Coordinator {
        return SwipableSegment.Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) ->  UIScrollView {
        setUpScrollView()
        
        scrollView.contentSize = CGSize(width: rect.width * CGFloat(tabs.count), height: rect.height)
        scrollView.addSubview(extractView())
        scrollView.delegate = context.coordinator

        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if uiView.contentOffset.x != offset{
            uiView.delegate = nil

            UIView.animate(withDuration: 0.4) {
                uiView.contentOffset.x = offset
            } completion: { (status) in
                if status{uiView.delegate = context.coordinator}
            }
        }
    }

    func setUpScrollView(){
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    func extractView()->UIView {
        let controller = UIHostingController(rootView: content)
        controller.view.frame = CGRect(x: 0, y: 0, width: rect.width * CGFloat(tabs.count), height: rect.height)
        
        return controller.view!
    }
    
    class Coordinator: NSObject,UIScrollViewDelegate{
        var parent: SwipableSegment

        init(parent: SwipableSegment) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.offset = scrollView.contentOffset.x
        }
    }
}


