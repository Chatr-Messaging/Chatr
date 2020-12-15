//
//  AddNewContactView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/7/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import SDWebImageSwiftUI
import RealmSwift

struct addNewContactView: View {
    @EnvironmentObject var auth: AuthModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var dismissView: Bool
    @Binding var newDialogID: Int
    @State var searchText: String = ""
    @State var outputSearchText: String = ""
    @State var isLoading: Bool = false
    @State var grandUsers: [User] = []
    @State var regristeredAddressBook: [User] = []
    @ObservedObject var addressBook = AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self))
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    
                    //MARK: MAIN SEARCH BAR
                    VStack {
                        HStack {
                            Text("SEARCH NAME OR PHONE NUMBER:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .offset(y: 2)
                            Spacer()
                        }
                        
                        VStack(alignment: .center) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .padding(.leading, 15)
                                    .foregroundColor(.secondary)
                                
                                TextField("Search", text: $searchText, onCommit: {
                                    self.outputSearchText = self.searchText
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    self.isLoading = true
                                    self.grandSeach(searchText: self.outputSearchText)
                                })
                                .padding(EdgeInsets(top: 16, leading: 5, bottom: 16, trailing: 10))
                                .foregroundColor(.primary)
                                .font(.system(size: 18))
                                .lineLimit(1)
                                .keyboardType(.webSearch)
                                .onChange(of: self.searchText) { value in
                                    print("the value is: \(value)")
                                    if self.searchText.count >= 3 {
                                        self.grandSeach(searchText: self.searchText)
                                    } else {
                                        self.grandUsers.removeAll()
                                    }
                                }
                                
                                Button(action: {
                                    self.searchText = ""
                                    self.outputSearchText = ""
                                    self.grandUsers.removeAll()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal, 15)
                                .opacity(!self.searchText.isEmpty ? 1 : 0)
                                .disabled(!self.searchText.isEmpty ? false : true)
                            }.background(Color("buttonColor"))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        }.padding(.top, 5)
                    }.padding(.all)
                    
                    //MARK: Search Section
                    if !self.isLoading && self.grandUsers.count > 0 {
                        HStack {
                            Text("SEARCH RESULTS:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .offset(y: 2)
                                .padding(.top)
                            
                            Spacer()
                        }
                    }
                    
                    VStack(alignment: .center, spacing: 0) {
                        if !self.isLoading {
                            if self.grandUsers.count > 0 {
                                ForEach(self.grandUsers, id: \.self) { contact in
                                    NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromSearch, connectyContact: contact).environmentObject(self.auth).edgesIgnoringSafeArea(.all)) {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            HStack {
                                                WebImage(url: URL(string: PersistenceManager().getCubeProfileImage(usersID: contact) ?? ""))
                                                    .resizable()
                                                    .placeholder{ Image(systemName: "person.fill") }
                                                    .indicator(.activity)
                                                    .transition(.fade(duration: 0.25))
                                                    .scaledToFill()
                                                    .clipShape(Circle())
                                                    .frame(width: 45, height: 45, alignment: .center)
                                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 6)
                                                
                                                VStack(alignment: .leading) {
                                                    Text(contact.fullName ?? "No Name")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(Color.primary)
                                                    
                                                    Text(contact.phone?.format(phoneNumber: String(contact.phone?.dropFirst() ?? "")) ?? "")
                                                        .font(.subheadline)
                                                        .fontWeight(.regular)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .resizable()
                                                    .font(Font.title.weight(.bold))
                                                    .scaledToFit()
                                                    .frame(width: 7, height: 15, alignment: .center)
                                                    .foregroundColor(.secondary)
                                            }.padding(.horizontal)
                                            .padding(.vertical, 12.5)
                                            .contentShape(Rectangle())
                                            
                                            if self.grandUsers.last != contact {
                                                Divider()
                                                    .frame(width: Constants.screenWidth - 100)
                                            }
                                        }
                                    }.buttonStyle(changeBGButtonStyle())
                                    .background(Color.clear)
                                    .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                }
                            } else {
                                if self.outputSearchText.count > 0 || self.searchText.count > 3 {
                                    HStack {
                                        Spacer()
                                            Text("no users found")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.all)
                                        Spacer()
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                    Text("loading...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.all)
                                Spacer()
                            }
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.top, self.isLoading || (self.outputSearchText.count > 0 && self.grandUsers.count == 0) ? 50 : 0)
                    .padding(.bottom, self.grandUsers.count > 0 && !self.isLoading ? 60 : 15)
                    
                    //MARK: Regristered Section
                    if self.regristeredAddressBook.count != 0 {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Regristered:")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(self.regristeredAddressBook.count == 1 ? "\(self.regristeredAddressBook.count) regristered contact" : "\(self.regristeredAddressBook.count) regristered contacts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }.animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                        .padding(.horizontal)
                        .padding(.horizontal)
                        
                        VStack(alignment: .center, spacing: 0) {
                            ForEach(self.regristeredAddressBook, id: \.self) { contact in
                                if contact.id != Session.current.currentUserID {
                                    NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromSearch, connectyContact: contact).environmentObject(self.auth).edgesIgnoringSafeArea(.all)) {
                                        VStack(alignment: .trailing, spacing: 0) {
                                            HStack(alignment: .center) {
                                                ZStack(alignment: .center) {
                                                    Circle()
                                                        .frame(width: 35, height: 35, alignment: .center)
                                                        .foregroundColor(Color("bgColor"))
                                                    
                                                    WebImage(url: URL(string: PersistenceManager().getCubeProfileImage(usersID: contact) ?? ""))
                                                        .resizable()
                                                        .placeholder{ Image(systemName: "person.fill") }
                                                        .indicator(.activity)
                                                        .transition(.fade(duration: 0.25))
                                                        .scaledToFill()
                                                        .clipShape(Circle())
                                                        .frame(width: 45, height: 45, alignment: .center)
                                                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 6)
                                                }
                                                
                                                VStack(alignment: .leading) {
                                                    Text(contact.fullName ?? "No Name")
                                                        .font(.headline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(Color.primary)
                                                    
                                                    Text(contact.phone?.format(phoneNumber: String(contact.phone?.dropFirst() ?? "")) ?? "")
                                                        .font(.subheadline)
                                                        .fontWeight(.regular)
                                                        .foregroundColor(.secondary)
                                                }
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .resizable()
                                                    .font(Font.title.weight(.bold))
                                                    .scaledToFit()
                                                    .frame(width: 7, height: 15, alignment: .center)
                                                    .foregroundColor(.secondary)
                                            }.padding(.horizontal)
                                            .padding(.vertical, 12.5)
                                            .contentShape(Rectangle())
                                            
                                            if self.regristeredAddressBook.last != contact {
                                                Divider()
                                                    .frame(width: Constants.screenWidth - 100)
                                            }
                                        }
                                    }.buttonStyle(changeBGButtonStyle())
                                    .background(Color.clear)
                                }
                            }.animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }

                    //MARK: Address Book Section
                    if self.addressBook.filterAddressBook(text: self.searchText).count == 0 {
                        //MARK: SHOW Sync VIEW
                        if self.addressBook.results.count == 0 {
                            SyncAddressBook()
                                .animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                        }
                    } else {
                        if self.addressBook.filterAddressBook(text: self.searchText).count != 0 {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Address Book:")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)

                                    Text("\(self.addressBook.results.count) TOTAL CONTACTS")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.horizontal)
                        }

                        VStack {
                            if #available(iOS 14.0, *) {
                                LazyVStack {
                                    ForEach(self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }, id: \.self) { result in
                                        SelectableAddressBookContact(addressBook: result)
                                            .padding(.horizontal)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                        if self.addressBook.filterAddressBook(text: self.searchText).sorted { $0.name < $1.name }.last != result {
                                            Divider()
                                                .frame(width: Constants.screenWidth - 80)
                                                .offset(x: 35)
                                        }
                                    }
                                }.animation(.spring(response: 0.45, dampingFraction: 0.70, blendDuration: 0))
                                .padding(.vertical, 10)
                            } else {
                                // Fallback on earlier versions
                            }
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 35)
                    }
                    
                    Spacer()
                    
                    if !self.isLoading && self.grandUsers.count > 0 || (self.outputSearchText.count > 0 && self.grandUsers.count == 0) {
                        FooterInformation()
                    }
                }.padding(.top, 60)
                .onAppear() {
                    Request.registeredUsersFromAddressBook(withUdid: UIDevice.current.identifierForVendor?.uuidString, isCompact: false, successBlock: { (users) in
                        self.regristeredAddressBook.removeAll()
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
            }.navigationBarTitle("Add Contact", displayMode: .inline)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
            .resignKeyboardOnDragGesture()
            .navigationBarItems(leading:
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Done")
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    })
                )
        }
    }
    
    func grandSeach(searchText: String) {
        Request.users(withFullName: searchText, paginator: Paginator.limit(20, skip: 0), successBlock: { (paginator, users) in
            for i in users {
                if i.id != Session.current.currentUserID {
                    self.grandUsers.append(i)
                    self.grandUsers.removeDuplicates()
                }
            }
        }) { (error) in
            print("error searching for name user \(error.localizedDescription)")
        }
        
        Request.users(withPhoneNumbers: [searchText], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
            for i in users {
                if i.id != Session.current.currentUserID {
                    self.grandUsers.append(i)
                    self.grandUsers.removeDuplicates()
                }
            }
            self.isLoading = false
        }) { (error) in
            print("error searching for phone number user \(error.localizedDescription)")
        }
    }
}
