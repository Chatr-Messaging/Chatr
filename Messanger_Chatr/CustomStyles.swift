//
//  CustomStyles.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 12/6/19.
//  Copyright © 2019 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct MainButtonStyle: ButtonStyle {
    public func makeBody(configuration: MainButtonStyle.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 40, maxWidth: .infinity, minHeight: 45, maxHeight: 65)
            .foregroundColor(.white)
            .background(LinearGradient(
                gradient: Gradient(colors: [Color(red: 71 / 255, green: 171 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
                startPoint: .top,
                endPoint: .bottom
            ))
            .cornerRadius(18)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
    }
}

struct HomeButtonStyle: ButtonStyle {
    public func makeBody(configuration: ClickButtonStyle.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color("bgColor_light") : Color("buttonColor"))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ClickButtonStyle: ButtonStyle {
    public func makeBody(configuration: ClickButtonStyle.Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.95 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ClickMiniButtonStyle: ButtonStyle {
    public func makeBody(configuration: ClickMiniButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
    }
}

struct changeBGButtonStyle: ButtonStyle {
    public func makeBody(configuration: changeBGButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("bgColor_light") : Color("buttonColor"))
    }
}

struct highlightedButtonStyle: ButtonStyle {
    public func makeBody(configuration: highlightedButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .background(configuration.isPressed ? Color("bgColor_light") : Color("buttonColor"))
            .cornerRadius(20)
    }
}

struct navigationScaleHelpticButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: PrimitiveButtonStyle.Configuration) -> some View {
        MyButton(configuration: configuration)
    }
    
    private struct MyButton: View {
        @State var pressed = false
        let configuration: PrimitiveButtonStyle.Configuration
        
        var body: some View {
            let gesture = DragGesture(minimumDistance: 0)
                .onChanged { _ in self.pressed = true }
                .onEnded { value in
                    self.pressed = false
                    if value.translation.width < 10 && value.translation.height < 10 {
                        self.configuration.trigger()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            
            return configuration.label
                .scaleEffect(self.pressed ? 0.975 : 1.0)
                .highPriorityGesture(gesture)
        }
    }
}

struct NeumorphismBtnStyle: ButtonStyle {
    public func makeBody(configuration: NeumorphismBtnStyle.Configuration) -> some View {
    configuration.label
        .background(
            Group {
                if configuration.isPressed {
                    Rectangle()
                        .cornerRadius(15)
                        .background(Color("bgColor"))
                } else {
                    Rectangle()
                        .background(Color("bgColor"))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
                        .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: 5)
                }
            }
        )
    }
}

struct plainButtonStyle: ButtonStyle {
    public func makeBody(configuration: plainButtonStyle.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 40, maxWidth: .infinity, minHeight: 45, maxHeight: 60)
            .foregroundColor(configuration.isPressed ? .gray : .blue)
            .cornerRadius(18)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct EmptyButtonStyle: ButtonStyle {
    public func makeBody(configuration: EmptyButtonStyle.Configuration) -> some View {
        configuration.label
            .foregroundColor(.clear)
    }
}

struct GroupedListModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 14, *) {
                AnyView(
                    content
                        .listStyle(InsetGroupedListStyle())
                )
            } else {
                content
                    .listStyle(GroupedListStyle())
                    .environment(\.horizontalSizeClass, .regular)
            }
        }
    }
}

struct personalProfileView: View {
    @Binding var image: String
    @Binding var size: CGFloat

    //want to add a 'progress' ring ontop of border eventualy
    var body: some View {
        ZStack {
           BlurView(style: .prominent)
               .frame(width: size + 10, height: size + 10, alignment: .center)
               .cornerRadius(35)
               .shadow(color: Color("buttonShadow_Deeper"), radius: 20, x: 0, y: 20)

           Circle()
              .foregroundColor(Color("bgColor"))
              .frame(width: size, height: size, alignment: .center)
              .shadow(color: Color("buttonShadow"), radius: 3, x: 0, y: 0)

           Image(systemName: image)
               .resizable()
               .foregroundColor(Color.primary)
               .frame(width: size, height: size, alignment: .center)
       }
    }
}

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter{$0.isKeyWindow}
            .first?
            .endEditing(force)
    }
    
    var currentScene: UIWindowScene? {
        connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged{ value in
        print("drage kayboard \(value.translation.height)")
        guard value.translation.height < 1 else { UIApplication.shared.windows.first?.rootViewController?.view.endEditing(true)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil); return }
    }
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

extension View {
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}

extension StringProtocol { // for Swift 4 you need to add the constrain `where Index == String.Index`
    var byWords: [SubSequence] {
        var byWords: [SubSequence] = []
        enumerateSubstrings(in: startIndex..., options: .byWords) { _, range, _, _ in
            byWords.append(self[range])
        }
        return byWords
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Array {
    func chunked(into size:Int) -> [[Element]] {
        
        var chunkedArray = [[Element]]()
        
        for index in 0...self.count {
            if index % size == 0 && index != 0 {
                chunkedArray.append(Array(self[(index - size)..<index]))
            } else if(index == self.count) {
                chunkedArray.append(Array(self[index - 1..<index]))
            }
        }
        
        return chunkedArray
    }
}
