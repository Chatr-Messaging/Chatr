//
//  KeyboardAdjusting.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/29/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit
import SwiftUI
import Foundation

struct KeyboardAdjustingModifier: ViewModifier {
    func body(content: Content) -> some View {
        KeyboardAdjustingView {
            content
        }
    }
}

private struct KeyboardAdjustingView<Content: View>: UIViewControllerRepresentable {
    private let content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> KeyboardAdjustingViewController<Content> {
        return KeyboardAdjustingViewController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: KeyboardAdjustingViewController<Content>, context: Context) {
        // Nothing to do
    }
}

fileprivate final class KeyboardAdjustingViewController<Content: View>: UIViewController {
    private let notificationCenter: NotificationCenter
    private let rootView: Content

    private lazy var hostingController = UIHostingController(rootView: rootView)
    private var bottomConstraint: NSLayoutConstraint?

    //private var storage = [AnyCancellable]()

    init(rootView: Content, notificationCenter: NotificationCenter = .default) {
        self.rootView = rootView
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Embed the SwiftUI view by using view controller containment with a `UIHostingController`
        hostingController.view.backgroundColor = .clear
        addChild(hostingController)
        view.addSubview(hostingController.view)
        //hostingController.didMove(toParent: self)

            // Pin the hosted SwiftUI view to our view's edge, but keep a reference to the
            // bottom constraint so we can adjust it later for keyboard notifications.
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor)
        NSLayoutConstraint.activate([bottomConstraint])
        self.bottomConstraint = bottomConstraint
        [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardWillHideNotification
        ]
        .forEach {
            notificationCenter.addObserver(
                self,
                selector: #selector(keyboard(notification:)),
                name: $0, object: nil)
        }
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func keyboard(notification: Notification) {
        var options = UIView.AnimationOptions(rawValue: UInt(notification.animationCurve.rawValue) << 16)
        options.update(with: .layoutSubviews)

        let contentAbsoluteFrame = view.convert(hostingController.view.frame, to: nil)
        let offset = contentAbsoluteFrame.maxY - notification.endFrame.minY
        let keyboardHeight = max(0, offset)

        view.layoutIfNeeded()
        UIView.animate(
            withDuration: notification.duration,
            delay: 0.0,
            options: options,
            animations: { [weak self] in
                self?.bottomConstraint?.constant = keyboardHeight
                self?.view.layoutIfNeeded()
            }, completion: nil)
    }
}

fileprivate extension Notification {
    var animationCurve: UIView.AnimationCurve {
        guard let rawValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int) else {
            return UIView.AnimationCurve.linear
        }

        return UIView.AnimationCurve(rawValue: rawValue)!
    }

    var duration: TimeInterval {
        userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0
    }

    var endFrame: CGRect {
        userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
    }
}
