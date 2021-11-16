//
//  NotificationSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/4/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct NotificationHUD: View {
    @State var showHUD: Bool = false
    let delayDuration = 3.5

    var image: String
    var color: Color
    var title: String
    var subtitle: String?
    
    var body: some View {
        ZStack {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                withAnimation(.easeInOut(duration: 0.45)){
                    showHUD = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    getRootController().view.subviews.forEach { view in
                        if view.tag == 1009 {
                            view.removeFromSuperview()
                        }
                    }
                }
            }, label: {
                HStack(spacing: 10) {
                    Image(systemName: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28, alignment: .center)
                        .foregroundColor(color)
                        .font(Font.title.weight(.regular))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(.none)
                            .fontWeight(subtitle == nil ? .medium : .semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(3)
                        }
                    }
                }.padding(10)
                .padding(.horizontal, 10)
                .padding(.trailing, subtitle == nil ? 0 : 10)
                .background(
                    BlurView(style: .systemMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color("blurBorder"), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 8)
                )
            })
            .buttonStyle(ClickButtonStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: showHUD ? 0 : -200)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7, blendDuration: 0)){
                    showHUD = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) {
                    withAnimation(.easeInOut(duration: 0.45)){
                        showHUD = false
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        guard !showHUD else { return }

                        getRootController().view.subviews.forEach { view in
                            if view.tag == 1009 {
                                view.removeFromSuperview()
                            }
                        }
                    }
                }
            }
        }
    }
}

// Extending view to create notification function..
extension View {
    func getRootController() -> UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .init()
        }

        guard let root = screen.windows.last?.rootViewController else {
            return .init()
        }

        return root
    }

    func showNotiHUD(image: String, color: Color = .primary, title: String, subtitle: String?) {
        // avoiding multiple HUDs...
        if getRootController().view.subviews.contains(where: { view in
            return view.tag == 1009
        }) {
            return
        }
        
        let hudViewController = UIHostingController(rootView: NotificationHUD(image: image, color: color, title: title, subtitle: subtitle))
        let size = hudViewController.view.intrinsicContentSize
        
        hudViewController.view.frame.size = size
        hudViewController.view.frame.origin = CGPoint(x: (Constants.screenWidth / 2) - (size.width / 2), y: 40)
        hudViewController.view.backgroundColor = .clear
        hudViewController.view.tag = 1009

        getRootController().view.addSubview(hudViewController.view)
    }

    func bringNotiViewToFront() {
        guard let notiView = getRootController().view.subviews.first(where: { $0.tag == 1009 }) else { return }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { UIApplication.shared.windows.first?.bringSubviewToFront(notiView)
        }
    }
}
