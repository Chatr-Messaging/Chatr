//
//  EditProfileView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/16/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI
import ConnectyCube
import FirebaseDatabase
import Uploadcare
import PopupView

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var viewModel = EditProfileViewModel()
    @StateObject var imagePicker = KeyboardCardViewModel()
    @State var fullNameText: String = ""
    @State var bioText: String = "Bio"
    @State var bioHeight: CGFloat = 0
    @State var phoneText: String = ""
    @State var emailText: String = ""
    @State var websiteText: String = ""
    @State var twitterText: String = ""
    @State var facebookText: String = ""
    @State var loadingSave: Bool = false
    @State var keyboardHeight: CGFloat = 0
    @State var errorEmail: Bool = false
    @State var didSave: Bool = true
    @State var showImagePicker: Bool = false
    @State private var image: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State var username: String = ""
    @State var presentAuth = false
    @State var instagramApi = InstagramApi.shared
    @State var receivedNotification: Bool = false

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    //MARK: Profile Picture Section
                    HStack {
                        Text("PROFILE PICTURE:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    //Profile Image
                    VStack(alignment: .center) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            withAnimation {
                                self.showImagePicker.toggle()
                            }
                        }, label: {
                            VStack {
                                HStack(alignment: .center) {
                                    Spacer()
                                    VStack(alignment: .center) {
                                        WebImage(url: URL(string: self.auth.profile.results.first?.avatar ?? ""))
                                            .resizable()
                                            .placeholder{ Image("empty-profile").resizable().frame(width: 80, height: 80, alignment: .center).scaledToFill() }
                                            .indicator(.activity)
                                            .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                            .scaledToFill()
                                            .frame(width: 80, height: 80, alignment: .center)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.20), radius: 12, x: 0, y: 8)
                                        
                                        Text("Change Profile Picture")
                                            .font(.none)
                                            .fontWeight(.none)
                                            .foregroundColor(.blue)
                                            .padding(.top, 10)
                                    }.padding(.horizontal)
                                    .offset(x: 20)
                                    .contentShape(Rectangle())
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .resizable()
                                        .font(Font.title.weight(.bold))
                                        .scaledToFit()
                                        .frame(width: 7, height: 15, alignment: .center)
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }.padding(.vertical, 10)
                        }).buttonStyle(changeBGButtonStyle())
                    }.background(Color("buttonColor"))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                    .sheet(isPresented: self.$showImagePicker) {
                        ImagePicker22(sourceType: .savedPhotosAlbum) { (imageUrl, _) in
                            self.auth.uploadFile(imageUrl, completionHandler: { imageId in
                                DispatchQueue.main.async {
                                    self.showImagePicker = false
                                    self.auth.setUserAvatar(imageId: imageId, oldLink: self.auth.profile.results.first?.avatar ?? "", completion: { success in
                                        print("DONEEE SETTING UP URL! \(success)")
                                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                                        auth.notificationtext = "Successfully updated profile image"
                                        NotificationCenter.default.post(name: NSNotification.Name("NotificationAlert"), object: nil)
                                    })
                                }
                            })
                        }
                    }
                    
                    //MARK: Name & Bio Section
                    HStack {
                        Text("NAME & BIO:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    .sheet(isPresented: self.$presentAuth, onDismiss: {
                        self.viewModel.pullInstagramUser(completion: { username in
                            self.username = username
                        })
                    }) {
                        InstagramWebView(presentAuth: self.$presentAuth, instagramApi: self.$instagramApi)
                    }
                    
                    self.viewModel.styleBuilder(content: {
                        //FullName Section
                        VStack {
                            HStack {
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                TextField("Full Name", text: $fullNameText)
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
                            self.fullNameText = self.auth.profile.results.first?.fullName ?? ""
                        }
                        
                        //Bio Section
                        VStack() {
                            HStack(alignment: .top) {
                                VStack() {
                                    Image(systemName: "note.text")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.secondary)
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
                                        .onChange(of: self.bioText) { bioText in
                                            if bioText.count >= 225 {
                                                self.bioText.removeLast()
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                            }
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
                            self.bioText = self.auth.profile.results.first?.bio ?? "Bio"
                        }
                    })
                    
                    //MARK: Details Section
                    HStack {
                        Text("DETAILS:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    self.viewModel.styleBuilder(content: {
                        //Phone Number Section
                        VStack {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Text("\(self.phoneText.format(phoneNumber: String(self.phoneText.dropFirst().dropFirst())))")
                                    .font(.none)
                                    .foregroundColor(.secondary)
                                    
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())

                            Divider()
                                .frame(width: Constants.screenWidth - 70)
                                .offset(x: 30)
                        }.onAppear {
                            self.phoneText = UserDefaults.standard.string(forKey: "phoneNumber") ?? ""
                        }
                        
                        //Email Address Section
                        VStack {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                TextField("Email Address", text: $emailText)
                                    .font(.none)
                                    .foregroundColor(self.errorEmail ? .red : .primary)
                                    .textCase(.lowercase)
                                    .keyboardType(.emailAddress)
                                    .onChange(of: self.emailText) { _ in
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
                            self.emailText = self.auth.profile.results.first?.emailAddress ?? ""
                        }
                        
                        //Website Section
                        VStack {
                            HStack {
                                Image(systemName: "safari")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                TextField("Website", text: $websiteText)
                                    .font(.none)
                                    .foregroundColor(.primary)
                                    .textCase(.lowercase)
                                    .onChange(of: self.websiteText) { _ in
                                        self.didSave = false
                                    }
                                
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.vertical, 6)
                            .padding(.top, 2)
                            .contentShape(Rectangle())
                        }.onAppear() {
                            self.websiteText = self.auth.profile.results.first?.website ?? ""
                        }
                    })
                    
                    //MARK: Details Section
                    HStack {
                        Text("SOCIAL:")
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.horizontal)
                            .offset(y: 2)
                        Spacer()
                    }.padding(.top, 10)
                    
                    self.viewModel.styleBuilder(content: {
                        //Instagram Section
                        VStack {
                            HStack {
                                Image("instagramIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Button(action: {
                                    if self.viewModel.testUserData.user_id == 0 {
                                        self.presentAuth.toggle()
                                    }
                                }) {
                                    Text(self.viewModel.testUserData.user_id == 0 ? "Connect Instagram Account" : " @\(self.username)")
                                        .font(.none)
                                        .foregroundColor(self.viewModel.testUserData.user_id == 0 ? .blue : .primary)
                                }.offset(x: -2.5)
                                
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())

                            Divider()
                                .frame(width: Constants.screenWidth - 70)
                                .offset(x: 30)
                        }.onAppear() {
                            self.viewModel.pullInstagramUser(completion: { username in
                                self.username = username
                            })
                        }
                        
                        //Twitter Section
                        VStack {
                            HStack {
                                Image("twitterIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)
                                
                                Text("@")
                                    .fontWeight(.regular)
                                    .foregroundColor(twitterText.count > 0 ? .primary : .secondary)

                                TextField("Twitter", text: $twitterText)
                                    .font(.none)
                                    .foregroundColor(.primary)
                                    .textCase(.lowercase)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .offset(x: twitterText.count > 0 ? -8 : -4)
                                    .onChange(of: self.twitterText) { twrText in
                                        if twrText.contains(" ") {
                                            let reducedText = twrText.replacingOccurrences(of: " ", with: "")
                                            self.twitterText = reducedText
                                        }

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
                            self.twitterText = self.auth.profile.results.first?.twitter ?? ""
                        }
                        
                        //Phone Number Section
                        VStack {
                            HStack {
                                Image("facebookIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.secondary)
                                    .frame(width: 20, height: 20, alignment: .center)
                                    .padding(.trailing, 5)

                                Text("@")
                                    .fontWeight(.regular)
                                    .foregroundColor(facebookText.count > 0 ? .primary : .secondary)

                                TextField("Facebook", text: $facebookText)
                                    .font(.none)
                                    .foregroundColor(.primary)
                                    .textCase(.lowercase)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .offset(x: facebookText.count > 0 ? -8 : -4)
                                    .onChange(of: self.facebookText) { fbText in
                                        if fbText.contains(" ") {
                                            let reducedText = fbText.replacingOccurrences(of: " ", with: "")
                                            self.facebookText = reducedText
                                        }
                                        self.didSave = false
                                    }
                                    
                                Spacer()
                            }.padding(.horizontal)
                            .padding(.vertical, 6)
                            .padding(.top, 2)
                            .contentShape(Rectangle())
                        }.onAppear() {
                            self.facebookText = self.auth.profile.results.first?.facebook ?? ""
                        }
                    })
                    
                    //MARK: Footer Section
                    FooterInformation()
                        .padding(.vertical, 40)
                    
                }.padding(.top, 70)
                .resignKeyboardOnDragGesture()
                .onAppear {
                    changeProfileRealmDate.shared.observeFirebaseUser(with: self.auth.profile.results.first?.id ?? 0)
                }
            }.frame(height: Constants.screenHeight - 50 - self.keyboardHeight)
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    UIApplication.shared.endEditing(true)
                    guard self.bioText.count < 220 else {
                        UINotificationFeedbackGenerator().notificationOccurred(.error)

                        return
                    }

                    if self.loadingSave == false {
                        self.loadingSave = true
                        let updateParameters = UpdateUserParameters()
                        updateParameters.fullName = self.fullNameText
                        updateParameters.website = self.websiteText
                        if changeProfileRealmDate.shared.isValidEmail(self.emailText) {
                            updateParameters.email = self.emailText
                            self.errorEmail = false
                        } else {
                            self.errorEmail = true
                        }
                        Request.updateCurrentUser(updateParameters, successBlock: { (user) in
                            changeProfileRealmDate.shared.updateProfile(user, completion: {
                                Database.database().reference().child("Users").child("\(UserDefaults.standard.integer(forKey: "currentUserID"))").updateChildValues(["bio" : self.bioText, "facebook" : self.facebookText, "twitter" : self.twitterText])
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
                    
                }) {
                    Text(self.bioText.count > 220 ? "error" : loadingSave ? "Saving" : self.didSave ? "Saved" : "Save")
                        .foregroundColor(self.bioText.count > 220 || loadingSave ? .secondary : self.didSave ? .secondary : .blue)
                        .fontWeight(self.bioText.count > 220 || loadingSave ? .none : self.didSave ? .none : .medium)
                }.disabled(self.bioText.count > 220 || loadingSave ? true : self.didSave ? true : false)
            ).background(Color("bgColor"))
            .edgesIgnoringSafeArea(.all)
            .popup(isPresented: self.$receivedNotification, type: .floater(), position: .bottom, animation: Animation.spring(), autohideIn: 4, closeOnTap: true) {
                NotificationSection()
                    .environmentObject(self.auth)
            }
            .onAppear {
                NotificationCenter.default.addObserver(forName: NSNotification.Name("NotificationAlert"), object: nil, queue: .main) { (_) in
                    self.receivedNotification.toggle()
                }

                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (data) in
                    let height1 = data.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                    self.keyboardHeight = height1.cgRectValue.height + 10
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
                    self.keyboardHeight = 0
                }
            }
        }
    }
}
