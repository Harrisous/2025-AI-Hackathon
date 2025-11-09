//
//  TrainingChatView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

// Text Training Chat View
struct TextTrainingChatView: View {
    @ObservedObject var viewModel: TextTrainingViewModel
    @ObservedObject var speechManager: SpeechManager
    
    init(viewModel: TextTrainingViewModel) {
        self.viewModel = viewModel
        self.speechManager = viewModel.speechManager
    }
    
    var body: some View {
        TrainingChatContentView(
            messages: viewModel.messages,
            inputText: $viewModel.inputText,
            isLoading: viewModel.isLoading,
            speechManager: speechManager,
            onSend: { viewModel.sendMessage() }
        )
    }
}

// Image Training Chat View
struct ImageTrainingChatView: View {
    @ObservedObject var viewModel: ImageTrainingViewModel
    @ObservedObject var speechManager: SpeechManager
    
    init(viewModel: ImageTrainingViewModel) {
        self.viewModel = viewModel
        self.speechManager = viewModel.speechManager
    }
    
    var body: some View {
        TrainingChatContentView(
            messages: viewModel.messages,
            inputText: $viewModel.inputText,
            isLoading: viewModel.isLoading,
            speechManager: speechManager,
            onSend: { viewModel.sendMessage() }
        )
    }
}

// Shared Chat Content View
struct TrainingChatContentView: View {
    let messages: [ChatMessage]
    @Binding var inputText: String
    let isLoading: Bool
    @ObservedObject var speechManager: SpeechManager
    let onSend: () -> Void
    
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
                        ForEach(messages) { message in
                            TrainingChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                }
                .onChange(of: messages.count) { _ in
                    // Scroll to bottom when new message is added
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 12) {
                TextField("Type your answer...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...4)
                    .onSubmit {
                        onSend()
                    }
                
                Button(action: {
                    onSend()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(inputText.isEmpty ? Color.gray : Color(red: 0.910, green: 0.722, blue: 0.675))
                }
                .disabled(inputText.isEmpty || isLoading)
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

struct TrainingChatBubble: View {
    let message: ChatMessage
    
    var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 24, design: .rounded))
                    .foregroundColor(isUser ? .white : Color(red: 0.184, green: 0.165, blue: 0.145))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        isUser
                            ? Color(red: 0.910, green: 0.722, blue: 0.675)
                            : Color.white.opacity(0.9)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            
            if !isUser {
                Spacer(minLength: 40)
            }
        }
    }
}

