//
//  NewConversationView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/19/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube
import FirebaseDatabase

struct NewConversationView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @State var usedAsNew: Bool = false
    @State var forwardContact: Bool = false
    @State var allowOnlineSearch: Bool = true
    @State var searchText: String = ""
    @State var regristeredAddressBook: [User] = []
    @Binding var selectedContact: [Int]
    @State var publicGroupOn: Bool = false
    @State var grandUsers: [User] = []
    @State var outputSearchText: String = ""
    @Binding var newDialogID: String
    @State var showingMaxAlert: Bool = false
    @State var navigationPrivate: Bool = true
    @State var creatingDialog: Bool = false
    @State var groupName: String = ""
    @State var description: String = ""
    @State var inputImageUrl: URL? = nil
    @State var inputCoverImageUrl: URL? = nil
    @State var selectedTags: [publicTag] = []
    //@ObservedObject var contacts = ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
    //@ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    //@ObservedObject var addressBook = AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self))
    //@ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))
    
    var contacts: [ContactStruct] {
        return self.auth.contacts.filterContact(text: self.searchText, ascending: true).filter({ $0.isMyContact == true && $0.id != UserDefaults.standard.integer(forKey: "currentUserID") && $0.fullName != "No Name" })
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                //MARK: Top Navigation
                if self.usedAsNew {
                    ZStack(alignment: self.navigationPrivate ? .leading : .trailing) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(Color("SegmentSliderColor"))
                            .frame(width: 100, height: 40, alignment: .center)
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                            .offset(x: self.navigationPrivate ? -22.5 : 22.5)

                        HStack(spacing: 50) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation(Animation.easeInOut(duration: 0.2)) {
                                    self.navigationPrivate = true
                                }
                            }, label: {
                                Text("Private")
                                    .font(.headline)
                                    .fontWeight(self.navigationPrivate ? .bold : .medium)
                                    .foregroundColor(self.navigationPrivate ? .blue : .primary)
                            })

                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            
                                withAnimation(Animation.easeInOut(duration: 0.2)) {
                                    self.navigationPrivate = false
                                }
                            }, label: {
                                Text("Public")
                                    .font(.headline)
                                    .fontWeight(!self.navigationPrivate ? .bold : .medium)
                                    .foregroundColor(!self.navigationPrivate ? .blue : .primary)
                            })
                        }
                    }.padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .padding(.vertical, -3)
                            .padding(.horizontal, -10)
                            .foregroundColor(Color("pendingBtnColor"))
                    )
                    .padding(.top, 25) //don't touch this or switch up the padding... there for a reason
                }

                HStack(alignment: .top, spacing: 0) {
                    //MARK: Private or Group Section
                    VStack {
                        //MARK: Search Bar
                        VStack {
                            if self.allowOnlineSearch {
                                HStack {
                                    Text("SEARCH NAME OR PHONE NUMBER:")
                                        .font(.caption)
                                        .fontWeight(.regular)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    Spacer()
                                }.padding(.bottom, 2)
                                
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .padding(.leading, 15)
                                        .foregroundColor(.primary)
                                    
                                    TextField("Search", text: $searchText, onCommit: {
                                        self.outputSearchText = self.searchText
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        if allowOnlineSearch {
                                            self.grandSeach(searchText: self.outputSearchText)
                                        }
                                    })
                                    .padding(EdgeInsets(top: 16, leading: 5, bottom: 16, trailing: 10))
                                    .foregroundColor(.primary)
                                    .font(.system(size: 18))
                                    .lineLimit(1)
                                    .keyboardType(.webSearch)
                                    .onChange(of: self.searchText) { value in
                                        if self.searchText.count >= 3 && self.allowOnlineSearch {
                                            self.grandSeach(searchText: self.searchText)
                                        } else {
                                            self.grandUsers.removeAll()
                                        }
                                    }
                                    
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            self.searchText = ""
                                            self.outputSearchText = ""
                                            self.grandUsers.removeAll()
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }.padding(.horizontal, 15)
                                    }
                                    
                                }.background(Color("buttonColor"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .circular))
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                            }
                        }.padding(.top, self.allowOnlineSearch ? 20 : 60)
                        .padding(.horizontal)

                        //MARK: Search All Section
                        if self.grandUsers.count != 0 {
                            HStack {
                                Text("TOP RESULTS:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.top, 25)

                            self.styleBuilder(content: {
                                ForEach(self.grandUsers, id: \.id) { searchedContact in
                                    if searchedContact.id != Session.current.currentUserID {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            ContactCell(user: searchedContact, selectedContact: self.$selectedContact)
                                                .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                                .padding(.horizontal)
                                                .padding(.vertical, 10)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    DispatchQueue.main.async {
                                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                        if self.selectedContact.contains(Int(searchedContact.id)) {
                                                            self.selectedContact.removeAll(where: { $0 == searchedContact.id })
                                                        } else if self.forwardContact && self.selectedContact.count >= 1 {
                                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                        } else {
                                                            self.selectedContact.append(Int(searchedContact.id))
                                                        }
                                                    }
                                                }

                                            if self.grandUsers.last != searchedContact {
                                                Divider()
                                                    .frame(width: Constants.screenWidth - 100)
                                            }
                                        }
                                    }
                                }
                            })
                        }

                        //MARK: Contacts Section
                        if self.contacts.count != 0 {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Contacts:")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text(self.contacts.count == 1 ? "\(self.contacts.count) CONTACT" : "\(self.contacts.count) CONTACTS")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.top, 25)
                        }

                        self.styleBuilder(content: {
                            ForEach(self.contacts.indices, id: \.self) { i in
                                VStack(alignment: .trailing, spacing: 0) {
                                    ContactRealmCell(contact: self.contacts[i], isSelected: self.selectedContact.contains(self.contacts[i].id) && !(self.forwardContact && self.selectedContact.count >= 1)) {
                                        if self.selectedContact.contains(self.contacts[i].id) {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            self.selectedContact.removeAll(where: { $0 == self.contacts[i].id })
                                        } else if self.forwardContact && self.selectedContact.count >= 1 {
                                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        } else {
                                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            self.selectedContact.append(Int(self.contacts[i].id))
                                        }
                                    }

                                    if self.contacts.last?.id != self.contacts[i].id {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 100)
                                    }
                                }
                            }
                        })
                        

                        //MARK: Regristered Section
                        if self.regristeredAddressBook.count != 0 {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Regristered:")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text(self.regristeredAddressBook.count == 1 ? "\(self.regristeredAddressBook.count) REGRISTERED CONTACT" : "\(self.regristeredAddressBook.count) REGRISTERED CONTACTS")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.horizontal)
                            .padding(.top, 25)
                            
                            self.styleBuilder(content: {
                                ForEach(self.regristeredAddressBook, id: \.id) { result in
                                    VStack(alignment: .trailing, spacing: 0) {
                                        ContactCell(user: result, selectedContact: self.$selectedContact)
                                            .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                            .padding(.horizontal)
                                            .padding(.vertical, 10)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                DispatchQueue.main.async {
                                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                    if self.selectedContact.contains(Int(result.id)) {
                                                        self.selectedContact.removeAll(where: { $0 == result.id })
                                                    } else if self.forwardContact && self.selectedContact.count >= 1 {
                                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                    } else {
                                                        self.selectedContact.append(Int(result.id))
                                                    }
                                                }
                                            }

                                        if self.regristeredAddressBook.last != result {
                                            Divider()
                                                .frame(width: Constants.screenWidth - 100)
                                        }
                                    }
                                }
                            })
                        }

                        //MARK: Address Book Section
                        if !self.forwardContact {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Address Book:")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text("\(self.auth.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.count) CONTACTS")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.horizontal)
                            .opacity(self.auth.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.count != 0 ? 1 : 0)
                            .padding(.top, 25)
                            
                            self.styleBuilder(content: {
                                ForEach(self.auth.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }, id: \.phone) { result in
                                    VStack(alignment: .trailing, spacing: 0) {
                                        SelectableAddressBookContact(addressBook: result)
                                            .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                            .padding(.horizontal)
                                            .padding(.vertical, 10)

                                        if self.auth.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.last != result {
                                            Divider()
                                                .frame(width: Constants.screenWidth - 100)
                                        }
                                    }
                                }
                            })

                            SyncAddressBook()
                                .opacity(self.auth.addressBook.results.count == 0 ? 1 : 0)
                                .offset(y: -60)
                        }
                        
                        //MARK: FOOTER
                        FooterInformation(middleText: self.auth.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.count == 1 ? "\(self.auth.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.count) total contact above" : "\(self.auth.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.count) total contacts above")
                            .padding(.vertical, 35)
                    }.frame(width: Constants.screenWidth)

                    //MARK: Public Dialog
                    VStack {
                        NewPublicConversationSection(creatingDialog: self.$creatingDialog, isNotPresent: self.$navigationPrivate, groupName: self.$groupName, description: self.$description, inputImageUrl: self.$inputImageUrl, inputCoverImageUrl: self.$inputCoverImageUrl, selectedTags: self.$selectedTags)
                            .environmentObject(auth)
                            .resignKeyboardOnDragGesture()
                        
                        //MARK: FOOTER
                        FooterInformation()
                            .padding(.vertical, 35)
                    }.frame(width: Constants.screenWidth)
                }.offset(x: self.navigationPrivate ? (Constants.screenWidth / 2) : -(Constants.screenWidth / 2))
            }.disabled(self.creatingDialog ? true : false)
            .navigationBarItems(leading:
                Button(action: {
                    self.selectedContact.removeAll()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.primary)
                }, trailing:
                Button(action: {
                    self.createAction()
                }) {
                    Text(self.usedAsNew ? (self.creatingDialog ? "Creating" : "Create") : self.forwardContact ? "Send" : "Add")
                        .foregroundColor(self.canCreate() ? .blue : .secondary)
                        .fontWeight(self.canCreate() ? .bold : .none)
                }.disabled(self.canCreate() ? false : true)
            )
            .navigationBarTitle(self.usedAsNew ? (self.navigationPrivate ? (self.selectedContact.count > 0 ? self.selectedContact.count > Constants.maxNumberGroupOccu ? "Max Reached" : "New Chat \(self.selectedContact.count)" : "New Chat") : "New Public Chat") : self.forwardContact ? "Forward Contact" : "Add Contact", displayMode: .inline)
            .onAppear() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Request.registeredUsersFromAddressBook(withUdid: UIDevice.current.identifierForVendor?.uuidString, isCompact: false, successBlock: { (users) in
                        DispatchQueue.main.async {
                            for i in users {
                                if !self.auth.contacts.results.contains(where: { $0.id == i.id || $0.id == UserDefaults.standard.integer(forKey: "currentUserID") }) {
                                    self.regristeredAddressBook.append(i)
                                }
                            }
                        }
                    })
                }
            }
        }.background(Color("bgColor"))
        .edgesIgnoringSafeArea(.all)
    }

    func grandSeach(searchText: String) {
        if searchText != "" {
            Request.users(withFullName: searchText, paginator: Paginator.limit(20, skip: 0), successBlock: { (paginator, users) in
                for i in users {
                    changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: Int(i.id), completion: { firebaseContact in
                        if !firebaseContact.isMessagingPrivate {
                            self.grandUsers.append(i)
                            self.grandUsers.removeDuplicates()
                        }
                    })
                }
            })
            
            Request.users(withPhoneNumbers: [searchText], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
                for i in users {
                    changeContactsRealmData.shared.observeFirebaseContactReturn(contactID: Int(i.id), completion: { firebaseContact in
                        if !firebaseContact.isMessagingPrivate {
                            self.grandUsers.append(i)
                            self.grandUsers.removeDuplicates()
                        }
                    })
                }
            })
        }
    }
    
    func createAction() {
        if self.usedAsNew {
            if self.navigationPrivate {
                if self.selectedContact.count <= Constants.maxNumberGroupOccu {
                    let dialog = ChatDialog(dialogID: nil, type: self.selectedContact.count > 1 ? .group : .private)
                    var occu: [NSNumber] = []
                    for i in self.selectedContact {
                        occu.append(NSNumber(value: i))
                    }
                    occu.append(NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID")))
                    dialog.occupantIDs = occu  // an ID of opponent
                    if occu.count > 2 {
                        dialog.name = "\(self.auth.profile.results.first?.fullName ?? "Chatr User")'s Group Chat"
                    }
                    Request.createDialog(dialog, successBlock: { (dialog) in
                        changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                            let title = dialog.type == .private ? "New Chat" : "New Group Chat"
                            let msg = dialog.type == .private ? "started a new chat with you" : "started a new group chat with you"

                            self.auth.sendPushNoti(userIDs: occu, title: title, message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") " + msg)
                            self.selectedContact.removeAll()
                            self.newDialogID = dialog.id?.description ?? ""
                            UserDefaults.standard.set(self.newDialogID, forKey: "selectedDialogID")
                            withAnimation {
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                    }
                } else {
                    //too many contact selected
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            } else {
                //Public section
                withAnimation {
                    self.creatingDialog = true
                }
                let dialog = ChatDialog(dialogID: nil, type: .public)
                var occu: [NSNumber] = []
                occu.append(NSNumber(value: UserDefaults.standard.integer(forKey: "currentUserID")))
                dialog.occupantIDs = occu
                dialog.name = self.groupName
                dialog.dialogDescription = self.description

                //let data = inputImage?.jpegData(compressionQuality: 1.0)
                //let coverData = inputCoverImage?.jpegData(compressionQuality: 1.0)
                let databaseRef = Database.database().reference().child("Marketplace")
                guard let avatarUrl = self.inputImageUrl, let coverUrl = inputCoverImageUrl else { return }

                self.auth.uploadFile(avatarUrl, completionHandler: { avatarId in
                    dialog.photo = Constants.uploadcareBaseUrl + avatarId + Constants.uploadcareStandardTransform

                    Request.createDialog(dialog, successBlock: { (dialog) in
                        changeDialogRealmData.shared.fetchDialogs(completion: { _ in
                            for i in self.selectedTags {
                                databaseRef.child("tags").child(i.title).child("dialogs").setValue([dialog.id : true])
                            }
                            
                            self.auth.uploadFile(coverUrl, completionHandler: { coverPhotoId in
                                changeDialogRealmData.shared.fetchTotalCountPublicDialogs(completion: { count in
                                    databaseRef.child("public_dialogs").child(dialog.id?.description ?? "").setValue(["avatar" : dialog.photo ?? Constants.uploadcareBaseUrl + avatarId + Constants.uploadcareStandardTransform, "banned" : false, "canMembersType" : false, "cover_photo" : Constants.uploadcareBaseUrl + coverPhotoId + Constants.uploadcareStandardTransform, "creation_order" : count + 1, "date_created" : Date().description, "description" : dialog.dialogDescription ?? "empty description", "memberCount" : 1, "members" : ["\(UserDefaults.standard.integer(forKey: "currentUserID"))" : true], "name" : dialog.name ?? self.groupName, "owner" : UserDefaults.standard.integer(forKey: "currentUserID")])

                                    self.description = ""
                                    self.groupName = ""
                                    self.inputImageUrl = nil
                                    self.selectedTags.removeAll()
                                    self.newDialogID = dialog.id?.description ?? ""
                                    UserDefaults.standard.set(self.newDialogID, forKey: "selectedDialogID")
                                    self.creatingDialog = false
                                    withAnimation {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                })
                            })
                        })
                    }) { (error) in
                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                        self.creatingDialog = false
                    }
                    
                })
            }
        } else {
            withAnimation {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    func canCreate() -> Bool {
        if self.navigationPrivate && self.selectedContact.count != 0 && self.selectedContact.count < Constants.maxNumberGroupOccu {
            return true
        } else if self.selectedTags.count != 0 && self.groupName.count != 0 && self.description.count != 0 && self.inputImageUrl != nil && self.inputCoverImageUrl != nil && !self.creatingDialog {
            return true
        } else {
            return false
        }
    }
    
    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVStack(alignment: .center, spacing: 0) {
            content()
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
}
