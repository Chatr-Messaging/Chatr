//
//  MessagesTimelineViewController.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 10/23/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import UIKit
import IGListKit
import SwiftUI
import RealmSwift

struct MessagesTimelineView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MessagesViewController {
        let messageVC =  MessagesViewController()
        
        return messageVC
    }
    
    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) { }
}

class MessagesViewController: UIViewController {
    var messages: [Any] = []
    var messagesRealm = MessagesRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(MessageStruct.self))
    
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 2)
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        
        return collectionView
    }()
    
    var bottomPadding: CGFloat {
        get {
            return self.view.safeAreaInsets.bottom
        }
    }
    
    let heightInputContainer: CGFloat = 52.0
    
    //    lazy var inputContainer: InputContainer = {
    //        let inputView = InputContainer()
    //        inputView.translatesAutoresizingMaskIntoConstraints = false
    //        inputView.autoresizingMask = .flexibleHeight
    //
    //        inputView.onSendButtonPressed = { [weak self] message in
    //            self?.onButtonSend(message: message)
    //        }
    //        inputView.onCameraButtonPressed = {
    //            self.onCameraButton()
    //        }
    //
    //        inputView.onGalleryButtonPressed = {
    //            self.onGalleryButton()
    //        }
    //
    //        return inputView
    //    }()
    
    //    override var inputAccessoryView: UIView? {
    //        get {
    //            return inputContainer
    //        }
    //    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    private var collectionViewHeight: NSLayoutConstraint?
    
    
    // MARK: Object lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    private func setup() {
        generateChat()
        //        adapter.collectionView = collectionView
        //        adapter.dataSource = self
        //
        //        view.addSubview(collectionView)
        //
        //        collectionView.alwaysBounceVertical = true
        //        collectionView.keyboardDismissMode = .interactive
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: View lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adapter.collectionView = collectionView
        adapter.dataSource = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.backgroundColor = .clear
        
        setObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - bottomPadding - heightInputContainer)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        guard let lastComment = messages.last else { return }
        
        adapter.scroll(to: lastComment, supplementaryKinds: nil, scrollDirection: .vertical, scrollPosition: .centeredVertically, animated: false)
    }
}

extension MessagesViewController : ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return messages as! [ListDiffable]
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        switch object {
        case is MessageModel:
            let sectionController = MessageSectionController()
            sectionController.inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            return sectionController
            //    case is ImageModel:
            //      let sectionController = ImagesSectionController()
            //      sectionController.inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            //      return sectionController
        default:
            let sectionController = MessageSectionController()
            sectionController.inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            return sectionController
        }
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

// MARK: - Keyboard Notifications
extension MessagesViewController {
    private func setObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func hideKeyboard(_ notification: Foundation.Notification) {
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
    }
    
    @objc private func showKeyboard(_ notification: Foundation.Notification) {
        guard let info = (notification as NSNotification).userInfo,
              let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                  return
              }
        let keyboardFrame = kbFrame.cgRectValue
        let endFrame = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        if endFrame.height > 80 {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: self.collectionView.contentOffset.y + keyboardFrame.height - heightInputContainer - bottomPadding), animated: true)
            collectionView.contentInset = UIEdgeInsets(top: 2.5, left: 0, bottom: 5 + keyboardFrame.height - heightInputContainer - bottomPadding, right: 0)
            collectionView.layoutIfNeeded()
        }
    }
}

extension MessagesViewController {
    func generateChat() {
        print("generating chtatsjgfd")
        messages = [
            MessageModel(id: -1, name: "Ignacia", text: "Have the courage to follow your heart and intuition.\n They somehow already know what you truly want to become.", isUser: false),
            MessageModel(id: 0, name: "Daniel", text: "Hola!", isUser: true),
            MessageModel(id: 1, name: "Daniel", text: "Todo bien?, todo correcto ?", isUser: true),
            MessageModel(id: 2, name: "Ignacia", text: "Sii 😀", isUser: false),
            MessageModel(id: 3, name: "Daniel", text: "Y yo que me alegro", isUser: true),
            MessageModel(id: 4, name: "Daniel", text: "Siempre hemos apostado por lo extraordinario. Es lo que nos ha dado la fuerza para trazar nuestro propio camino desde 1878.", isUser: true),
            MessageModel(id: 5, name: "Ignacia", text: "Ir a la caza de sabores únicos requiere tiempo y paciencia, pero sobre todo necesita la habilidad y creatividad de reescribir las reglas. \n Por eso hemos revisado cuidadosamente nuestro proceso de producción para incorporar diferenciadores matices de roble en la personalidad de Manifest", isUser: false),
            MessageModel(id: 6, name: "Daniel", text: "In general, that should be all you need in most cases.\n Even if you are changing the height of the text view on the fly, this usually does all you need.\n (A common example of changing the height on the fly, is changing it as the user types.) \n Here is the broken UITextView from Apple...", isUser: true),
            MessageModel(id: 7, name: "Ignacia", text: "You can’t connect the dots looking forward; you can only connect them looking backward. So you have to trust that the dots will somehow connect in your future.", isUser: false),
            MessageModel(id: 8, name: "Ignacia", text: "Your time is limited, so don’t waste it living someone else’s life.", isUser: false),
            MessageModel(id: 9, name: "Ignacia", text: "Have the courage to follow your heart and intuition. They somehow already know what you truly want to become.", isUser: false),
            MessageModel(id: 10, name: "Ignacia", text: "If today were the last day of your life, would you want to do what you are about to do today?", isUser: false),
            MessageModel(id: 11, name: "Daniel", text: "Hola!", isUser: true),
            MessageModel(id: 12, name: "Daniel", text: "Todo bien?, todo correcto ?", isUser: true),
            MessageModel(id: 13, name: "Ignacia", text: "Sii 😀", isUser: false),
            MessageModel(id: 14, name: "Daniel", text: "Y yo que me alegro", isUser: true),
            MessageModel(id: 15, name: "Daniel", text: "Siempre hemos apostado por lo extraordinario. Es lo que nos ha dado la fuerza para trazar nuestro propio camino desde 1878.", isUser: true),
            MessageModel(id: 16, name: "Ignacia", text: "Ir a la caza de sabores únicos requiere tiempo y paciencia, pero sobre todo necesita la habilidad y creatividad de reescribir las reglas.\n Por eso hemos revisado cuidadosamente nuestro proceso de producción para incorporar diferenciadores matices de roble en la personalidad de Manifest", isUser: false),
            MessageModel(id: 17, name: "Daniel", text: "In general, that should be all you need in most cases.\n Even if you are changing the height of the text view on the fly, this usually does all you need.\n (A common example of changing the height on the fly, is changing it as the user types.) \n Here is the broken UITextView from Apple...", isUser: true),
            MessageModel(id: 18, name: "Ignacia", text: "You can’t connect the dots looking forward; you can only connect them looking backward. So you have to trust that the dots will somehow connect in your future.", isUser: false),
            MessageModel(id: 19, name: "Ignacia", text: "Have the courage to follow your heart and intuition.\n They somehow already know what you truly want to become.", isUser: false),
            MessageModel(id: 20, name: "Ignacia", text: "If today were the last day of your life, would you want to do what you are about to do today?", isUser: false)
        ]
    }
}
