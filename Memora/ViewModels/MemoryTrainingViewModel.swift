//
//  MemoryTrainingViewModel.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import SwiftUI

enum TrainingPhase {
    case notStarted
    case warmup
    case warmupComplete
    case training
    case completed
}

@MainActor
class MemoryTrainingViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var phase: TrainingPhase = .notStarted
    @Published var currentQuestion: String?
    @Published var currentQuestionNumber: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var sessionSummary: String?
    @Published var sessionStats: (correct: Int, total: Int, percentage: Double)?
    
    private let trainingService: MemoryTrainingService
    private var sessionId: String?
    let speechManager: SpeechManager
    @Published var streamingMessageId: UUID?
    
    init(backendURL: String, apiKey: String) {
        self.trainingService = MemoryTrainingService(baseURL: backendURL, apiKey: apiKey)
        self.speechManager = SpeechManager(apiKey: apiKey)
    }
    
    // MARK: - Session Management
    
    func startSession() {
        guard phase == .notStarted else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await trainingService.startSession()
                
                guard response.success, let sessionId = response.sessionId, let message = response.message else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = response.error ?? "Failed to start session"
                    }
                    return
                }
                
                await MainActor.run {
                    self.sessionId = sessionId
                    self.phase = .warmup
                    self.isLoading = false
                    
                    let welcomeMessage = ChatMessage(
                        role: "assistant",
                        content: message
                    )
                    self.messages.append(welcomeMessage)
                    
                    // Speak the welcome message
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        self.speechManager.speak(message)
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
                switch phase {
                case .warmup:
                    // Handle warmup response
                    let response = try await trainingService.sendWarmupResponse(sessionId: sessionId, message: userMessageText)
                    
                    await MainActor.run {
                        if response.success, let message = response.message {
                            let assistantMessage = ChatMessage(
                                role: "assistant",
                                content: message
                            )
                            self.messages.append(assistantMessage)
                            
                            if response.readyForTraining == true {
                                self.phase = .warmupComplete
                                // Automatically start training after warmup
                                self.startTraining()
                            }
                            
                            self.speechManager.speak(message)
                        } else {
                            self.errorMessage = response.error ?? "Failed to process warmup response"
                        }
                        self.isLoading = false
                    }
                    
                case .training:
                    // Handle answer submission
                    let response = try await trainingService.submitAnswer(sessionId: sessionId, answer: userMessageText)
                    
                    // Since class is @MainActor, we can directly access properties
                    if response.success {
                        var feedbackMessage = ""
                        if let feedback = response.feedback {
                            feedbackMessage = feedback
                        }
                        
                        if response.correct == true {
                            feedbackMessage = "✓ Correct! \(feedbackMessage)"
                        } else if let hint = response.hint, !hint.isEmpty {
                            feedbackMessage = "\(feedbackMessage)\n\nHint: \(hint)"
                        }
                        
                        let assistantMessage = ChatMessage(
                            role: "assistant",
                            content: feedbackMessage
                        )
                        self.messages.append(assistantMessage)
                        self.speechManager.speak(feedbackMessage)
                        
                        if response.moveToNext == true {
                            // Move to next question
                            if response.attemptsExhausted == true {
                                // Wait a bit before showing next question
                                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                            }
                            await self.getNextQuestion()
                        }
                        // If move_to_next is false, user can try again
                    } else {
                        self.errorMessage = response.error ?? "Failed to submit answer"
                    }
                    self.isLoading = false
                    
                default:
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "Session not in a valid state for sending messages"
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
    
    func startTraining(numQuestions: Int = 3) {
        guard let sessionId = sessionId, phase == .warmupComplete || phase == .warmup else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await trainingService.startTraining(sessionId: sessionId, numQuestions: numQuestions)
                
                await MainActor.run {
                    if response.success, let question = response.question {
                        self.phase = .training
                        self.currentQuestion = question
                        self.currentQuestionNumber = response.questionNumber ?? 1
                        self.totalQuestions = response.totalQuestions ?? numQuestions
                        self.isLoading = false
                        
                        let questionMessage = ChatMessage(
                            role: "assistant",
                            content: "Question \(self.currentQuestionNumber)/\(self.totalQuestions):\n\n\(question)"
                        )
                        self.messages.append(questionMessage)
                        self.speechManager.speak(question)
                    } else {
                        self.errorMessage = response.error ?? "Failed to start training"
                        self.isLoading = false
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
                }
            }
        }
    }
    
    func getNextQuestion() async {
        guard let sessionId = sessionId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await trainingService.getNextQuestion(sessionId: sessionId)
            
            await MainActor.run {
                if response.success {
                    if response.phase == "completed" {
                        // Session completed, get summary
                        self.phase = .completed
                        self.getSummary()
                    } else if let question = response.question {
                        self.currentQuestion = question
                        self.currentQuestionNumber = response.questionNumber ?? 0
                        self.totalQuestions = response.totalQuestions ?? 0
                        self.isLoading = false
                        
                        let questionMessage = ChatMessage(
                            role: "assistant",
                            content: "Question \(self.currentQuestionNumber)/\(self.totalQuestions):\n\n\(question)"
                        )
                        self.messages.append(questionMessage)
                        self.speechManager.speak(question)
                    } else {
                        // No more questions, get summary
                        self.getSummary()
                    }
                } else {
                    self.errorMessage = response.error ?? "Failed to get next question"
                    self.isLoading = false
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
            }
        }
    }
    
    func getSummary() {
        guard let sessionId = sessionId else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await trainingService.getSummary(sessionId: sessionId)
                
                await MainActor.run {
                    if response.success {
                        self.phase = .completed
                        self.sessionSummary = response.summary
                        if let stats = response.stats {
                            self.sessionStats = (correct: stats.correct, total: stats.total, percentage: stats.percentage)
                        }
                        self.isLoading = false
                        
                        var summaryText = response.summary ?? "Session completed!"
                        if let stats = response.stats {
                            summaryText += "\n\n📊 Score: \(stats.correct)/\(stats.total) (\(String(format: "%.1f", stats.percentage))%)"
                        }
                        
                        let summaryMessage = ChatMessage(
                            role: "assistant",
                            content: summaryText
                        )
                        self.messages.append(summaryMessage)
                        self.speechManager.speak(summaryText)
                        
                        // End session
                        Task {
                            try? await self.trainingService.endSession(sessionId: sessionId)
                        }
                    } else {
                        self.errorMessage = response.error ?? "Failed to get summary"
                        self.isLoading = false
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
                }
            }
        }
    }
}

