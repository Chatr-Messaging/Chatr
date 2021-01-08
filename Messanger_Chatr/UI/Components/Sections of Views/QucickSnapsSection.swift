//
//  QucickSnapsSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import ConnectyCube

struct QuickSnapsSection: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var quickSnapContacts = ContactsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ContactStruct.self))
    @Binding var viewState: QuickSnapViewingState
    @Binding var selectedQuickSnapContact: ContactStruct
    @Binding var emptyQuickSnaps: Bool
    @State var preLoading: Bool = false
    
    var body: some View {
        ZStack() {
            if self.quickSnapContacts.results.filter({ $0.hasQuickSnaped != false }).count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        //New Button
                        VStack(alignment: .center) {
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                self.viewState = .camera
                                self.selectedQuickSnapContact = ContactStruct()
                            }) {
                                VStack {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: Constants.btnSize / 4)
                                            .frame(width: Constants.quickSnapBtnSize, height: Constants.quickSnapBtnSize, alignment: .center)
                                            .foregroundColor(.clear)
                                            .background(Constants.snapPurpleGradient)
                                            .cornerRadius(Constants.quickSnapBtnSize / 4)
                                            .shadow(color: Color(.sRGB, red: 148 / 255, green: 109 / 255, blue: 245 / 255, opacity: 0.35), radius: 5, x: 0, y: 5)
                                        
                                        Image(systemName: "camera.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 24, alignment: .center)
                                            .padding(22)
                                            .foregroundColor(.white)
                                    }
                                }
                            }.buttonStyle(ClickButtonStyle())
                            .scaleEffect(UserDefaults.standard.bool(forKey: "localOpen") ? 0.85 : 1)
                            
                            Text("New")
                                .font(.caption)
                                .fontWeight(.none)
                                .foregroundColor(.secondary)
                                .offset(y: UserDefaults.standard.bool(forKey: "localOpen") ? -7 : -5)
                        }.padding(.trailing, 5)
                        .padding(.leading, UserDefaults.standard.bool(forKey: "localOpen") ? 20 : 0)
                        .offset(y: UserDefaults.standard.bool(forKey: "localOpen") ? (UIDevice.current.hasNotch ? 5 : 0) : 0)
                        
                        Divider()
                            .padding(.bottom, 30)
                            .scaleEffect(UserDefaults.standard.bool(forKey: "localOpen") ? 0.85 : 1)
                            .offset(y: UserDefaults.standard.bool(forKey: "localOpen") ? (UIDevice.current.hasNotch ? 5 : 0) : 0)
                        
                        //Received List
                        HStack(spacing: 0) {
                            ForEach(self.quickSnapContacts.results.sorted(by: {$0.quickSnaps.count > $1.quickSnaps.count}).filter({ $0.hasQuickSnaped != false }), id:\.self) { snap in
                                if snap.hasQuickSnaped {
                                    QuickSnapCell(viewState: self.$viewState, quickSnap: snap, selectedQuickSnapContact: self.$selectedQuickSnapContact)
                                        .offset(x: (self.quickSnapContacts.results.sorted(by: {$0.quickSnaps.count > $1.quickSnaps.count}).filter({ $0.hasQuickSnaped != false }).first != nil) ? -4 : 0)
                                }
                            }
                        }.padding(.leading, 5)
                    }.padding(.horizontal)
                }.frame(height: self.emptyQuickSnaps ? 70 : 0)
                .onAppear() {
                    self.emptyQuickSnaps = false
                    print("quick snaps is NOT empty: \(self.emptyQuickSnaps)")
                }
            } else {
                Text("")
                    .onAppear() {
                        if self.auth.isUserAuthenticated != .signedOut {
                            self.emptyQuickSnaps = true
                            changeContactsRealmData().updateContacts(contactList: Chat.instance.contactList?.contacts ?? [], completion: { _ in
                                print("done refreshing quick snap contacts!... just in case")
                            })
                            print("empty quick snaps so try to refresh to dubble check: \(self.emptyQuickSnaps)")
                        }
                    }
//                Button(action: {
//                    changeContactsRealmData().observeQuickSnaps()
//                }, label: {
//                    Text("Reload Quick Snaps")
//                        .font(.none)
//                        .fontWeight(.medium)
//                }).buttonStyle(MainButtonStyle())
//                .frame(width: 185, height: 45, alignment: .center)
//                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
//                .opacity(self.preLoading ? 1 : 0)
//                .onAppear() {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
//                        self.preLoading.toggle()
//                    }
//                }
            }
        }
    }
}
