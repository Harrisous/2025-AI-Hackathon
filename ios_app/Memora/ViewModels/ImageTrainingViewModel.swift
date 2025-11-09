//
//  ImageTrainingViewModel.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import SwiftUI

@MainActor
class ImageTrainingViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentQuestion: String?
    @Published var currentImageUrl: String?
    @Published var sessionId: String?
    @Published var score: (correct: Int, total: Int)?
    @Published var totalQuestions: Int = 0
    @Published var isEnd: Bool = false
    
    private let trainingService: ImageTrainingService
    let speechManager: SpeechManager
    
    init(baseURL: String, apiKey: String) {
        self.trainingService = ImageTrainingService(baseURL: baseURL)
        self.speechManager = SpeechManager(apiKey: apiKey)
    }
    
    // MARK: - Session Management
    
    func startSession() {
        guard sessionId == nil else { return }
        
        isLoading = true
        errorMessage = nil
        isEnd = false
        
        Task {
            do {
                let response = try await trainingService.startConversation()
                
                guard response.success, let sessionId = response.sessionId else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = response.error ?? "Failed to start session"
                    }
                    return
                }
                
                await MainActor.run {
                    self.sessionId = sessionId
                    self.isLoading = false
                    self.totalQuestions = response.totalQuestions ?? 0
                    
                    // Set image URL
                    if let imageUrl = response.imageUrl {
                        self.currentImageUrl = imageUrl
                    }
                    
                    // Add greeting if available - the queue will handle sequencing
                    if let greeting = response.greeting {
                        let greetingMessage = ChatMessage(
                            role: "assistant",
                            content: greeting
                        )
                        self.messages.append(greetingMessage)
                        self.speechManager.speak(greeting)
                    }
                    
                    // Add first question - will be queued after greeting
                    if let question = response.question {
                        self.currentQuestion = question
                        let questionMessage = ChatMessage(
                            role: "assistant",
                            content: question
                        )
                        self.messages.append(questionMessage)
                        // This will be queued and play after greeting finishes
                        self.speechManager.speak(question)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    let errorDescription: String
                    if let nsError = error as NSError? {
                        errorDescription = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    } else {
                        errorDescription = error.localizedDescription
                    }
                    self.errorMessage = errorDescription
                    
                    let errorChatMessage = ChatMessage(
                        role: "assistant",
                        content: "I'm sorry, I encountered an error: \(errorDescription)"
                    )
                    self.messages.append(errorChatMessage)
                }
            }
        }
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let sessionId = sessionId else {
            return
        }
        
        let userMessageText = inputText
        let userMessage = ChatMessage(role: "user", content: userMessageText)
        messages.append(userMessage)
        
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await trainingService.submitAnswer(
                    sessionId: sessionId,
                    answer: userMessageText
                )
                
                await MainActor.run {
                    if response.success {
                        // Update score
                        if let score = response.score {
                            self.score = (correct: score.correct, total: score.total)
                        }
                        
                        // Update image URL if available
                        if let imageUrl = response.imageUrl {
                            self.currentImageUrl = imageUrl
                        }
                        
                        // Add response message if available - queue will handle sequencing
                        if let responseText = response.response {
                            let assistantMessage = ChatMessage(
                                role: "assistant",
                                content: responseText
                            )
                            self.messages.append(assistantMessage)
                            self.speechManager.speak(responseText)
                        }
                        
                        // Check if session ended
                        if response.isEnd == true {
                            self.isEnd = true
                            
                            // Add final message if available - will be queued after response
                            if let finalMessage = response.finalMessage {
                                let finalMessageChat = ChatMessage(
                                    role: "assistant",
                                    content: finalMessage
                                )
                                self.messages.append(finalMessageChat)
                                self.speechManager.speak(finalMessage)
                            }
                            
                            self.isLoading = false
                        } else {
                            // Move to next question - will be queued after response
                            if let nextQuestion = response.nextQuestion {
                                self.currentQuestion = nextQuestion
                                let nextQuestionMessage = ChatMessage(
                                    role: "assistant",
                                    content: nextQuestion
                                )
                                self.messages.append(nextQuestionMessage)
                                self.speechManager.speak(nextQuestion)
                            }
                            self.isLoading = false
                        }
                    } else {
                        self.errorMessage = response.error ?? "Failed to submit answer"
                        self.isLoading = false
                        
                        let errorChatMessage = ChatMessage(
                            role: "assistant",
                            content: "I'm sorry, I encountered an error: \(self.errorMessage ?? "Unknown error")"
                        )
                        self.messages.append(errorChatMessage)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    let errorDescription: String
                    if let nsError = error as NSError? {
                        errorDescription = nsError.userInfo[NSLocalizedDescriptionKey] as? String ?? error.localizedDescription
                    } else {
                        errorDescription = error.localizedDescription
                    }
                    self.errorMessage = errorDescription
                    
                    let errorChatMessage = ChatMessage(
                        role: "assistant",
                        content: "I'm sorry, I encountered an error: \(errorDescription)"
                    )
                    self.messages.append(errorChatMessage)
                }
            }
        }
    }
}

