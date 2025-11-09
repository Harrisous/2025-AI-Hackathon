//
//  ChatViewModel.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let openAIService: OpenAIService
    let speechManager: SpeechManager
    @Published var streamingMessageId: UUID?
    
    init(apiKey: String) {
        self.openAIService = OpenAIService(apiKey: apiKey)
        self.speechManager = SpeechManager(apiKey: apiKey)
        
        // Add welcome message
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeText = "Hello! I'm here to help you recall your memories. What would you like to remember today?"
        let welcomeMessage = ChatMessage(
            role: "assistant",
            content: welcomeText
        )
        messages.append(welcomeMessage)
        
        // Automatically speak the welcome message after a short delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            speechManager.speak(welcomeText)
        }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let userMessage = ChatMessage(role: "user", content: inputText)
        messages.append(userMessage)
        
        let messageToSend = inputText
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        // Create placeholder for streaming response
        let assistantMessageId = UUID()
        streamingMessageId = assistantMessageId
        let assistantMessage = ChatMessage(
            id: assistantMessageId,
            role: "assistant",
            content: ""
        )
        messages.append(assistantMessage)
        
        Task {
            var fullResponse = ""
            var displayedLength = 0
            var lastDisplayTime = ContinuousClock.now
            let displaySpeed: Duration = .milliseconds(60) // 60ms per character (slower text display)
            
            // Start streaming speech
            await MainActor.run {
                speechManager.startStreamingSpeech()
            }
            
            // Start background task for gradual text display
            let displayTask = Task {
                while !Task.isCancelled {
                    await MainActor.run {
                        if displayedLength < fullResponse.count {
                            let timeSinceLastDisplay = ContinuousClock.now - lastDisplayTime
                            
                            if timeSinceLastDisplay >= displaySpeed {
                                displayedLength += 1
                                let displayText = String(fullResponse.prefix(displayedLength))
                                
                                if let index = self.messages.firstIndex(where: { $0.id == assistantMessageId }) {
                                    self.messages[index] = ChatMessage(
                                        id: assistantMessageId,
                                        role: "assistant",
                                        content: displayText
                                    )
                                }
                                lastDisplayTime = ContinuousClock.now
                            }
                        }
                    }
                    try? await Task.sleep(nanoseconds: 10_000_000) // Check every 10ms
                }
            }
            
            do {
                // Get conversation history excluding the last two messages (user message and empty assistant message)
                let history = Array(messages.dropLast(2))
                
                // Use streaming API
                try await openAIService.sendMessageStreaming(messageToSend, conversationHistory: history) { chunk in
                    await MainActor.run {
                        fullResponse += chunk
                        
                        // CRITICAL: Update TTS IMMEDIATELY - zero delay for voice
                        // Voice processes instantly and starts speaking as soon as sentences are detected
                        self.speechManager.updateStreamingText(fullResponse)
                        // Note: Text display is handled by displayTask above (gradual, slower)
                    }
                }
                
                // Wait for display to catch up
                while displayedLength < fullResponse.count {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                
                displayTask.cancel()
                
                await MainActor.run {
                    isLoading = false
                    streamingMessageId = nil
                    
                    // Finalize the message with complete content
                    if let index = self.messages.firstIndex(where: { $0.id == assistantMessageId }) {
                        self.messages[index] = ChatMessage(
                            id: assistantMessageId,
                            role: "assistant",
                            content: fullResponse
                        )
                    }
                    
                    // Finish streaming speech - speak any remaining text
                    speechManager.finishStreamingSpeech()
                }
            } catch {
                await MainActor.run {
                    let errorDescription: String
                    if let nsError = error as NSError? {
                        errorDescription = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    } else {
                        errorDescription = error.localizedDescription
                    }
                    
                    errorMessage = errorDescription
                    isLoading = false
                    streamingMessageId = nil
                    
                    // Remove the empty streaming message
                    if let index = self.messages.firstIndex(where: { $0.id == assistantMessageId }) {
                        self.messages.remove(at: index)
                    }
                    
                    // Add error message to chat with more details
                    var helpText = ""
                    if errorDescription.contains("429") || errorDescription.contains("quota") {
                        helpText = "\n\nThis is a billing/quota issue. Please:\n• Check your OpenAI billing at https://platform.openai.com/account/billing\n• Add credits or set up payment method\n• Verify you haven't exceeded your usage limits"
                    } else if errorDescription.contains("401") || errorDescription.contains("Unauthorized") {
                        helpText = "\n\nThis is an authentication issue. Please:\n• Verify your API key is correct in APIConfig.swift\n• Make sure the API key starts with 'sk-'"
                    } else {
                        helpText = "\n\nPlease check:\n• Your API key is valid\n• You have internet connection\n• Your OpenAI account has credits"
                    }
                    
                    let errorChatMessage = ChatMessage(
                        role: "assistant",
                        content: "I'm sorry, I encountered an error: \(errorDescription)\(helpText)"
                    )
                    messages.append(errorChatMessage)
                    
                    // Don't speak error messages
                }
            }
        }
    }
    
    
}
