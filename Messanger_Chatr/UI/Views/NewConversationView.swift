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
    @State var allowOnlineSearch: Bool = true
    @State var searchText: String = ""
    @State var regristeredAddressBook: [User] = []
    @Binding var selectedContact: [Int]
    @State var publicGroupOn: Bool = false
    @State var grandUsers: [User] = []
    @State var outputSearchText: String = ""
    @Binding var newDialogID: String
    @State var isPremium: Bool = false
    @ObservedObject var contacts = ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
    @ObservedObject var addressBook = AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self))
    @ObservedObject var dialogs = DialogRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(DialogStruct.self))

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
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
                            }.padding(.top, 10)
                            .padding(.bottom, 2)
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .padding(.leading, 15)
                                    .foregroundColor(.secondary)
                                
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
                                    print("the value is: \(value)")
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
                    }.padding(.top, self.allowOnlineSearch ? 20 : 0)
                    .padding(.horizontal)
                    
                    //MARK: Public Section
//                    VStack {
//                        if self.isPremium {
//                            HStack {
//                                Text("PUBLIC:")
//                                    .font(.caption)
//                                    .fontWeight(.regular)
//                                    .foregroundColor(.secondary)
//                                    .padding(.horizontal)
//                                    .padding(.horizontal)
//                                Spacer()
//                            }.padding(.top, 10)
//
//                            VStack {
//                                VStack {
//                                    HStack {
//                                        Text("New Channel")
//                                            .font(.none)
//                                            .foregroundColor(.primary)
//
//                                        Spacer()
//
//                                        Toggle("", isOn: self.$publicGroupOn)
//                                        .onReceive([self.publicGroupOn].publisher.first()) { (value) in
//                                            print("New value is: \(value)")
//                                        }
//                                    }.padding(.horizontal)
//                                }.padding(.vertical, 8)
//                            }.background(Color("buttonColor"))
//                            .cornerRadius(15)
//                            .padding(.horizontal)
//                            .padding(.bottom, 25)
//
//                            if self.publicGroupOn {
//                                HStack {
//                                    Text("PLEASE COMPLETE THE BELOW:")
//                                        .font(.caption)
//                                        .fontWeight(.regular)
//                                        .foregroundColor(.secondary)
//                                        .padding(.horizontal)
//                                        .padding(.horizontal)
//                                    Spacer()
//                                }
//
//                                VStack {
//                                    VStack {
//                                        VStack(alignment: .center) {
//                                            Button(action: {
//                                                print("select image")
//                                            }) {
//                                                VStack {
////                                                    Image()
////                                                        .frame(width: 60, height: 60)
////                                                        .clipShape(Circle())
//
//                                                    Text("Select Photo")
//                                                        .font(.none)
//                                                        //.fontWeight(.semiBold)
//                                                        .foregroundColor(.blue)
//                                                }
//                                            }
//                                        }.padding(.horizontal)
//                                    }.padding(.vertical, 6)
//                                }.background(Color("buttonColor"))
//                                .cornerRadius(15)
//                                .padding(.horizontal)
//                                .padding(.bottom, 25)
//                            }
//                        }
//                    }.onAppear() {
//                        self.isPremium = self.profile.results.first?.isPremium ?? false
//                    }

                    //Spacer()
                    
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

                        LazyVStack(spacing: 0) {
                            ForEach(self.grandUsers, id: \.self) { searchedContact in
                               if searchedContact.id != Session.current.currentUserID {
                                    VStack(alignment: .trailing, spacing: 0) {
                                        ContactCell(user: searchedContact, selectedContact: self.$selectedContact)
                                            .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                            .padding(.horizontal)
                                            .padding(.vertical, 10)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                if self.selectedContact.contains(Int(searchedContact.id)) {
                                                    self.selectedContact.removeAll(where: { $0 == searchedContact.id })
                                                } else {
                                                    self.selectedContact.append(Int(searchedContact.id))
                                                }
                                            }

                                        if self.grandUsers.last != searchedContact {
                                            Divider()
                                                .frame(width: Constants.screenWidth - 100)
                                        }
                                    }
                                }
                            }
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                        .padding(.horizontal)
                    }

                    //MARK: Contacts Section
                    if self.contacts.filterContact(text: self.searchText).count != 0 {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Contacts:")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                Text(Chat.instance.contactList?.contacts.count == 1 ? "\(Chat.instance.contactList?.contacts.count ?? 0) CONTACT" : "\(self.contacts.filterContact(text: self.searchText).filter({ $0.id != UserDefaults.standard.integer(forKey: "currentUserID") && $0.fullName != "No Name" }).count) CONTACTS")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }.padding(.horizontal)
                        .padding(.horizontal)
                        .padding(.top, 25)

                        LazyVStack(spacing: 0) {
                            ForEach(self.contacts.filterContact(text: self.searchText).sorted { $0.fullName < $1.fullName }.filter({ $0.id != UserDefaults.standard.integer(forKey: "currentUserID") && $0.fullName != "No Name" }), id: \.self) { contact in
                                VStack(alignment: .trailing, spacing: 0) {
                                    ContactRealmCell(selectedContact: self.$selectedContact, contact: contact)
                                        .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                        .padding(.horizontal)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            if self.selectedContact.contains(contact.id) {
                                                self.selectedContact.removeAll(where: { $0 == contact.id })
                                            } else {
                                                self.selectedContact.append(contact.id)
                                            }
                                        }

                                    if self.contacts.filterContact(text: self.searchText).sorted { $0.fullName < $1.fullName }.last != contact {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 100)
                                    }
                                }
                            }
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                        .padding(.horizontal)
                    }

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
                        
                        LazyVStack(spacing: 0) {
                            ForEach(self.regristeredAddressBook, id: \.self) { result in
                                VStack(alignment: .trailing, spacing: 0) {
                                    ContactCell(user: result, selectedContact: self.$selectedContact)
                                        .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                        .padding(.horizontal)
                                        .padding(.vertical, 10)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            if self.selectedContact.contains(Int(result.id)) {
                                                self.selectedContact.removeAll(where: { $0 == result.id })
                                            } else {
                                                self.selectedContact.append(Int(result.id))
                                            }
                                        }

                                    if self.regristeredAddressBook.last != result {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 100)
                                    }
                                }
                            }
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                        .padding(.horizontal)
                    }

                    //MARK: Address Book Section
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Address Book:")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)

                            Text("\(self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.count) CONTACTS")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }.padding(.horizontal)
                    .padding(.horizontal)
                    .opacity(self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.count != 0 ? 1 : 0)
                    .padding(.top, 25)
                    
                    LazyVStack(spacing: 0) {
                        ForEach(self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }, id: \.self) { result in
                            VStack(alignment: .trailing, spacing: 0) {
                                SelectableAddressBookContact(addressBook: result)
                                    .animation(.spring(response: 0.15, dampingFraction: 0.60, blendDuration: 0))
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)

                                if self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.last != result {
                                    Divider()
                                        .frame(width: Constants.screenWidth - 100)
                                }
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                    .padding(.horizontal)

                    SyncAddressBook()
                        .opacity(self.addressBook.results.count == 0 ? 1 : 0)
                        .offset(y: -60)
                    
                    Spacer()
                    
                    //MARK: FOOTER
                    FooterInformation(middleText: self.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.results.count == 1 ? "\(self.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.results.count) total contact above" : "\(self.addressBook.results.count + self.regristeredAddressBook.count + self.contacts.results.count) total contacts above")
                        .padding(.vertical, 35)
                }
            }.navigationBarTitle(self.selectedContact.count > 0 ? self.usedAsNew ? "(\(self.selectedContact.count)) New Chat" : "Add \(self.selectedContact.count) Contact" : self.usedAsNew ? "New Chat" : "Add Contact", displayMode: .inline)
            .background(Color("bgColor"))
            .frame(width: Constants.screenWidth, alignment: .center)
            .padding(.horizontal)
            .edgesIgnoringSafeArea(.bottom)
            .resignKeyboardOnDragGesture()
            .navigationBarItems(leading:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.primary)
                }, trailing:
                Button(action: {
                    if self.usedAsNew {
                        if self.selectedContact.count > 0 {
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
                                changeDialogRealmData().fetchDialogs(completion: { _ in
                                    self.auth.sendPushNoti(userIDs: occu, message: "\(self.auth.profile.results.first?.fullName ?? "Chatr User") created a new group chat with you 🥳")
                                    self.selectedContact.removeAll()
                                    self.newDialogID = "\(String(describing: dialog.id))"
                                    withAnimation {
                                        self.presentationMode.wrappedValue.dismiss()
                                    }
                                })
                            }) { (error) in
                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                            }
                        }
                    } else {
                        withAnimation {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }) {
                    Text(self.usedAsNew ? "Create" : "Add")
                        .foregroundColor(self.selectedContact.count != 0 ? .blue : .secondary)
                        .fontWeight(self.selectedContact.count != 0 ? .bold : .none)
                }.disabled(self.selectedContact.count != 0 ? false : true)
            )
            .onAppear() {
                Request.registeredUsersFromAddressBook(withUdid: UIDevice.current.identifierForVendor?.uuidString, isCompact: false, successBlock: { (users) in
                    for i in users {
                        let config = Realm.Configuration(schemaVersion: 1)
                        do {
                            let realm = try Realm(configuration: config)
                            if (realm.object(ofType: ContactStruct.self, forPrimaryKey: i.id) == nil) && i.id != Session.current.currentUserID {
                                self.regristeredAddressBook.append(i)
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
        }
    }
    
    func grandSeach(searchText: String) {
        if searchText != "" {
            Request.users(withFullName: searchText, paginator: Paginator.limit(20, skip: 0), successBlock: { (paginator, users) in
                for i in users {
                    changeContactsRealmData().observeFirebaseContactReturn(contactID: Int(i.id), completion: { firebaseContact in
                        print("got emmm \(firebaseContact.isMessagingPrivate)")
                        if !firebaseContact.isMessagingPrivate {
                            self.grandUsers.append(i)
                            self.grandUsers.removeDuplicates()
                        }
                    })
                }
            }) { (error) in
                print("error searching for name user \(error.localizedDescription)")
            }
            
            Request.users(withPhoneNumbers: [searchText], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
                for i in users {
                    changeContactsRealmData().observeFirebaseContactReturn(contactID: Int(i.id), completion: { firebaseContact in
                        if !firebaseContact.isMessagingPrivate {
                            self.grandUsers.append(i)
                            self.grandUsers.removeDuplicates()
                        }
                    })
                }
            }) { (error) in
                print("error searching for phone number user \(error.localizedDescription)")
            }
        }
    }
}
