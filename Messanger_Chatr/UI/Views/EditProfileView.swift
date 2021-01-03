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

struct EditProfileView: View {
    @EnvironmentObject var auth: AuthModel
    @ObservedObject var profile = ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self))
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

    var body: some View {
        ZStack {
            GeometryReader { geometry in
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
                                self.showImagePicker.toggle()
                            }, label: {
                                VStack {
                                    VStack {
                                        HStack {
                                            if let avitarURL = self.profile.results.first?.avatar {
                                                WebImage(url: URL(string: avitarURL))
                                                    .resizable()
                                                    .placeholder{ Image("empty-profile").resizable().frame(width: 65, height: 65, alignment: .center).scaledToFill() }
                                                    .indicator(.activity)
                                                    .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                                    .scaledToFill()
                                                    .clipShape(Circle())
                                                    .frame(width: 65, height: 65, alignment: .center)
                                                    .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 8)
                                            }
                                            
                                            Text("Change Profile Picture")
                                                .font(.none)
                                                .fontWeight(.none)
                                                .foregroundColor(.blue)

                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .resizable()
                                                .font(Font.title.weight(.bold))
                                                .scaledToFit()
                                                .frame(width: 7, height: 15, alignment: .center)
                                                .foregroundColor(.secondary)
                                        }.padding(.horizontal)
                                        .contentShape(Rectangle())
                                    }
                                }.padding(.vertical, 10)
                            }).buttonStyle(changeBGButtonStyle())
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .sheet(isPresented: $showImagePicker, onDismiss: loadImage) {
                            ImagePicker(image: self.$inputImage)
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
                        
                        VStack(alignment: .center) {
                            VStack {
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
                                            .font(.system(size: 24, weight: .bold, design: .default))
                                            .foregroundColor(.primary)
                                            .onChange(of: self.fullNameText) { _ in
                                                self.didSave = false
                                            }

                                        Spacer()
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())

                                    Divider()
                                        .frame(width: Constants.screenWidth - 70)
                                        .offset(x: 30)
                                }.padding(.bottom, 5)
                                .onAppear() {
                                    self.fullNameText = self.profile.results.first?.fullName ?? ""
                                }
                                
                                //Bio Section
                                VStack() {
                                    ZStack(alignment: .topTrailing) {
                                        HStack(alignment: .top) {
                                            Image(systemName: "note.text")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundColor(Color.secondary)
                                                .frame(width: 20, height: 20, alignment: .center)
                                                .padding(.trailing, 5)
                                            
                                            ZStack(alignment: .topLeading) {
                                                ResizableTextField(height: self.$bioHeight, text: self.$bioText, emptyPlaceholder: true)
                                                    .padding(.horizontal, 2.5)
                                                    .padding(.trailing, 5)
                                                    .font(.none)
                                                    .foregroundColor(self.bioText != "Bio" ? .primary : .secondary)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(5)
                                                    .offset(x: -5, y: -10)
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
                                            
                                            Spacer()
                                        }.padding(.horizontal)
                                        .frame(height: 100)
                                        
                                        Text("\(220 - self.bioText.count)")
                                            .font(.subheadline)
                                            .fontWeight(self.bioText.count > 220 ? .bold : .none)
                                            .foregroundColor(self.bioText.count > 220 ? .red : .secondary)
                                            .padding(.trailing, 15)
                                    }
                                }.onAppear() {
                                    self.bioText = self.profile.results.first?.bio ?? "Bio"
                                    print("bio height is: \(self.bioHeight) && \(self.bioText)")
                                }
                            }.padding(.vertical, 15)
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        
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
                        
                        VStack(alignment: .center) {
                            VStack {
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
                                    .contentShape(Rectangle())

                                    Divider()
                                        .frame(width: Constants.screenWidth - 70)
                                        .offset(x: 30)
                                }.padding(.bottom, 5)
                                .onAppear {
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
                                    .contentShape(Rectangle())

                                    Divider()
                                        .frame(width: Constants.screenWidth - 70)
                                        .offset(x: 30)
                                }.padding(.bottom, 5)
                                .onAppear() {
                                    self.emailText = self.profile.results.first?.emailAddress ?? ""
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
                                    .contentShape(Rectangle())
                                }.onAppear() {
                                    self.websiteText = self.profile.results.first?.website ?? ""
                                }
                                
                            }.padding(.vertical, 15)
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        
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
                        
                        VStack(alignment: .center) {
                            VStack {
                                //Twitter Section
                                VStack {
                                    HStack {
                                        Image("twitterIcon")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundColor(Color.secondary)
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .padding(.trailing, 5)
                                        
                                        TextField("Twitter", text: $twitterText)
                                            .font(.none)
                                            .foregroundColor(.primary)
                                            .textCase(.lowercase)
                                            .onChange(of: self.twitterText) { _ in
                                                self.didSave = false
                                            }
                                        
                                        Spacer()
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())

                                    Divider()
                                        .frame(width: Constants.screenWidth - 70)
                                        .offset(x: 30)
                                }.onAppear() {
                                    self.twitterText = self.profile.results.first?.twitter ?? ""
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
                                        
                                        TextField("Facebook", text: $facebookText)
                                            .font(.none)
                                            .foregroundColor(.primary)
                                            .textCase(.lowercase)
                                            .onChange(of: self.facebookText) { _ in
                                                self.didSave = false
                                            }
                                            
                                        Spacer()
                                    }.padding(.horizontal)
                                    .contentShape(Rectangle())
                                }.onAppear() {
                                    self.facebookText = self.profile.results.first?.facebook ?? ""
                                }
                            }.padding(.vertical, 15)
                        }.background(Color("buttonColor"))
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .circular))
                        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                                            
                        //MARK: Footer Section
                        FooterInformation()
                            .padding(.vertical, 40)
                        
                    }.padding(.top, 70)
                    //.KeyboardAwarePaddingFull()
                    .resignKeyboardOnDragGesture()
                }.frame(height: Constants.screenHeight - 50 - self.keyboardHeight)
                .navigationBarTitle("Edit Profile", displayMode: .inline)
                .navigationBarItems(trailing:
                    Button(action: {
                        print("Save btn")
                        UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
                        if self.loadingSave == false {
                            self.loadingSave = true
                            let updateParameters = UpdateUserParameters()
                            updateParameters.fullName = self.fullNameText
                            updateParameters.website = self.websiteText
                            if changeProfileRealmDate().isValidEmail(self.emailText) {
                                updateParameters.email = self.emailText
                                self.errorEmail = false
                            } else {
                                self.errorEmail = true
                            }
                            Request.updateCurrentUser(updateParameters, successBlock: { (user) in
                                changeProfileRealmDate().updateProfile(user, completion: {
                                    Database.database().reference().child("Users").child("\(UserDefaults.standard.integer(forKey: "currentUserID"))").updateChildValues(["bio" : self.bioText, "facebook" : self.facebookText, "twitter" : self.twitterText])
                                    print("done updating profile")
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
                        Text((220 - self.bioText.count) > 220 && loadingSave ? "Saving" : self.didSave ? "Saved" : "Save")
                            .foregroundColor((220 - self.bioText.count) > 220 && loadingSave ? .secondary : self.didSave ? .secondary : .blue)
                            .fontWeight((220 - self.bioText.count) > 220 && loadingSave ? .none : self.didSave ? .none : .medium)
                    }.disabled((220 - self.bioText.count) > 220 && loadingSave ? true : self.didSave ? true : false)
                )
                .background(Color("bgColor"))
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { (data) in
                        DispatchQueue.main.async {
                            let height1 = data.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue
                            self.keyboardHeight = height1.cgRectValue.height + 10
                            print("keyboad height is: \(self.keyboardHeight)")
                        }
                    }
                    
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { (_) in
                        self.keyboardHeight = 0
                        print("keyboad height is: \(self.keyboardHeight)")

                    }
                }
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        self.auth.setUserAvatar(image: inputImage, completion: { result in
            
        })
    }
}