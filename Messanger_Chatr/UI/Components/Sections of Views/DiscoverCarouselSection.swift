//
//  DiscoverCarouselSection.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/27/20.
//  Copyright © 2020 Brandon Shaw. All rights reserved.
//

import SwiftUI
import RealmSwift
import SDWebImageSwiftUI
import FirebaseFirestore

class PublicDialogModel {
    var id: String?
    var name: String?
    var memberCount: Int?
    var creationOrder: Int?
    var owner: Int?
    var dateCreated: String?
    var coverPhoto: String?
    var avatar: String?
    var description: String?
    var canMembersType: Bool?
}

extension PublicDialogModel {
    static func transformDialog(_ dict: [String: Any], key: String) -> PublicDialogModel {
        let dialog = PublicDialogModel()
        
        dialog.id = key
        dialog.name = dict["name"] as? String
        dialog.memberCount = dict["members"] as? Int
        dialog.creationOrder = dict["creation_order"] as? Int
        dialog.owner = dict["owner"] as? Int
        dialog.dateCreated = dict["date_created"] as? String
        dialog.coverPhoto = dict["cover_photo"] as? String
        dialog.avatar = dict["avatar"] as? String
        dialog.description = dict["description"] as? String
        dialog.canMembersType = dict["canMembersType"] as? Bool

        return dialog
    }
}

/*
//MARK: Carousel View
struct DiscoverCarousel : UIViewRepresentable {
    var width : CGFloat
    @Binding var page : Int
    @Binding var dataArray: [PublicDialogModel]
    @Binding var dataArrayCount: Int
    @State var scrollOffset: CGFloat = CGFloat()
    var height : CGFloat
    
    func makeCoordinator() -> Coordinator {
        return DiscoverCarousel.Coordinator(parent1: self)
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
        let view1 = UIHostingController(rootView: DiscoverListView(page: self.$page, dataArray: self.$dataArray))
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
        var parent : DiscoverCarousel
        
        init(parent1: DiscoverCarousel) {
            parent = parent1
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            // Using This Function For Getting Currnet Page
        
            let page = Int(scrollView.contentOffset.x / (Constants.screenWidth * 0.55))
            self.parent.page = page
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            self.parent.scrollOffset = scrollView.contentOffset.x
        }
    }
}

//MARK: Discover List View
//struct DiscoverListView : View {
//    @EnvironmentObject var auth: AuthModel
//    @Binding var page : Int
//    @Binding var dataArray: [PublicDialogModel]
//
//    var body: some View {
//        HStack(spacing: 0) {
//            ForEach(self.dataArray, id: \.self) { data in
//                DiscoverBannerCell(groupName: data.name ?? "no name", memberCount: data.memberCount ?? 0, description: data.description ?? "", avatar: data.groupImg ?? "", backgroundImg: data.backgroundImg, catagoryImg: data.catagoryImg)
//                    .frame(width: Constants.screenWidth * 0.55)
//            }
//        }
//    }
//}
*/


//MARK: UIPageControl
struct DiscoverPageControl : UIViewRepresentable {
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

