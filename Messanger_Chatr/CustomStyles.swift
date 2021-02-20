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
            .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 55, maxHeight: 55)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color(.sRGB, red: 78/255, green: 153/255, blue: 255/255, opacity: 1.0) : Color(.sRGB, red: 31/255, green: 127/255, blue: 255/255, opacity: 1.0))
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
    }
}

struct MainButtonStyleMini: ButtonStyle {
    public func makeBody(configuration: MainButtonStyleMini.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 40, maxHeight: 40)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color(.sRGB, red: 78/255, green: 153/255, blue: 255/255, opacity: 1.0) : Color(.sRGB, red: 31/255, green: 127/255, blue: 255/255, opacity: 1.0))
            .cornerRadius(12.5)
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
    }
}

struct MainButtonStyleDeselected: ButtonStyle {
    public func makeBody(configuration: MainButtonStyleDeselected.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 55, maxHeight: 55)
            .foregroundColor(Color("disabledButton"))
            .background(configuration.isPressed ? Color.secondary : Color(.clear))
            .cornerRadius(15)
            .overlay(
                 RoundedRectangle(cornerRadius: 15)
                     .stroke(Color("disabledButton"), lineWidth: 1)
             )
    }
}

struct HomeButtonStyle: ButtonStyle {
    public func makeBody(configuration: HomeButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("bgColor_light") : Color("buttonColor"))
            .cornerRadius(Constants.menuBtnSize / 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: Color("buttonShadow_Deeper"), radius: 10, x: 0, y: 8)
            .frame(width: Constants.menuBtnSize, height: Constants.menuBtnSize)
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

struct keyboardButtonStyle: ButtonStyle {
    public func makeBody(configuration: keyboardButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .background(RoundedRectangle(cornerRadius: 15))
            .foregroundColor(configuration.isPressed ? Color("interactionBtnColor") : Color("interactionBtnBorderUnselected"))
    }
}

struct changeBGPaperclipButtonStyle: ButtonStyle {
    public func makeBody(configuration: changeBGPaperclipButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("bgColor") : Color.clear)
    }
}

struct changeBGButtonStyle: ButtonStyle {
    public func makeBody(configuration: changeBGButtonStyle.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("bgColor_light") : Color("buttonColor"))
    }
}

struct changeBGButtonStyleDisabled: ButtonStyle {
    public func makeBody(configuration: changeBGButtonStyleDisabled.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color("disabledButton") : Color.clear)
            .cornerRadius(10)
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

struct interactionButtonStyle: ButtonStyle {
    @Binding var isHighlighted: Bool
    @Binding var messagePosition: messagePosition
    
    public func makeBody(configuration: interactionButtonStyle.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .background(RoundedRectangle(cornerRadius: 20).shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 3))
            .foregroundColor(configuration.isPressed ? (isHighlighted ? Color.blue.opacity(0.15) : Color("bgColor").opacity(0.15)) : isHighlighted ? Color("main_blue").opacity(0.3) : Color("interactionBtnColor").opacity(0.75))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isHighlighted ? (configuration.isPressed ? Color.blue.opacity(0.15) : Color.blue.opacity(0.4)) : (configuration.isPressed ? Color("interactionBtnBorderUnselected").opacity(0.2) : Color("interactionBtnBorderUnselected")), lineWidth: 1.5))
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
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
            .frame(minWidth: 40, maxWidth: Constants.screenWidth, minHeight: 45, maxHeight: 60)
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

extension TimeInterval{
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)

        //let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        //let hours = (time / 3600)

        return String(format: "%0.2d:%0.2d", minutes, seconds)
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
