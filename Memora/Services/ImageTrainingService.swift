//
//  ImageTrainingService.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

// MARK: - Response Models for Image Training

struct ImageStartResponse: Codable {
    let success: Bool
    let sessionId: String?
    let greeting: String?
    let imageUrl: String?
    let question: String?
    let totalQuestions: Int?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case greeting
        case imageUrl = "image_url"
        case question
        case totalQuestions = "total_questions"
        case error
    }
}

struct ImageAnswerResponse: Codable {
    let success: Bool
    let correct: Bool?
    let response: String?
    let imageUrl: String?
    let nextQuestion: String?
    let isEnd: Bool?
    let finalMessage: String?
    let score: Score?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case correct
        case response
        case imageUrl = "image_url"
        case nextQuestion = "next_question"
        case isEnd = "is_end"
        case finalMessage = "final_message"
        case score
        case error
    }
    
    struct Score: Codable {
        let correct: Int
        let total: Int
    }
}

// MARK: - Request Models for Image Training

struct ImageAnswerRequest: Codable {
    let sessionId: String
    let answer: String
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case answer
    }
}

// MARK: - Image Training Service

@MainActor
class ImageTrainingService: ObservableObject {
    private let baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    // MARK: - API Methods
    
    func startConversation() async throws -> ImageStartResponse {
        let url = URL(string: "\(baseURL)/api/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add ngrok header to bypass browser warning
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ImageTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ImageTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(ImageStartResponse.self, from: data)
    }
    
    func submitAnswer(sessionId: String, answer: String) async throws -> ImageAnswerResponse {
        let url = URL(string: "\(baseURL)/api/answer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        
        let requestBody = ImageAnswerRequest(sessionId: sessionId, answer: answer)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ImageTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ImageTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(ImageAnswerResponse.self, from: data)
    }
}

