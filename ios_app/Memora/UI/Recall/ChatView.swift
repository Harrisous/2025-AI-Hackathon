//
//  ChatView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var speechManager: SpeechManager
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        self.speechManager = viewModel.speechManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Audio controls toolbar
            AudioControlsToolbar(speechManager: speechManager)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Palette.paper.opacity(0.5))
            
            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(
                                message: message,
                                isStreaming: viewModel.isLoading && viewModel.streamingMessageId == message.id
                            )
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
                .onChange(of: viewModel.messages.last?.content ?? "") { _ in
                    // Scroll to bottom when message content updates (for streaming)
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Scroll to bottom when new message is added
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type your message...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...4)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.inputText.isEmpty ? Color.gray : Color(red: 0.910, green: 0.722, blue: 0.675))
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Palette.paper)
        }
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Palette.shadow, radius: 12, x: 0, y: 8)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false
    
    var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if message.content.isEmpty && isStreaming {
                    // Show loading indicator for empty streaming messages
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Thinking...")
                            .font(.system(size: 20, design: .rounded))
                            .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                } else {
                    HStack(spacing: 0) {
                        Text(message.content)
                            .font(.system(size: 24, design: .rounded))
                            .foregroundColor(isUser ? .white : Color(red: 0.184, green: 0.165, blue: 0.145))
                        
                        // Add a subtle blinking cursor effect when streaming
                        if isStreaming && !isUser {
                            Rectangle()
                                .fill(Color(red: 0.184, green: 0.165, blue: 0.145))
                                .frame(width: 2, height: 24)
                                .opacity(0.8)
                                .padding(.leading, 2)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isStreaming)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isUser
                            ? Color(red: 0.910, green: 0.722, blue: 0.675)
                            : Color.white.opacity(0.9)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            
            if !isUser {
                Spacer(minLength: 40)
            }
        }
    }
}

#Preview {
    ZStack {
        Palette.paper.ignoresSafeArea()
        
        ChatView(viewModel: ChatViewModel(apiKey: "preview-key"))
            .frame(height: 600)
            .padding()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

struct AudioControlsToolbar: View {
    @ObservedObject var speechManager: SpeechManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Mute/Unmute button
            Button(action: {
                speechManager.toggleMute()
                Haptics.soft()
            }) {
                Image(systemName: speechManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 30))
                    .foregroundColor(speechManager.isMuted ? Color.gray : Color(red: 0.184, green: 0.165, blue: 0.145))
                    .frame(width: 42, height: 42)
            }
            
            // Pause/Resume button (only show when speaking or paused)
            if speechManager.isSpeaking || speechManager.isPaused {
                Button(action: {
                    if speechManager.isSpeaking {
                        speechManager.pauseSpeaking()
                    } else {
                        speechManager.continueSpeaking()
                    }
                    Haptics.soft()
                }) {
                    Image(systemName: speechManager.isSpeaking ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                        .frame(width: 32, height: 32)
                }
                
                // Stop button
                Button(action: {
                    speechManager.stopSpeaking()
                    Haptics.soft()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                        .frame(width: 32, height: 32)
                }
            }
            
            Spacer()
            
            // Status indicator
            if speechManager.isSpeaking {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 0.910, green: 0.722, blue: 0.675))
                        .frame(width: 6, height: 6)
                        .opacity(speechManager.isSpeaking ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: speechManager.isSpeaking)
                    
                    Text("Speaking...")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.6))
                }
            }
        }
    }
}

