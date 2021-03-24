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
        HStack(alignment: .center) {
            Spacer()
            if !self.viewModel.recordingsList.isEmpty {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                     if self.viewModel.isPlayingAudio {
                        self.viewModel.stopAudioRecording()
                     } else {
                        self.viewModel.playAudioRecording()
                     }
                }) {
                    Image(systemName: self.viewModel.isPlayingAudio ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20, alignment: .center)
                        .font(Font.title.weight(.regular))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                }
                
                Text(self.viewModel.durationString)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .onAppear() {
                        self.viewModel.prepAudio()
                        self.viewModel.getTotalPlaybackDurationString()
                    }
                    .onReceive(self.viewModel.timer) { time in
                        self.viewModel.getTotalPlaybackDurationString()
                    }
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    withAnimation {
                        self.viewModel.isRecording.toggle()
                    }
                    if !self.viewModel.isRecording {
                        self.viewModel.stopRecording()
                    } else {
                        self.viewModel.startRecording()
                    }
                }) {
                    VStack {
                        if self.viewModel.isRecording {
                            Text(self.viewModel.getTotalDurationString())
                                .fontWeight(.semibold)
                                .onReceive(self.viewModel.timer) { time in
                                    if self.viewModel.time == 100 {
                                        self.viewModel.stopRecording()
                                    }
                                    self.viewModel.time += 1
                                }
                        }

                        Text(self.viewModel.isRecording ? "tap to stop" : "tap to record audio")
                            .foregroundColor(.secondary)
                            .font(self.viewModel.isRecording ? .caption : .none)
                    }.frame(width: Constants.screenWidth * 0.5, height: 40)
                    .background(self.viewModel.isRecording ? Color("alertRed").opacity(0.4) : Color("pendingBtnColor"))
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                    .cornerRadius(12.5)
                }.buttonStyle(ClickButtonStyle())
            }

            if !self.viewModel.isRecording {
                if !self.viewModel.recordingsList.isEmpty {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        self.viewModel.fetchAudioRecording(completion: { recording in
                            self.viewModel.deleteAudioFile()
                        })
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .font(Font.title.weight(.regular))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                    }
                }
                
                Button(action: {
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
                        .padding(.trailing, 10)
                        .padding(.leading, 4)
                }
            } else {
                Circle()
                    .frame(width: 14, height: 14, alignment: .center)
                    .padding(.trailing, 15)
                    .padding(.leading, 9)
                    .foregroundColor(.red)
                    .opacity(isFlashingAnimation ? 1 : 0)
                    .animation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true))
                    .onAppear { self.isFlashingAnimation = true }
                    .onDisappear { self.isFlashingAnimation = false }
            }
        }.onAppear() {
            self.viewModel.fetchAudioRecording(completion: { _ in })
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.viewModel.isRecording = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.viewModel.isRecording = false
        }
    }
}