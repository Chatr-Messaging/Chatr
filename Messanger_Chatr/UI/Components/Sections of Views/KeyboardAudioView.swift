//
//  KeyboardAudioView.swift
//  Messanger_Chatr
//
//  Created by Brandon Shaw on 3/22/21.
//  Copyright © 2021 Brandon Shaw. All rights reserved.
//

import SwiftUI

struct KeyboardAudioView: View {
    @ObservedObject var viewModel: VoiceViewModel = VoiceViewModel()
    @Binding var isRecordingAudio: Bool
    @State var isFlashingAnimation: Bool = false

    var body: some View {
        HStack {
            Spacer()
            if self.viewModel.isRecording {
               Circle()
                .frame(width: 14, height: 14, alignment: .center)
                .foregroundColor(.red)
                .opacity(isFlashingAnimation ? 1 : 0)
                .animation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true))
                .onAppear { self.isFlashingAnimation = true }
                .onDisappear { self.isFlashingAnimation = false }
                
                Text("0:00")
                    .foregroundColor(.secondary)
            }

            Text(self.viewModel.isRecording ? "tap to stop recording" : "tap to record audio")
                .padding(.vertical, 12.5)
                .padding(.horizontal, 30)
                .background(self.viewModel.isRecording ? Color("alertRed").opacity(0.4) : Color("pendingBtnColor"))
                .cornerRadius(12.5)
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.viewModel.isRecording.toggle()
                    }
                    self.viewModel.isRecording ? self.viewModel.startRecording() : self.viewModel.stopRecording()
                }

            if !self.viewModel.isRecording {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.isRecordingAudio = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24, alignment: .center)
                        .font(Font.title.weight(.regular))
                        .foregroundColor(.secondary)
                        .padding(10)
                }.padding(.horizontal, 8)
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.viewModel.isRecording = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.viewModel.isRecording = false
        }
    }
}
