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
import Cache
import ConnectyCube

struct MessagesTimelineView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MessagesViewController {
        let messageVC =  MessagesViewController()
        
        return messageVC
    }
    
    func updateUIViewController(_ uiViewController: MessagesViewController, context: Context) { }
}

class MessagesViewController: UIViewController {
    var messages: [MessageModel] = []

    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 2)
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.backgroundColor = .clear

        return collectionView
    }()

    var bottomPadding: CGFloat {
        get {
            return 0 //self.view.safeAreaInsets.bottom
        }
    }

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
        generateChat(dialogId: UserDefaults.standard.string(forKey: "selectedDialogID") ?? "")
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
        setObservers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - bottomPadding)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 55, right: 0)

        guard let lastComment = messages.last else { return }

        adapter.scroll(to: lastComment, supplementaryKinds: nil, scrollDirection: .vertical, scrollPosition: .centeredVertically, animated: false)
    }
}

extension MessagesViewController : ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return messages as [ListDiffable]
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        switch object {
        // Keeping like this just to show you have multiple model options
        case is MessageModel:
            let sectionController = MessageSectionController()
            sectionController.inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

            return sectionController
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
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 55, right: 0)
    }
    
    @objc private func showKeyboard(_ notification: Foundation.Notification) {
        guard let info = (notification as NSNotification).userInfo,
              let kbFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardFrame = kbFrame.cgRectValue
        let endFrame = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        if endFrame.height > 80 {
            collectionView.setContentOffset(CGPoint(x: 0, y: self.collectionView.contentOffset.y + keyboardFrame.height - bottomPadding), animated: true)
            collectionView.contentInset = UIEdgeInsets(top: 2.5, left: 0, bottom: 55 + keyboardFrame.height - bottomPadding, right: 0)

            collectionView.layoutIfNeeded()
        }
    }
}

extension MessagesViewController {
    func generateChat(dialogId: String) {
        let extRequest : [String: String] = ["sort_desc" : "date_sent", "mark_as_read" : "0"]

        print("requesting messages: \(dialogId)")
        Request.messages(withDialogID: dialogId, extendedRequest: extRequest, paginator: Paginator.limit(UInt(40), skip: UInt(0)), successBlock: { (messages, _) in
            print("found the requested messages: \(messages.count)")

            let diskConfig = DiskConfig(name: "test1")
            let memoryConfig = MemoryConfig(expiry: .never, countLimit: 100, totalCostLimit: 50)
            let storage = try? Storage<String, MessageModel>(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: MessageModel.self))
            
            for msgz in messages {
                let foundMsg = try? storage?.object(forKey: msgz.id ?? "")

                if let temp = foundMsg, let value = temp {
                    print("found the message adding it now: \(String(describing: msgz.text))")
                    self.messages.insert(value, at: 0)
                } else if foundMsg == nil {
                    print("creating new message model: \(String(describing: msgz.text))")
                    let newMsg = MessageModel()
                    newMsg.id = msgz.id ?? ""
                    newMsg.text = msgz.text ?? ""
                    newMsg.dialogID = msgz.dialogID ?? ""
                    newMsg.date = msgz.dateSent ?? Date()
                    newMsg.destroyDate = Int(msgz.destroyAfterInterval)
                    newMsg.senderID = Int(msgz.senderID)
                    newMsg.positionRight = Int(msgz.senderID) == UserDefaults.standard.integer(forKey: "currentUserID") ? true : false

                    for read in msgz.readIDs ?? [] {
                        if !newMsg.readIDs.contains(Int(truncating: read)) {
                            newMsg.readIDs.append(Int(truncating: read))
                        }
                    }

                    for deliv in msgz.deliveredIDs ?? [] {
                        if !newMsg.deliveredIDs.contains(Int(truncating: deliv)) {
                            newMsg.deliveredIDs.append(Int(truncating: deliv))
                        }
                    }

                    if msgz.delayed {
                        newMsg.hadDelay = true
                    }

                    if (msgz.destroyAfterInterval > 0) {
                        newMsg.destroyDate = Int(msgz.destroyAfterInterval)
                    }

                    if let attachments = msgz.attachments {
                        for attach in attachments {
                            //image/video attachment
                            if let imagePram = attach.customParameters as? [String: String] {
                                if let typez = attach.type {
                                    newMsg.imageType = typez
                                }

                                if let imagez = imagePram["imageURL"] {
                                    newMsg.image = imagez
                                }

                                if let imageUploadPram = imagePram["uploadId"] {
                                    newMsg.uploadMediaId = imageUploadPram
                                }

                                if let contactID = imagePram["contactID"] {
                                    newMsg.contactID = Int(contactID) ?? 0
                                }

                                if let channelId = imagePram["channelID"] {
                                    newMsg.channelID = channelId
                                }

                                if let longitude = imagePram["longitude"] {
                                    newMsg.longitude = Double("\(longitude)") ?? 0
                                }

                                if let latitude = imagePram["latitude"] {
                                    newMsg.latitude = Double("\(latitude)") ?? 0
                                }

                                if let videoUrl = imagePram["videoURL"] {
                                    newMsg.image = "\(videoUrl)"
                                }

                                if let placeholderId = imagePram["placeholderURL"] {
                                    newMsg.placeholderVideoImg = "\(placeholderId)"
                                }

                                if let ratio = imagePram["mediaRatio"] {
                                    newMsg.mediaRatio = Double("\(ratio)") ?? 0.0
                                }
                            }
                        }
                    }

                    self.messages.insert(newMsg, at: 0)

                    try? storage?.setObject(newMsg, forKey: msgz.id ?? "")
                }
            }
            
//            self.insertMessages(messages, completion: {
//                self.checkSurroundingValues(dialogId: dialogID, completion: {
//                    completion(true)
//                })
//            })
        }) { errorz in
            print("error fetching messages: \(errorz.localizedDescription)")
        }
    }
}
