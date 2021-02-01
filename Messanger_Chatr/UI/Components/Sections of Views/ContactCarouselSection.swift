//
//  ContactCarouselSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 9/10/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift

struct ContactBannerData: Identifiable {
    var id = UUID()
    var titleBold: String
    var title: String
    var subtitleImage: String
    var subtitle: String
    var imageMain: String
    var gradientBG: String
}

//MARK: Carousel View
struct ContactCarousel : UIViewRepresentable {
    var width : CGFloat
    @Binding var page : Int
    @Binding var scrollOffset : CGFloat
    @Binding var dataArray: [ContactBannerData]
    @Binding var dataArrayCount: Int
    @Binding var quickSnapViewState: QuickSnapViewingState
    var height : CGFloat
    
    func makeCoordinator() -> Coordinator {
        return ContactCarousel.Coordinator(parent1: self)
    }

    func makeUIView(context: Context) -> UIScrollView{
        // ScrollView Content Size...
        let total = width * CGFloat(dataArrayCount)
        let view = UIScrollView()
        view.isPagingEnabled = true
        //1.0  For Disabling Vertical Scroll....
        view.contentSize = CGSize(width: total, height: 1.0)
        view.bounces = true
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.delegate = context.coordinator
        
        // Now Going to  embed swiftUI View Into UIView...
        let view1 = UIHostingController(rootView: ContactListView(page: self.$page, dataArray: self.$dataArray, quickSnapViewState: self.$quickSnapViewState))
        view1.view.frame = CGRect(x: 0, y: 0, width: total, height: self.height)
        view1.view.backgroundColor = .clear
        view.addSubview(view1.view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        let total = width * CGFloat(dataArrayCount)
        uiView.contentSize = CGSize(width: total, height: 1.0)
    }
    
    class Coordinator : NSObject,UIScrollViewDelegate{
        var parent : ContactCarousel
        
        init(parent1: ContactCarousel) {
            parent = parent1
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Using This Function For Getting Currnet Page
        
            let page = Int(scrollView.contentOffset.x / UIScreen.main.bounds.width)
            self.parent.page = page
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.parent.scrollOffset = scrollView.contentOffset.x
        }
    }
}

//MARK: ContactList View
struct ContactListView : View {
    @EnvironmentObject var auth: AuthModel
    @Binding var page : Int
    @Binding var dataArray: [ContactBannerData]
    @Binding var quickSnapViewState: QuickSnapViewingState
    @State var openDiscoverContent: Bool = false
    @State var openPremiumContent: Bool = false
    @State var openAddressBookContent: Bool = false
    @ObservedObject var addressBook = AddressBookRealmModel(results: try! Realm(configuration: Realm.Configuration(schemaVersion: 1)).objects(AddressBookStruct.self))
    
    var body: some View {
        HStack(spacing: 0) {
            
            //Discover Channels
            ContactBannerCell(titleBold: self.dataArray[0].titleBold, title: self.dataArray[0].title, subtitleImage: self.dataArray[0].subtitleImage, subtitle: self.dataArray[0].subtitle, imageMain: self.dataArray[0].imageMain, gradientBG: self.dataArray[0].gradientBG)
                .frame(width: Constants.screenWidth)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.openDiscoverContent.toggle()
                }.sheet(isPresented: self.$openDiscoverContent, content: {
                    NavigationView {
                        DiscoverView()
                            .environmentObject(self.auth)
                            //.navigationBarTitle("Discover", displayMode: .large)
                            .background(Color("bgColor").edgesIgnoringSafeArea(.all))
                    }
                })
            
            //premium
            if self.auth.subscriptionStatus == .notSubscribed {
                ContactBannerCell(titleBold: self.dataArray[1].titleBold, title: self.dataArray[1].title, subtitleImage: self.dataArray[1].subtitleImage, subtitle: self.dataArray[1].subtitle, imageMain: self.dataArray[1].imageMain, gradientBG: self.dataArray[1].gradientBG)
                    .frame(width: Constants.screenWidth)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        self.openPremiumContent.toggle()
                    }.sheet(isPresented: self.$openPremiumContent, content: {
                        MembershipView()
                            .environmentObject(self.auth)
                            .edgesIgnoringSafeArea(.all)
                            .navigationBarTitle("")
                    })
            }
            
            //address book
            if self.addressBook.results.count == 0 {
                ContactBannerCell(titleBold: self.dataArray[2].titleBold, title: self.dataArray[2].title, subtitleImage: self.dataArray[2].subtitleImage, subtitle: self.dataArray[2].subtitle, imageMain: self.dataArray[2].imageMain, gradientBG: self.dataArray[2].gradientBG)
                    .frame(width: Constants.screenWidth)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        self.openAddressBookContent.toggle()
                    }.sheet(isPresented: self.$openAddressBookContent, content: {
                        NavigationView {
                            SyncAddressBook()
                        }.navigationBarTitle("Sync Address Book", displayMode: .inline)
                        .background(Color("bgColor"))
                        .frame(height: Constants.screenHeight)
                    })
            }
            
            ContactBannerCell(titleBold: self.dataArray[3].titleBold, title: self.dataArray[3].title, subtitleImage: self.dataArray[3].subtitleImage, subtitle: self.dataArray[3].subtitle, imageMain: self.dataArray[3].imageMain, gradientBG: self.dataArray[3].gradientBG)
                .frame(width: Constants.screenWidth)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self.quickSnapViewState = .camera
                }
        }.padding(.vertical)
    }
}

// MARK: Walkthrough Cell
struct ContactBannerCell: View, Identifiable {
    let id = UUID()
    @State var titleBold: String
    @State var title: String
    @State var subtitleImage: String
    @State var subtitle: String
    @State var imageMain: String
    @State var gradientBG: String

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .trailing) {
                Image(self.imageMain)
                    .resizable()
                    .scaledToFit()
                    .frame(width: (geo.size.width / 2) - 20, height: geo.size.height)
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: self.subtitleImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 18, alignment: .center)
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                            
                            Text(self.subtitle)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 0)
                        }
                        
                        HStack {
                            Text(self.titleBold)
                                .font(.system(size: 30))
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                            
                            Text(self.title)
                                .font(.system(size: 30))
                                .fontWeight(.light)
                                .foregroundColor(Color.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }.padding(.leading)
                    
                    Spacer()
                }
            }.background(Image(self.gradientBG).resizable().scaledToFill())
            .cornerRadius(25)
            .padding(.horizontal)
            .shadow(color: Color("buttonShadow"), radius: 10, x: 0, y: 10)
        }
    }
}

//MARK: UIPageControl
struct ContactPageControl : UIViewRepresentable {
    @Binding var page : Int
    @Binding var dataArrayCount: Int
    @State var color: String = ""
    
    func makeUIView(context: Context) -> UIPageControl {
        let view = UIPageControl()
        if self.color == "white" {
            view.currentPageIndicatorTintColor = .white
            view.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
        } else {
            view.currentPageIndicatorTintColor = UIColor.black.withAlphaComponent(0.8)
            view.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
        }
        view.numberOfPages = dataArrayCount
        return view
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        // Updating Page Indicator When Ever Page Changes....
        DispatchQueue.main.async {
            uiView.currentPage = self.page
            uiView.numberOfPages = dataArrayCount
        }
    }
}
