//
//  EditGroupDialogView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 1/27/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI
import ConnectyCube
import FirebaseDatabase

struct EditGroupDialogView: View {
    @EnvironmentObject var auth: AuthModel
    @Binding var dialogModel: DialogStruct
    @State var fullNameText: String = ""
    @State var bioText: String = "Description"
    @State var bioHeight: CGFloat = 0
    @State var loadingSave: Bool = false
    @State var keyboardHeight: CGFloat = 0
    @State var didSave: Bool = true
    @State var username: String = ""
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    //MARK: Name & Bio Section
                    HStack {
                        Text("NAME & DESCRIPTION:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    self.styleBuilder(content: {
                        //FullName Section
                        VStack {
                            HStack {
                                Image(systemName: "person.3.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.primary)
                                    .frame(width: 30, height: 24, alignment: .center)
                                
                                TextField("Full Name", text: self.$fullNameText)
                                    .foregroundColor(.primary)
                                    .autocapitalization(.words)
                                    .onChange(of: self.fullNameText) { _ in
                                        self.didSave = false
                                    }

                                Spacer()
                            }.padding(.horizontal)
                            .padding(.vertical, 6)
                            .padding(.top, 2)
                            .contentShape(Rectangle())

                            Divider()
                                .frame(width: Constants.screenWidth - 70)
                                .offset(x: 30)
                        }.onAppear() {
                            self.fullNameText = self.dialogModel.fullName
                        }
                        
                        //Bio Section
                        VStack() {
                            HStack(alignment: .top) {
                                VStack() {
                                    Image(systemName: "note.text")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.primary)
                                        .frame(width: 20, height: 20, alignment: .center)
                                        .padding(.trailing, 5)
                                    
                                    Text("\(220 - self.bioText.count)")
                                        .font(.subheadline)
                                        .fontWeight(self.bioText.count > 220 ? .bold : .none)
                                        .foregroundColor(self.bioText.count > 220 ? .red : .secondary)
                                        .padding(.trailing, 5)
                                }
                                
                                ZStack(alignment: .topLeading) {
                                    ResizableTextField(height: self.$bioHeight, text: self.$bioText)
                                        .padding(.horizontal, 2.5)
                                        .padding(.trailing, 5)
                                        .font(.none)
                                        .foregroundColor(self.bioText != "Bio" ? .primary : .secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(5)
                                        .offset(x: -7, y: -10)
                                        .onChange(of: self.bioText) { _ in
                                            self.didSave = false
                                        }
                                    
                                    Text("Bio")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.secondary)
                                        .opacity(self.bioText != "" ? 0 : 1)
                                        .padding(.leading, 5)
                                }
                            }
                        }.padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(height: 100)
                        .onAppear() {
                            self.bioText = self.dialogModel.bio
                        }
                    })
                    
                    //MARK: Footer Section
                    FooterInformation()
                        .padding(.vertical, 40)
                    
                }.padding(.top, 70)
                .resignKeyboardOnDragGesture()
            }.frame(height: Constants.screenHeight - 50 - self.keyboardHeight)
            .animation(.spring())
        }.frame(height: Constants.screenHeight)
        .background(Color("bgColor"))
        .edgesIgnoringSafeArea(.all)
        .navigationBarTitle("Edit Group", displayMode: .inline)
        .navigationBarItems(trailing:
            Button(action: {
                UIApplication.shared.endEditing(true)
                self.saveGroupInfo()
            }) {
                Text((220 - self.bioText.count) > 220 && loadingSave ? "Saving" : self.didSave ? "Saved" : "Save")
                    .foregroundColor((220 - self.bioText.count) > 220 && loadingSave ? .secondary : self.didSave ? .secondary : .blue)
                    .fontWeight((220 - self.bioText.count) > 220 && loadingSave ? .none : self.didSave ? .none : .medium)
            }.disabled((220 - self.bioText.count) > 220 && loadingSave ? true : self.didSave ? true : false)
        ).onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (data) in
                DispatchQueue.main.async {
                    let height1 = data.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                    self.keyboardHeight = height1.cgRectValue.height + 10
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
                self.keyboardHeight = 0
            }
        }
    }
    
    func saveGroupInfo() {
        if self.loadingSave == false {
            self.loadingSave = true
            
            let parameters = UpdateChatDialogParameters()
            parameters.name = self.fullNameText
            parameters.dialogDescription = self.bioText

            Request.updateDialog(withID: self.dialogModel.id, update: parameters, successBlock: { (updatedDialog) in
                changeDialogRealmData.shared.updateDialogNameDescription(name: self.fullNameText, description: self.bioText, dialogID: self.dialogModel.id)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.loadingSave = false
                self.didSave = true
                //changeDialogRealmData.shared.fetchDialogs(completion: { _ in })
            }) { (error) in
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self.loadingSave = false
                self.didSave = false
            }
        }
    }
    
    func styleBuilder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .center) {
            VStack(spacing: 0) {
                content()
            }.padding(.vertical, 10)
        }.background(Color("buttonColor"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
}
