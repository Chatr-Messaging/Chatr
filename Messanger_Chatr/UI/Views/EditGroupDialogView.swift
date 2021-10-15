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
import SDWebImageSwiftUI

struct EditGroupDialogView: View {
    @EnvironmentObject var auth: AuthModel
    @StateObject var imagePicker = KeyboardCardViewModel()
    @Binding var dialogModel: DialogStruct
    @State var fullNameText: String = ""
    @State var bioText: String = "Description"
    @State var bioHeight: CGFloat = 0
    @State var loadingSave: Bool = false
    @State var keyboardHeight: CGFloat = 0
    @State var didSave: Bool = true
    @State var username: String = ""
    @State var groupImage: Image? = nil
    @State var coverImage: Image? = nil
    @State var avatarDownload: CGFloat = 0.0
    @State var coverPhotoDownload: CGFloat = 0.0
    @State var canMembersType: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var showCoverImagePicker: Bool = false

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack() {
                    //MARK: Public Avatar and Cover Photo
                    if self.dialogModel.dialogType == "public" {
                        HStack {
                            Text("AVATAR & COVER PHOTO:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .offset(y: 2)
                            Spacer()
                        }.padding(.top, 5)
                        .sheet(isPresented: self.$showCoverImagePicker) {
                            ImagePicker22(sourceType: .photoLibrary) { (imageUrl, img) in
                                if let newImg = img {
                                    self.coverImage = Image(uiImage: newImg)
                                }
                                
                                self.auth.uploadFile(imageUrl, completionHandler: { coverId in
                                    DispatchQueue.main.async {
                                        let databaseRef = Database.database().reference().child("Marketplace/public_dialogs").child(self.dialogModel.id)
                                        let fullImgLink = Constants.uploadcareBaseUrl + coverId + Constants.uploadcareStandardTransform

                                        databaseRef.updateChildValues(["cover_photo" : "\(fullImgLink)"], withCompletionBlock: { (_,_) in
                                            self.auth.dialogs.updateDialogCoverPhoto(coverPhoto: "\(imageUrl)", dialogID: self.dialogModel.id)
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        })
                                    }
                                })
                            }
                        }
                        
                        //Cover Image
                        VStack(alignment: .center, spacing: 0) {
                            ZStack(alignment: .bottom) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation {
                                        self.showCoverImagePicker.toggle()
                                    }
                                }, label: {
                                    ZStack {
                                        if (coverImage != nil) {
                                            coverImage?.resizable().aspectRatio(contentMode: .fill).frame(width: Constants.screenWidth - 30, height: 160).clipped()
                                        } else if dialogModel.coverPhoto != "" {
                                            WebImage(url: URL(string: dialogModel.coverPhoto))
                                                .resizable()
                                                .placeholder{ Image(systemName: "photo.on.rectangle.angled").resizable().frame(width: 35, height: 32, alignment: .center).scaledToFill().offset(y: -20) }
                                                .indicator(.activity)
                                                .scaledToFill()
                                                .frame(width: Constants.screenWidth - 32, height: 160, alignment: .center)
                                                .clipped()
                                                .offset(y: -20)
                                        } else {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 0)
                                                    .frame(width: Constants.screenWidth - 32, height: 160, alignment: .center)
                                                    .overlay(
                                                            RoundedRectangle(cornerRadius: 16)
                                                                .stroke(Color.gray, style: StrokeStyle(lineWidth: 2.5, dash: [20, 5]))
                                                                .padding(10)
                                                        )
                                                    .foregroundColor(Color("buttonColor"))

                                                VStack(spacing: 2.5) {
                                                    Image(systemName: "photo.on.rectangle.angled")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .foregroundColor(Color.secondary)
                                                        .frame(width: 36, height: 34, alignment: .center)

                                                    Text("cover photo")
                                                        .font(.caption)
                                                        .fontWeight(.regular)
                                                        .foregroundColor(.secondary)
                                                }.offset(y: -22)
                                            }
                                        }
                                        
                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                                .frame(width: 20, height: 20)
                                                .opacity(0.35)

                                            Circle()
                                                .trim(from: 1.0 - self.coverPhotoDownload, to: 1.0)
                                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                                .frame(width: 20, height: 20)
                                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                                                .rotationEffect(.init(degrees: -90))
                                                .animation(Animation.linear(duration: 0.1))
                                        }.opacity(self.coverPhotoDownload == 0.0 || self.coverPhotoDownload == 1.0 ? 0 : 1)
                                    }
                                }).padding(.bottom, 30)
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    withAnimation {
                                        self.showImagePicker.toggle()
                                    }
                                }, label: {
                                    ZStack {
                                        if (groupImage != nil) {
                                            groupImage?.resizable().aspectRatio(contentMode: .fill).frame(width: 80, height: 80).cornerRadius(16)
                                                .shadow(color: Color("buttonShadow"), radius: 12, x: 0, y: 5)
                                        } else if dialogModel.avatar != "" {
                                            WebImage(url: URL(string: dialogModel.avatar))
                                                .resizable()
                                                .placeholder{ Image("empty-profile").resizable().frame(width: 80, height: 80, alignment: .center).scaledToFill() }
                                                .indicator(.activity)
                                                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                                .scaledToFill()
                                                .clipped()
                                                .frame(width: 80, height: 80, alignment: .center)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .shadow(color: Color("buttonShadow"), radius: 12, x: 0, y: 5)
                                        } else {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 20)
                                                    .frame(width: 80, height: 80, alignment: .center)
                                                    .foregroundColor(Color("buttonColor"))

                                                Image(systemName: "person.crop.circle.badge.plus")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(Color.secondary)
                                                    .frame(width: 45, height: 45, alignment: .center)
                                                    .offset(x: -3)
                                            }.shadow(color: Color("buttonShadow"), radius: 12, x: 0, y: 5)
                                        }

                                        ZStack {
                                            Circle()
                                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                                .frame(width: 20, height: 20)
                                                .opacity(0.35)

                                            Circle()
                                                .trim(from: 1.0 - self.avatarDownload, to: 1.0)
                                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                                .frame(width: 20, height: 20)
                                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 0)
                                                .rotationEffect(.init(degrees: -90))
                                                .animation(Animation.linear(duration: 0.1))
                                        }.opacity(self.avatarDownload == 0.0 || self.avatarDownload == 1.0 ? 0 : 1)
                                    }
                                }).offset(y: -12)
                            }
                            Divider()
                                .frame(width: Constants.screenWidth - 70)
                                .offset(x: 10)
                        
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation {
                                    self.showImagePicker.toggle()
                                }
                            }, label: {
                                HStack {
                                    Text("Select Avatar")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.blue)
                                        .padding(.leading)
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 14)
                            }).buttonStyle(changeBGButtonStyle())

                            Divider()
                                .frame(width: Constants.screenWidth - 70)
                                .offset(x: 10)
                            
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                withAnimation {
                                    self.showCoverImagePicker.toggle()
                                }
                            }, label: {
                                HStack {
                                    Text("Select Cover Photo")
                                        .font(.none)
                                        .fontWeight(.none)
                                        .foregroundColor(.blue)
                                        .padding(.leading)

                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                }.padding(.horizontal)
                                .padding(.vertical, 14)
                            }).buttonStyle(changeBGButtonStyle())
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .sheet(isPresented: self.$showImagePicker) {
                            ImagePicker22(sourceType: .photoLibrary) { (imageUrl, img) in
                                if let newImg = img {
                                    self.groupImage = Image(uiImage: newImg)
                                }
                                
                                self.auth.uploadFile(imageUrl, completionHandler: { avatarId in
                                    DispatchQueue.main.async {
                                        let fullImgLink = Constants.uploadcareBaseUrl + avatarId + Constants.uploadcareStandardTransform
                                        
                                        self.setGroupAvatar(avatarLink: fullImgLink, completion: { didUpdate in
                                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        })
                                    }
                                })
                            }
                        }
                    }
                    
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
                                    .disableAutocorrection(true)
                                    .font(.system(size: 20, weight: self.fullNameText.count > 0 ? .semibold : .regular, design: .default))
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
                                    ResizableTextField(imagePicker: self.imagePicker, height: self.$bioHeight, text: self.$bioText)
                                        .padding(.horizontal, 2.5)
                                        .padding(.trailing, 5)
                                        .font(.none)
                                        .foregroundColor(self.bioText != "Bio" ? .primary : .secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(6)
                                        .offset(x: -7, y: -8)
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
                        .padding(.top, 8)
                        .frame(height: 100)
                        .onAppear() {
                            self.bioText = self.dialogModel.bio
                        }
                    })
                    
                    //MARK: Settings Section
                    if self.dialogModel.dialogType == "public" {
                        HStack {
                            Text("SETINGS:")
                                .font(.caption)
                                .fontWeight(.regular)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.horizontal)
                                .offset(y: 2)
                            Spacer()
                        }.padding(.top, 10)
                        
                        self.styleBuilder(content: {
                            HStack {
                                Image(systemName: "keyboard")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .foregroundColor(.primary)

                                Toggle("Member Contributions", isOn: self.$canMembersType)
                                    .padding(.leading, 5)
                                    .onReceive([self.canMembersType].publisher.first()) { (value) in
                                        Database.database().reference().child("Marketplace").child("public_dialogs").child("\(self.dialogModel.id)").updateChildValues(["canMembersType" : value])
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                            }.padding(.horizontal)
                            .padding(.vertical, 2.5)
                            .onAppear() {
                                self.canMembersType = self.dialogModel.canMembersType
                            }
                        })
                        
                        HStack(alignment: .center) {
                            Text("member contributions allows any subscribed member to send messages and media along with admins")
                                .font(.caption)
                                .fontWeight(.none)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }.padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
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
                Text(self.bioText.count > 220 ? "error" : loadingSave ? "Saving" : self.didSave ? "Saved" : "Save")
                    .foregroundColor(self.bioText.count > 220 || loadingSave ? .secondary : self.didSave ? .secondary : .blue)
                    .fontWeight(self.bioText.count > 220 || loadingSave ? .none : self.didSave ? .none : .medium)
            }.disabled(self.bioText.count > 220 || loadingSave ? true : self.didSave ? true : false)
        ).onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (data) in
                let height1 = data.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                self.keyboardHeight = height1.cgRectValue.height + 10
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
                self.keyboardHeight = 0
            }
        }.onDisappear() {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

    func saveGroupInfo() {
        guard self.bioText.count < 220 else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)

            return
        }
        if self.loadingSave == false {
            self.loadingSave = true
            
            let parameters = UpdateChatDialogParameters()
            parameters.name = self.fullNameText
            parameters.dialogDescription = self.bioText

            Request.updateDialog(withID: self.dialogModel.id, update: parameters, successBlock: { (updatedDialog) in
                let databaseRef = Database.database().reference().child("Marketplace/public_dialogs").child(self.dialogModel.id)

                databaseRef.updateChildValues(["canMembersType" : self.canMembersType, "description" : updatedDialog.dialogDescription ?? "", "name" : updatedDialog.name ?? "no name"], withCompletionBlock: { (_,_) in
                    self.auth.dialogs.updateDialogNameDescription(name: updatedDialog.name ?? "no name", description: updatedDialog.dialogDescription ?? "", membersType: self.canMembersType, dialogID: self.dialogModel.id)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.loadingSave = false
                    self.didSave = true
                })
            }) { (error) in
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self.loadingSave = false
                self.didSave = false
            }
        }
    }
    
    func setGroupAvatar(avatarLink: String, completion: @escaping (Bool) -> Void) {
        let parameters = UpdateChatDialogParameters()
        parameters.photo = avatarLink
        
        Request.updateDialog(withID: self.dialogModel.id, update: parameters, successBlock: { (updatedDialog) in
            let databaseRef = Database.database().reference().child("Marketplace/public_dialogs").child(self.dialogModel.id)
            databaseRef.updateChildValues(["avatar" : updatedDialog.photo ?? avatarLink], withCompletionBlock: { (_,_) in
                self.auth.dialogs.updateDialogAvatar(avatar: updatedDialog.photo ?? avatarLink, dialogID: self.dialogModel.id)
                completion(true)
            })
        }, errorBlock: { (error) in
            completion(false)
        })
    }
    
    func setGroupCoverImage(image: UIImage, completion: @escaping (Bool) -> Void) {
        let image = image
        let data = image.jpegData(compressionQuality: 0.5)
        
        Request.uploadFile(with: data!, fileName: "\(self.dialogModel.fullName)s_coverImg", contentType: "image/jpeg", isPublic: true, progressBlock: { (progress) in
            self.coverPhotoDownload = CGFloat(progress)
        }, successBlock: { (blob) in
            let parameters = UpdateChatDialogParameters()
            parameters.photo = blob.uid
            let databaseRef = Database.database().reference().child("Marketplace").child(self.dialogModel.id)
            databaseRef.updateChildValues(["cover_photo" : blob.uid ?? ""], withCompletionBlock: { (_,_) in
                self.auth.dialogs.updateDialogCoverPhoto(coverPhoto: blob.uid ?? "", dialogID: self.dialogModel.id)
                completion(true)
            })
        }) { (error) in
            completion(false)
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
