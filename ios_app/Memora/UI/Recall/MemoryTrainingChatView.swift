//
//  MemoryTrainingChatView.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import SwiftUI

struct MemoryTrainingChatView: View {
    @ObservedObject var viewModel: MemoryTrainingViewModel
    @ObservedObject var speechManager: SpeechManager
    
    init(viewModel: MemoryTrainingViewModel) {
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
                    // Scroll to bottom when message content updates
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
                TextField(
                    viewModel.phase == .training ? "Type your answer..." : "Type your message...",
                    text: $viewModel.inputText,
                    axis: .vertical
                )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...4)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                    .disabled(viewModel.phase == .completed)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(viewModel.inputText.isEmpty || viewModel.isLoading || viewModel.phase == .completed ? Color.gray : Color(red: 0.910, green: 0.722, blue: 0.675))
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading || viewModel.phase == .completed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Palette.paper)
            
            // Show summary if completed
            if viewModel.phase == .completed, let stats = viewModel.sessionStats {
                VStack(spacing: 8) {
                    Text("Session Completed!")
                        .font(.system(size: 24, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145))
                    
                    Text("Score: \(stats.correct)/\(stats.total) (\(String(format: "%.1f", stats.percentage))%)")
                        .font(.system(size: 20, design: .rounded))
                        .foregroundColor(Color(red: 0.184, green: 0.165, blue: 0.145).opacity(0.7))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.5))
            }
        }
        .background(Palette.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Palette.shadow, radius: 12, x: 0, y: 8)
    }
}

// Note: ChatBubble and AudioControlsToolbar are defined in ChatView.swift
// and are accessible here since they're in the same module

#Preview {
    ZStack {
        Palette.paper.ignoresSafeArea()
        
        MemoryTrainingChatView(viewModel: MemoryTrainingViewModel(
            backendURL: "http://10.197.154.239:8000",
            apiKey: "test-key"
        ))
            .frame(height: 600)
            .padding()
    }
    .previewInterfaceOrientation(.landscapeLeft)
    .previewLayout(.fixed(width: 1180, height: 820))
}

