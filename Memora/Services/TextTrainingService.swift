//
//  TextTrainingService.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

// MARK: - Response Models for Text Training

struct TextStartResponse: Codable {
    let success: Bool
    let sessionId: String?
    let greeting: String?
    let question: String?
    let memoryId: String?
    let person: String?
    let event: String?
    let hasHint: Bool?
    let type: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case greeting
        case question
        case memoryId = "memory_id"
        case person
        case event
        case hasHint = "has_hint"
        case type
        case error
    }
}

struct TextAnswerResponse: Codable {
    let success: Bool
    let response: String?
    let nextQuestion: String?
    let type: String?
    let isEnd: Bool?
    let score: Score?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case response
        case nextQuestion = "next_question"
        case type
        case isEnd = "is_end"
        case score
        case error
    }
    
    struct Score: Codable {
        let correct: Int
        let total: Int
    }
}

struct TextAskResponse: Codable {
    let success: Bool
    let answer: String?
    let error: String?
}

// MARK: - Request Models for Text Training

struct TextAnswerRequest: Codable {
    let sessionId: String
    let answer: String
    let question: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case answer
        case question
        case type
    }
}

struct TextAskRequest: Codable {
    let sessionId: String
    let question: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case question
    }
}

// MARK: - Text Training Service

@MainActor
class TextTrainingService: ObservableObject {
    private let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    // MARK: - API Methods
    
    func startConversation() async throws -> TextStartResponse {
        let url = URL(string: "\(baseURL)/api/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TextTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TextTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(TextStartResponse.self, from: data)
    }
    
    func submitAnswer(sessionId: String, answer: String, question: String) async throws -> TextAnswerResponse {
        let url = URL(string: "\(baseURL)/api/answer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TextAnswerRequest(
            sessionId: sessionId,
            answer: answer,
            question: question,
            type: "conversation"
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TextTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TextTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(TextAnswerResponse.self, from: data)
    }
    
    func askQuestion(sessionId: String, question: String) async throws -> TextAskResponse {
        let url = URL(string: "\(baseURL)/api/ask")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TextAskRequest(sessionId: sessionId, question: question)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TextTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TextTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(TextAskResponse.self, from: data)
    }
}

