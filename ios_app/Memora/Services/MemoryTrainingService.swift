//
//  MemoryTrainingService.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

// MARK: - Response Models
struct SessionStartResponse: Codable {
    let success: Bool
    let sessionId: String?
    let message: String?
    let phase: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case message
        case phase
        case error
    }
}

struct WarmupResponse: Codable {
    let success: Bool
    let message: String?
    let phase: String?
    let readyForTraining: Bool?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case phase
        case readyForTraining = "ready_for_training"
        case error
    }
}

struct TrainingStartResponse: Codable {
    let success: Bool
    let phase: String?
    let question: String?
    let questionNumber: Int?
    let totalQuestions: Int?
    let qaId: String?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case phase
        case question
        case questionNumber = "question_number"
        case totalQuestions = "total_questions"
        case qaId = "qa_id"
        case message
        case error
    }
}

struct AnswerResponse: Codable {
    let success: Bool
    let correct: Bool?
    let feedback: String?
    let hint: String?
    let attempt: Int?
    let attemptsRemaining: Int?
    let moveToNext: Bool?
    let attemptsExhausted: Bool?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case correct
        case feedback
        case hint
        case attempt
        case attemptsRemaining = "attempts_remaining"
        case moveToNext = "move_to_next"
        case attemptsExhausted = "attempts_exhausted"
        case error
    }
}

struct NextQuestionResponse: Codable {
    let success: Bool
    let phase: String?
    let question: String?
    let questionNumber: Int?
    let totalQuestions: Int?
    let qaId: String?
    let message: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case phase
        case question
        case questionNumber = "question_number"
        case totalQuestions = "total_questions"
        case qaId = "qa_id"
        case message
        case error
    }
}

struct SummaryResponse: Codable {
    let success: Bool
    let summary: String?
    let stats: SessionStats?
    let durationSeconds: Int?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case summary
        case stats
        case durationSeconds = "duration_seconds"
        case error
    }
    
    struct SessionStats: Codable {
        let correct: Int
        let total: Int
        let percentage: Double
    }
}

struct SessionStatusResponse: Codable {
    let success: Bool
    let sessionId: String?
    let phase: String?
    let currentQuestionIndex: Int?
    let totalQuestions: Int?
    let results: [String: QAResult]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case sessionId = "session_id"
        case phase
        case currentQuestionIndex = "current_question_index"
        case totalQuestions = "total_questions"
        case results
        case error
    }
    
    struct QAResult: Codable {
        let correct: Bool
        let attempts: Int
    }
}

// MARK: - Request Models
struct SessionStartRequest: Codable {
    let apiKey: String?
    let model: String?
    
    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case model
    }
}

struct WarmupRequest: Codable {
    let message: String
}

struct TrainingStartRequest: Codable {
    let numQuestions: Int?
    
    enum CodingKeys: String, CodingKey {
        case numQuestions = "num_questions"
    }
}

struct AnswerRequest: Codable {
    let answer: String
}

@MainActor
class MemoryTrainingService: ObservableObject {
    private let baseURL: String
    private let apiKey: String
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    // MARK: - Session Management
    
    func startSession() async throws -> SessionStartResponse {
        let url = URL(string: "\(baseURL)/api/session/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = SessionStartRequest(
            apiKey: apiKey,
            model: "gpt-5-mini-2025-08-07"
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(SessionStartResponse.self, from: data)
    }
    
    func sendWarmupResponse(sessionId: String, message: String) async throws -> WarmupResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/warmup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = WarmupRequest(message: message)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(WarmupResponse.self, from: data)
    }
    
    func startTraining(sessionId: String, numQuestions: Int = 3) async throws -> TrainingStartResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/training/start")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TrainingStartRequest(numQuestions: numQuestions)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(TrainingStartResponse.self, from: data)
    }
    
    func submitAnswer(sessionId: String, answer: String) async throws -> AnswerResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/answer")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AnswerRequest(answer: answer)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(AnswerResponse.self, from: data)
    }
    
    func getNextQuestion(sessionId: String) async throws -> NextQuestionResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/next")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(NextQuestionResponse.self, from: data)
    }
    
    func getSummary(sessionId: String) async throws -> SummaryResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/summary")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(SummaryResponse.self, from: data)
    }
    
    func endSession(sessionId: String) async throws -> SummaryResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/end")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(SummaryResponse.self, from: data)
    }
    
    func getStatus(sessionId: String) async throws -> SessionStatusResponse {
        let url = URL(string: "\(baseURL)/api/session/\(sessionId)/status")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "MemoryTrainingService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MemoryTrainingService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
        }
        
        return try JSONDecoder().decode(SessionStatusResponse.self, from: data)
    }
}

