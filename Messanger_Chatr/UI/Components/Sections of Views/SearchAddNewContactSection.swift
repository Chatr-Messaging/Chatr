//
//  SearchAddNewContactSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 7/1/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import SDWebImageSwiftUI
import RealmSwift

struct SearchAddNewContactSection: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var searchText: String
    @Binding var grandUsers: [User]
    @Binding var outputSearchText: String
    @Binding var isLoading: Bool
    @Binding var newDialogID: Int
    @Binding var dismissView: Bool
    
    var body: some View {
        //MARK: MAIN SEARCH BAR
        VStack {
            VStack {
                miniHeader(title: "SEARCH NAME OR PHONE NUMBER:", doubleIndent: false)
                
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
                            .onChange(of: self.searchText) { _ in
                                if self.searchText.count >= 2 {
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
                }.padding(.top, 2)
            }.padding(.all)
            
            //MARK: Search Section
            if !self.isLoading && self.grandUsers.count > 0 {
                miniHeader(title: "SEARCH RESULTS:")
                    .padding(.top)
            }
            
            LazyVStack(alignment: .center, spacing: 0) {
                if !self.isLoading {
                    if self.grandUsers.count > 0 {
                        ForEach(self.grandUsers.indices, id: \.self) { contact in
                            NavigationLink(destination: VisitContactView(newMessage: self.$newDialogID, dismissView: self.$dismissView, viewState: .fromSearch, connectyContact: self.grandUsers[contact]).environmentObject(self.auth).edgesIgnoringSafeArea(.all)) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack {
                                        if let avatar = self.grandUsers[contact].avatar ?? PersistenceManager.shared.getCubeProfileImage(usersID: self.grandUsers[contact]), avatar != "" {
                                            WebImage(url: URL(string: avatar))
                                                .resizable()
                                                .placeholder{ Image("empty-profile").resizable().frame(width: 45, height: 45, alignment: .center).scaledToFill() }
                                                .indicator(.activity)
                                                .transition(.fade(duration: 0.25))
                                                .scaledToFill()
                                                .clipShape(Circle())
                                                .frame(width: 45, height: 45, alignment: .center)
                                                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 6)
                                        } else {
                                            ZStack {
                                                Circle()
                                                    .frame(width: 45, height: 45, alignment: .center)
                                                    .foregroundColor(Color("bgColor"))
                                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 6)
                                                
                                                Text("".firstLeters(text: self.grandUsers[contact].fullName ?? "No Name"))
                                                    .font(.system(size: 20))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(self.grandUsers[contact].fullName ?? "No Name")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color.primary)
                                            
                                            Text("last online \(self.grandUsers[contact].lastRequestAt?.getElapsedInterval(lastMsg: "moments") ?? "recently") ago")
                                                .font(.caption)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        
                                        if self.isUserNotContact(id: self.grandUsers[contact].id) {
                                            Button(action: {
                                                Chat.instance.confirmAddContactRequest(UInt(self.grandUsers[contact].id)) { (error) in
                                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                                    self.grandUsers.removeAll(where: { $0.id == self.grandUsers[contact].id })
                                                    self.auth.sendPushNoti(userIDs: [NSNumber(value: self.grandUsers[contact].id)], title: "Contact Request", message: "\(self.auth.profile.results.first?.fullName ?? "A user") sent you a contact request")
                                                }
                                            }) {
                                                Text("Add")
                                                    .fontWeight(.medium)
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 15)
                                                    .background(Color.blue)
                                                    .cornerRadius(10)
                                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                                            }
                                        }
                                        
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                        .padding(.vertical, 12.5)
                                        .contentShape(Rectangle())
                                    
                                    if self.grandUsers.last != self.grandUsers[contact] {
                                        Divider()
                                            .frame(width: Constants.screenWidth - 100)
                                    }
                                }
                            }.buttonStyle(changeBGButtonStyle())
                                .background(Color.clear)
                                .simultaneousGesture(TapGesture()
                                                        .onEnded { _ in
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                })
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
            }.animation(.spring(response: 0.25, dampingFraction: 0.70, blendDuration: 0))
            .background(Color("buttonColor"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            .padding(.horizontal)
            .padding(.top, self.isLoading || (self.outputSearchText.count > 0 && self.grandUsers.count == 0) ? 50 : 0)
            .padding(.bottom, self.grandUsers.count > 0 && !self.isLoading ? 60 : 15)
        }
    }
    
    func grandSeach(searchText: String) {
        Request.users(withFullName: searchText, paginator: Paginator.limit(20, skip: 0), successBlock: { (paginator, users) in
            for i in users {
                if i.id != Session.current.currentUserID {
                    withAnimation {
                        self.grandUsers.append(i)
                        self.grandUsers.removeDuplicates()
                    }
                }
            }
            
            Request.users(withPhoneNumbers: [searchText], paginator: Paginator.limit(5, skip: 0), successBlock: { (paginator, users) in
                for i in users {
                    if i.id != Session.current.currentUserID {
                        withAnimation {
                            self.grandUsers.append(i)
                            self.grandUsers.removeDuplicates()
                        }
                    }
                }
                self.isLoading = false
            }) { _ in }
        }) { _ in }
    }
    
    func isUserNotContact(id: UInt) -> Bool {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            if let contact = realm.object(ofType: ContactStruct.self, forPrimaryKey: id) {
                guard contact.id != Session.current.currentUserID && contact.isMyContact == false else {
                    return false
                }
                
                return true
            } else {
                for i in Chat.instance.contactList?.pendingApproval ?? [] {
                    if i.userID == id {
                        return false
                    }
                }
                
                guard !(self.auth.profile.results.first?.contactRequests.contains(Int(id)) ?? false) else {
                    return false
                }
                
                return true
            }
        } catch {
            return false
        }
    }
}
