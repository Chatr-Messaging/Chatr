//
//  QuickSnapsPostView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/1/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import RealmSwift
import FirebaseDatabase
import ConnectyCube

struct QuickSnapsPostView: View {
    @ObservedObject var quickSnapsRealm = QuickSnapsRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(QuickSnapsStruct.self))
    @Binding var selectedQuickSnapContact: ContactStruct
    @Binding var viewState: QuickSnapViewingState
    @State var loadAni: Bool = false
    @State var errorLoading: Bool = false
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var timeRemaining: Int = 10
    @State var timeLoading: Int = 0
    @State var likePost: Bool = false
    @Binding var selectedContacts: [Int]
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                if !self.loadAni && self.viewState == .viewing {
                    HStack {
                        ZStack {
                            WebImage(url: URL(string: self.selectedQuickSnapContact.avatar))
                                .resizable()
                                .placeholder{ Image("empty-profile").resizable().frame(width: Constants.smallBtnSize, height: Constants.smallBtnSize, alignment: .center).scaledToFill() }
                                .indicator(.activity)
                                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: Constants.smallBtnSize, height: Constants.smallBtnSize, alignment: .center)
                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)
                            
                            if self.quickSnapsRealm.results.filter("id == %@", selectedQuickSnapContact.quickSnaps.first ?? "").count > 0 {
                                Circle()
                                    .trim(from: 0, to: CGFloat(Double(self.timeRemaining) * 0.1))
                                    .stroke(Constants.snapPurpleGradient, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .frame(width: Constants.smallBtnSize + 6, height: Constants.smallBtnSize + 6)
                                    .animation(Animation.linear(duration: 1.0).repeatForever(autoreverses: true))
                                    .rotationEffect(.degrees(90))
                                    .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                                    .foregroundColor(.clear)
                                    .onReceive(timer) { _ in
                                        if self.viewState == .viewing {
                                            if self.timeRemaining > 0 {
                                                print("Quick Snap Timer: \(self.timeRemaining)")
                                                self.timeRemaining -= 1
                                            } else {
                                                //time remaining!
                                                print("DONE WITH THIS POST!!")
                                                self.timer.upstream.connect().cancel()
                                                self.deletePost()
                                            }
                                        } else {
                                            self.timer.upstream.connect().cancel()
                                        }
                                    }.onDisappear() {
                                        if self.viewState == .closed && self.viewState != .viewingOver && self.selectedQuickSnapContact.quickSnaps.count != 0  && self.timeRemaining != 10 && self.timeRemaining != 0 {
                                            self.deletePost()
                                        }
                                    }
                            }
                            
                            RoundedRectangle(cornerRadius: 5)
                                .frame(width: 10, height: 10)
                                .foregroundColor(.green)
                                .opacity(selectedQuickSnapContact.isOnline ? 1 : 0)
                                .offset(x: 14, y: 14)
                        }
                        
                        VStack(alignment: .leading) {
                            if self.selectedQuickSnapContact.fullName != "empty name" {
                                Text(self.selectedQuickSnapContact.fullName)
                                    .font(.none)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                            }
                            
                            if let timeAgo = self.quickSnapsRealm.results.filter("id == %@", selectedQuickSnapContact.quickSnaps.first ?? "").sorted(by: { $0.sentDate.compare($1.sentDate) == .orderedDescending }).first?.sentDate.getElapsedInterval(lastMsg: "moments") {
                                Text(timeAgo + " ago")
                                    .font(.footnote)
                                    .fontWeight(.regular)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                            }
                        }
                        
                        Spacer()
                        Button(action: {
                            print("close Button")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.deletePost()
                            self.viewState = .closed
                        }) {
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: Constants.microBtnSize, height: Constants.microBtnSize, alignment: .center)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 0)
                                .padding(.all)
                                
                        }.buttonStyle(ClickButtonStyle())
                        
                    }.padding(.horizontal)
                    .padding(.top, 60)
                }
                
                //MARK: Viewing State
                if self.viewState == .viewing {
                    //MARK: MAIN IMAGE
                    if let image = self.quickSnapsRealm.results.filter("id == %@", selectedQuickSnapContact.quickSnaps.first ?? "").sorted(by: { $0.sentDate.compare($1.sentDate) == .orderedDescending }).first?.imageUrl {
                        WebImage(url: URL(string: image))
                            .resizable()
                            .placeholder{
                                VStack {
                                    HStack(spacing: self.errorLoading ? 10 : 0) {
                                        if self.errorLoading {
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                                self.timer.upstream.connect().cancel()
                                                self.timeLoading = 0
                                                self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                                                self.errorLoading = false
                                            }, label: {
                                                Image(systemName: "arrow.counterclockwise")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20, alignment: .center)
                                                    .foregroundColor(.white)
                                            }).opacity(self.errorLoading ? 1 : 0)
                                        }

                                        Text(self.errorLoading ? "taking a while..." : "loading...")
                                            .font(.subheadline)
                                            .fontWeight(.none)
                                            .foregroundColor(.white)
                                            .onAppear() {
                                                self.loadAni = true
                                                print("well the url is: \(image)")
                                            }.onDisappear() {
                                                self.loadAni = false
                                                self.errorLoading = false
                                                self.timeLoading = 0
                                            }.onReceive(timer) { _ in
                                                self.timeLoading += 1
                                                if timeLoading == 4 {
                                                    self.errorLoading = true
                                                }
                                            }
                                    }
                                    
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                        self.deletePost()
                                    }, label: {
                                        Text("skip")
                                            .fontWeight(.semibold)
                                    }).buttonStyle(MainButtonStyleMini())
                                    .frame(maxWidth: 120)
                                    .shadow(color: Color.black.opacity(0.1), radius: 14, x: 0, y: 8)
                                    .opacity(self.errorLoading ? 1 : 0)
                                    .padding(.top, 45)
                                    .disabled(self.errorLoading ? false : true)
                                }
                            }.scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 8)
                            .onAppear() {
                                self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                                self.likePost = false
                            }
                            .onTapGesture {
                                if !self.loadAni {
                                    print("Tap a da tap - DONE WITH THIS POST!!")
                                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                                    self.timer.upstream.connect().cancel()
                                    self.deletePost()
                                }
                            }
                    }
                }
                
                //MARK: Past View State
                if self.viewState == .viewingOver {
                    VStack(alignment: .center) {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 50)
                                .frame(width: 90, height: 90, alignment: .center)
                                .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 15)
                                .foregroundColor(.white)
                                .opacity(0.5)
                            
                            WebImage(url: URL(string: self.selectedQuickSnapContact.avatar))
                                .resizable()
                                .placeholder{ Image("empty-profile").resizable().frame(width: 80, height: 80, alignment: .center).scaledToFill() }
                                .indicator(.activity)
                                .transition(.asymmetric(insertion: AnyTransition.opacity.animation(.easeInOut(duration: 0.15)), removal: AnyTransition.identity))
                                .scaledToFill()
                                .clipShape(Circle())
                                .frame(width: 80, height: 80, alignment: .center)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 8)
                                .onAppear() {
                                    self.timer.upstream.connect().cancel()
                                }
                            
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 15, height: 15)
                                .foregroundColor(.green)
                                .opacity(self.selectedQuickSnapContact.isOnline ? 1 : 0)
                                .offset(x: 30, y: 30)
                            
                        }.padding(.bottom, 15)
                        
                        if self.selectedQuickSnapContact.fullName != "empty name" {
                            Text(self.selectedQuickSnapContact.fullName)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 0)
                            
                            Text(self.selectedQuickSnapContact.isOnline ? "online now" : "last online \(self.selectedQuickSnapContact.lastOnline.getElapsedInterval(lastMsg: "moments")) ago")
                                .font(.subheadline)
                                .fontWeight(.light)
                                .foregroundColor(Color("lightGray"))
                                .multilineTextAlignment(.leading)
                        }
                        
                        HStack(spacing: 60) {
                            Spacer()
                            VStack {
                                Button(action: {
                                    print("Like Quick Snap")
                                    if self.likePost == true {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                    } else {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        self.likePost = true
                                        
                                        let event = Event()
                                        event.notificationType = .push
                                        event.usersIDs = [NSNumber(value: self.selectedQuickSnapContact.id)]
                                        event.type = .oneShot
                                        event.name = "Liked Qucik Snap"

                                        var pushParameters = [String : String]()
                                        pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") liked your quick snap ❤️"
                                        pushParameters["ios_sound"] = "app_sound.wav"
                                        pushParameters["title"] = "Liked Quci Snap"

                                        if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
                                            let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

                                            event.message = jsonString

                                            Request.createEvent(event, successBlock: {(events) in
                                                print("sent push notification!! \(events)")
                                            }, errorBlock: {(error) in
                                                print("error sending noti: \(error.localizedDescription)")
                                            })
                                        }
                                    }
                                }, label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: Constants.btnSize, height: Constants.btnSize, alignment: .center)
                                            .foregroundColor(.white)
                                            .opacity(0.35)
                                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 10)
                                        
                                        Image(systemName: "heart.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 26, height: 28, alignment: .center)
                                            .foregroundColor(self.likePost ? .red : .white)
                                            .scaleEffect(self.likePost ? 1.3 : 1.0)
                                            .animation(.spring(response: 0.2, dampingFraction: 0.25, blendDuration: 0))
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                    }
                                }).buttonStyle(ClickButtonStyle())
                                
                                Text(self.likePost ? "Liked" : "Like")
                                    .font(.caption)
                                    .fontWeight(.none)
                                    .foregroundColor(Color("lightGray"))
                                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                            }
                            
                            VStack {
                                Button(action: {
                                    print("Reply")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    self.selectedContacts.removeAll()
                                    self.selectedContacts.append(self.selectedQuickSnapContact.id)
                                    self.viewState = .camera
                                }, label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .frame(width: Constants.btnSize, height: Constants.btnSize, alignment: .center)
                                            .foregroundColor(.white)
                                            .opacity(0.35)
                                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
                                        
                                        Image(systemName: "paperplane.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 26, alignment: .center)
                                            .foregroundColor(.white)
                                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
                                    }
                                }).buttonStyle(ClickButtonStyle())
                                
                                Text("Reply")
                                    .font(.caption)
                                    .fontWeight(.none)
                                    .foregroundColor(Color("lightGray"))
                                    .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 0)
                            }
                            Spacer()
                        }
                        .padding(.top, 35)
                        
                        Spacer()
                        
                        Button(action: {
                            print("close Button")
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            self.deletePost()
                            self.viewState = .closed
                        }) {
                            Text("Close")
                                .font(.subheadline)
                                .fontWeight(.none)
                                .foregroundColor(Color("lightGray"))
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 0)
                                .padding(.all, 25)
                        }.buttonStyle(ClickButtonStyle())
                        .padding(.bottom, 25)
                    }.frame(width: Constants.screenWidth)
                    Spacer()
                }
                
                Spacer()
            }.background(BlurView(style: .systemThinMaterialDark))
            .cornerRadius(20)
        }.onAppear() {
            NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main) { notification in
                print("Screenshot taken!")
                if self.viewState == .viewing {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
 
                    let event = Event()
                    event.notificationType = .push
                    event.usersIDs = [NSNumber(value: self.selectedQuickSnapContact.id)]
                    event.type = .oneShot
                    event.name = "Screenshot Taken!"

                    var pushParameters = [String : String]()
                    pushParameters["message"] = "\(ProfileRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(ProfileStruct.self)).results.first?.fullName ?? "A user") took a screenshot of your quick snap."
                    pushParameters["ios_sound"] = "app_sound.wav"
                    pushParameters["title"] = "Screenshot"

                    if let jsonData = try? JSONSerialization.data(withJSONObject: pushParameters, options: .prettyPrinted) {
                        let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8)

                        event.message = jsonString

                        Request.createEvent(event, successBlock: {(events) in
                            print("sent push notification!! \(events)")
                        }, errorBlock: {(error) in
                            print("error sending noti: \(error.localizedDescription)")
                        })
                    }
                }
            }
        }
    }
    
    func deletePost() {
        let config = Realm.Configuration(schemaVersion: 1)
        do {
            let realm = try Realm(configuration: config)
            
            try? realm.write({
                if let deleteFirst = (self.quickSnapsRealm.results.filter("id == %@", self.selectedQuickSnapContact.quickSnaps.first ?? "").sorted(by: { $0.sentDate.compare($1.sentDate) == .orderedDescending }).first) {
                    realm.delete(deleteFirst)
                }
                
                let profileResult = realm.object(ofType: ContactStruct.self, forPrimaryKey: self.selectedQuickSnapContact.id)
                if profileResult?.quickSnaps.count == 0 && self.viewState == .viewing {
                    self.viewState = .viewingOver
                } else {
                    if let firstID = profileResult?.quickSnaps.first {
                        Database.database().reference().child("Users").child("\(Session.current.currentUserID)").child("quickSnaps").child("\(self.selectedQuickSnapContact.id)").updateChildValues([firstID : false])
                        profileResult?.quickSnaps.remove(at: 0)
                        if profileResult?.quickSnaps.count == 0 && self.viewState == .viewing {
                            self.viewState = .viewingOver
                        } else {
                            self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                        }
                    }
                }
                self.timeRemaining = 10
            })
        } catch {
            print(error.localizedDescription)
        }
    }
}
