//
//  StorageView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 8/22/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI

struct storageView: View {
    @EnvironmentObject var auth: AuthModel
    @State var clearData: Bool = false
    @State var loadingClearData: Bool = false
    //@State var removeDialogData: Bool = false
    //@State var removeContactsData: Bool = false
    //@State var removeMessagesData: Bool = false
    //@State var removeQuickSnapsData: Bool = false

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    VStack(alignment: .center) {
                        
                        //Percentage Section
                        VStack {
                            HStack {
                                ZStack {
                                    Circle()
                                        .trim(from: 0, to: 1)
                                        .stroke(Color.primary.opacity(0.15), style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                                        .frame(width: 70, height: 70, alignment: .center)
                                    
                                    Circle()
                                        .trim(from: CGFloat(1 - self.checkRealmFileMBSize()), to: 1)
                                        .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                                        .frame(width: 70, height: 70, alignment: .center)
                                        .rotationEffect(.degrees(90))
                                        .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                        .shadow(color: Color.orange.opacity(0.4), radius: 6, x: 0, y: 0)
                                    
                                    Text("\(String(format: "%.1f", (self.checkRealmFileMBSize() * 100)))%")
                                        .font(.system(size: 20))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                }.offset(x: -5)
                                
                                VStack(alignment: .leading) {
                                    Text("Storage")
                                        .font(.system(size: 26))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("\(Int(1000 - (self.checkRealmFileSize() / 1000)))KB remaining")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                }.padding(.horizontal, 5)
                                
                                Spacer()
                            }.padding(.horizontal, 20)
                            
                        }.padding(.vertical, 15)
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    
                    HStack(alignment: .center) {
                        Text("1 megabyte recommended limit. you are not required to modify or delete data.")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }.padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    
                    //MARK: Delete Data Section
                    HStack {
                        Text("DATA:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }
                    
                    VStack(alignment: .center) {
                        VStack {
                            Button(action: {
                                self.loadingClearData = true
                                SDImageCache.shared.clearMemory()
                                SDImageCache.shared.clearDisk(onCompletion: nil)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    self.loadingClearData = false
                                    self.clearData = true
                                }
                            }) {
                                HStack {
                                    Text(self.loadingClearData ? self.clearData ? "Cleaned Data" : "Cleaning..." : "Clean All Data")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(!self.loadingClearData ? .primary : .secondary)

                                    Spacer()
                                    Image(systemName: self.clearData ? "checkmark" : "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: self.clearData ? 15 : 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.all)
                            }.buttonStyle(changeBGButtonStyle())
                            .disabled(self.clearData ? true : false)
                                                    
                            /*
                            VStack {
                                Button(action: {
                                    print("delete all Dialog data")
                                    changeDialogRealmData.shared.removeAllDialogs()
                                    self.removeDialogData = true
                                }) {
                                    HStack {
                                        Text(self.removeDialogData ? "Removed" : "Remove Dialog Data")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(!self.removeDialogData ? .primary : .secondary)

                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                                .disabled(self.removeDialogData ? true : false)

                                Divider()
                                    .frame(width: Constants.screenWidth - 50)
                                    .offset(x: 10)
                            }.padding(.vertical, 5)
                            
                            //MARK: Contacts Section
                            VStack {
                                Button(action: {
                                    print("delete all Contacts data")
                                    changeContactsRealmData.shared.removeAllContacts()
                                    self.removeContactsData = true
                                }) {
                                    HStack {
                                        Text(self.removeContactsData ? "Removed" : "Remove Contact Data")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(!self.removeContactsData ? .primary : .secondary)

                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                                .disabled(self.removeContactsData ? true : false)

                                Divider()
                                    .frame(width: Constants.screenWidth - 50)
                                    .offset(x: 10)
                            }.padding(.vertical, 5)
                            
                            //MARK: Messages Section
                            VStack {
                                Button(action: {
                                    print("delete all Message data")
                                    changeMessageRealmData.shared.removeAllMessages(completion: { _ in })
                                    self.removeMessagesData = true
                                }) {
                                    HStack {
                                        Text(self.removeMessagesData ? "Removed" : "Remove Contact Data")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(!self.removeMessagesData ? .primary : .secondary)

                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                                .disabled(self.removeMessagesData ? true : false)

                                Divider()
                                    .frame(width: Constants.screenWidth - 50)
                                    .offset(x: 10)
                            }.padding(.vertical, 5)
                            
                            //MARK: Quick Snap Section
                            VStack {
                                Button(action: {
                                    print("delete all Quick Snap data")
                                    changeQuickSnapsRealmData.shared.removeAllQuickSnaps()
                                    self.removeQuickSnapsData = true
                                }) {
                                    HStack {
                                        Text(self.removeQuickSnapsData ? "Removed" : "Remove Quick Snap Data")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(!self.removeQuickSnapsData ? .primary : .secondary)

                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .font(Font.title.weight(.bold))
                                            .scaledToFit()
                                            .frame(width: 7, height: 15, alignment: .center)
                                            .foregroundColor(.secondary)
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.buttonStyle(PlainButtonStyle())
                                .disabled(self.removeQuickSnapsData ? true : false)
                            }.padding(.vertical, 5)
                            */
                            
                        }
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    
                    HStack(alignment: .center) {
                        Text("cleaning data filters out old & unused data.")
                            .font(.caption)
                            .fontWeight(.none)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }.padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                    
                    FooterInformation()
                        .padding(.vertical, 50)
                }.padding(.top, 110)
                .frame(width: Constants.screenWidth)
            }.navigationBarTitle("Data & Storage", displayMode: .automatic)
            .background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    func checkRealmFileSize() -> Double {
        if let realmPath = Realm.Configuration.defaultConfiguration.fileURL?.relativePath {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath:realmPath)
                if let fileSize = attributes[FileAttributeKey.size] as? Double {

                    print(fileSize)
                    return fileSize
                }
            }
            catch (let error) {
                print("FileManager Error: \(error)")
            }
        }
        return Double()
    }
    
    func checkRealmFileMBSize() -> Double {
        var number = Double()
        number = self.checkRealmFileSize() / 1000000
        
        return number
    }
}
