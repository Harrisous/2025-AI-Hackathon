//
//  TextTrainingViewModel.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import SwiftUI

@MainActor
class TextTrainingViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentQuestion: String?
    @Published var sessionId: String?
    @Published var score: (correct: Int, total: Int)?
    @Published var isEnd: Bool = false
    
    private let trainingService: TextTrainingService
    let speechManager: SpeechManager
    
    init(baseURL: String, apiKey: String) {
        self.trainingService = TextTrainingService(baseURL: baseURL)
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
                    
                    // Add greeting if available
                    if let greeting = response.greeting {
                        let greetingMessage = ChatMessage(
                            role: "assistant",
                            content: greeting
                        )
                        self.messages.append(greetingMessage)
                        self.speechManager.speak(greeting)
                    }
                    
                    // Add first question
                    if let question = response.question {
                        self.currentQuestion = question
                        let questionMessage = ChatMessage(
                            role: "assistant",
                            content: question
                        )
                        self.messages.append(questionMessage)
                        // Queue the question - it will play after greeting finishes
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
              let sessionId = sessionId,
              let question = currentQuestion else {
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
                    answer: userMessageText,
                    question: question
                )
                
                await MainActor.run {
                    if response.success {
                        // Add response message
                        if let responseText = response.response {
                            let assistantMessage = ChatMessage(
                                role: "assistant",
                                content: responseText
                            )
                            self.messages.append(assistantMessage)
                            self.speechManager.speak(responseText)
                        }
                        
                        // Update score
                        if let score = response.score {
                            self.score = (correct: score.correct, total: score.total)
                        }
                        
                        // Check if session ended
                        if response.isEnd == true {
                            self.isEnd = true
                            self.isLoading = false
                            return
                        }
                        
                        // Move to next question
                        if let nextQuestion = response.nextQuestion {
                            self.currentQuestion = nextQuestion
                            // Add next question message
                            let nextQuestionMessage = ChatMessage(
                                role: "assistant",
                                content: nextQuestion
                            )
                            self.messages.append(nextQuestionMessage)
                            // Queue the next question - it will play after response finishes
                            self.speechManager.speak(nextQuestion)
                            self.isLoading = false
                        } else {
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
    
    func askQuestion(_ question: String) {
        guard let sessionId = sessionId else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await trainingService.askQuestion(sessionId: sessionId, question: question)
                
                await MainActor.run {
                    if response.success, let answer = response.answer {
                        let assistantMessage = ChatMessage(
                            role: "assistant",
                            content: answer
                        )
                        self.messages.append(assistantMessage)
                        self.speechManager.speak(answer)
                    } else {
                        self.errorMessage = response.error ?? "Failed to get answer"
                    }
                    self.isLoading = false
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
                }
            }
        }
    }
}

