import SwiftUI

private let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

struct LinkColoredText: View {
    enum Component {
        case text(String)
        case link(String, URL)
    }

    let text: String
    let components: [Component]
    let messageRight: Bool
    let messageState: messageStatus

    init(text: String, links: [NSTextCheckingResult], messageRight: Bool, messageState: messageStatus) {
        self.messageRight = messageRight
        self.text = text
        self.messageState = messageState
        let nsText = text as NSString

        var components: [Component] = []
        var index = 0
        for result in links {
            if result.range.location > index {
                components.append(.text(nsText.substring(with: NSRange(location: index, length: result.range.location - index))))
            }
            components.append(.link(nsText.substring(with: result.range), result.url!))
            index = result.range.location + result.range.length
        }

        if index < nsText.length {
            components.append(.text(nsText.substring(from: index)))
        }

        self.components = components
    }

    var body: some View {
        ZStack {
            components.map { component in
                switch component {
                case .text(let text):
                    return Text(verbatim: text)
                        .foregroundColor(self.messageState != .error ? (self.messageRight ? .white : .primary) : .red)

                case .link(let text, _):
                    return Text(verbatim: text)
                        .foregroundColor(self.messageRight ? .white : .blue)
                        .underline()
                }
            }.reduce(Text(""), +)
        }.foregroundColor(self.messageState != .error ? (self.messageRight ? .white : .primary) : .red)
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .transition(AnyTransition.scale)
        .background(self.messageRight ? LinearGradient(
            gradient: Gradient(colors: [Color(red: 46 / 255, green: 168 / 255, blue: 255 / 255, opacity: 1.0), Color(.sRGB, red: 31 / 255, green: 118 / 255, blue: 249 / 255, opacity: 1.0)]),
            startPoint: .top, endPoint: .bottom) : LinearGradient(
                gradient: Gradient(colors: [Color("buttonColor"), Color("buttonColor_darker")]), startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .circular))
        .shadow(color: self.messageRight ? Color.blue.opacity(0.15) : Color.black.opacity(0.15), radius: 6, x: 0, y: 6)
    }
}

struct LinkedText: View {
    let text: String
    var links: [NSTextCheckingResult] = []
    let messageRight: Bool

    @State var displayOverlay = true
    @State var showWebsite: Bool = false
    @State var websiteUrl: String = ""
    @State var messageState: messageStatus = .sending

    init (_ text: String, messageRight: Bool, messageState: messageStatus) {
        self.messageRight = messageRight
        self.text = text
        self.messageState = messageState
        let nsText = text as NSString

        // find the ranges of the string that have URLs
        let wholeString = NSRange(location: 0, length: nsText.length)
        links = linkDetector.matches(in: text, options: [], range: wholeString)
    }

    var body: some View {
        LinkColoredText(text: text, links: links, messageRight: messageRight, messageState: messageState)
            .font(.body) // enforce here because the link tapping won't be right if it's different
            .overlay(displayOverlay ? LinkTapOverlay(text: text, links: links, showWebsite: self.$showWebsite, websiteUrl: self.$websiteUrl) : nil)
            .onChange(of: links, perform: { _ in
                self.displayOverlay = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.displayOverlay = true
                }
            }).sheet(isPresented: self.$showWebsite, content: {
                NavigationView {
                    WebsiteView(websiteUrl: self.$websiteUrl)
                        .onAppear(){
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        }
                }
            })
    }
}

private struct LinkTapOverlay: UIViewRepresentable {
    let text: String
    let links: [NSTextCheckingResult]
    @ObservedObject var webViewStateModel: WebViewStateModel = WebViewStateModel()
    @Binding var showWebsite: Bool
    @Binding var websiteUrl: String

    func makeUIView(context: Context) -> LinkTapOverlayView {
        let view = LinkTapOverlayView()
        view.textContainer = context.coordinator.textContainer
        
        view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didTapLabel(_:)))
        tapGesture.delegate = context.coordinator
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: LinkTapOverlayView, context: Context) {
        let attributedString = NSAttributedString(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
        context.coordinator.textStorage = NSTextStorage(attributedString: attributedString)
        context.coordinator.textStorage!.addLayoutManager(context.coordinator.layoutManager)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let overlay: LinkTapOverlay

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        var textStorage: NSTextStorage?
        
        init(_ overlay: LinkTapOverlay) {
            self.overlay = overlay
            
            textContainer.lineFragmentPadding = 0
            textContainer.lineBreakMode = .byWordWrapping
            textContainer.maximumNumberOfLines = 0
            layoutManager.addTextContainer(textContainer)
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            let location = touch.location(in: gestureRecognizer.view!)
            let result = link(at: location)
            return result != nil
        }
        
        @objc func didTapLabel(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view!)
            guard let result = link(at: location) else {
                return
            }

            guard let url = result.url else {
                return
            }

            //UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.overlay.websiteUrl = "\(url)"
            self.overlay.webViewStateModel.websiteUrl = "\(url)"
            self.overlay.showWebsite.toggle()
        }
        
        private func link(at point: CGPoint) -> NSTextCheckingResult? {
            guard !overlay.links.isEmpty else {
                return nil
            }

            let indexOfCharacter = layoutManager.characterIndex(
                for: point,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            return overlay.links.first { $0.range.contains(indexOfCharacter) }
        }
    }
}

private class LinkTapOverlayView: UIView {
    var textContainer: NSTextContainer!
    
    override func layoutSubviews() {
        super.layoutSubviews()

        var newSize = bounds.size
        newSize.height += 20 // need some extra space here to actually get the last line
        textContainer.size = newSize
    }
}
