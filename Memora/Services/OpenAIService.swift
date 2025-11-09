//
//  OpenAIService.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: String, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let stream: Bool
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail?
    
    struct ErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

@MainActor
class OpenAIService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(_ message: String, conversationHistory: [ChatMessage]) async throws -> String {
        // Validate API key
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENAI_API_KEY_HERE", apiKey.hasPrefix("sk-") else {
            throw NSError(domain: "OpenAIService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Invalid API key. Please check your API key in APIConfig.swift"])
        }
        
        // Prepare messages for API (convert ChatMessage to API format)
        var apiMessages: [OpenAIRequest.Message] = [
            OpenAIRequest.Message(
                role: "system",
                content: "You are a helpful assistant for memory recall. Help users remember their memories in a warm, supportive way. Be gentle and encouraging."
            )
        ]
        
        // Add conversation history (filter out system messages if any)
        for chatMessage in conversationHistory {
            // Only include user and assistant messages in history
            if chatMessage.role == "user" || chatMessage.role == "assistant" {
                apiMessages.append(OpenAIRequest.Message(
                    role: chatMessage.role,
                    content: chatMessage.content
                ))
            }
        }
        
        // Add current user message
        apiMessages.append(OpenAIRequest.Message(
            role: "user",
            content: message
        ))
        
        // Create request
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: apiMessages,
            temperature: 0.7,
            stream: false // Non-streaming for backward compatibility
        )
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to decode error response from OpenAI
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                let errorMsg = errorResponse.error?.message ?? "Unknown API error"
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMsg)"])
            } else {
                // Fallback to raw error message
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
            }
        }
        
        // Decode response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let firstChoice = openAIResponse.choices.first else {
            throw NSError(domain: "OpenAIService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No response from API"])
        }
        
        return firstChoice.message.content
    }
    
    // Streaming version
    func sendMessageStreaming(_ message: String, conversationHistory: [ChatMessage], onChunk: @escaping (String) async -> Void) async throws {
        // Validate API key
        guard !apiKey.isEmpty, apiKey != "YOUR_OPENAI_API_KEY_HERE", apiKey.hasPrefix("sk-") else {
            throw NSError(domain: "OpenAIService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Invalid API key. Please check your API key in APIConfig.swift"])
        }
        
        // Prepare messages for API
        var apiMessages: [OpenAIRequest.Message] = [
            OpenAIRequest.Message(
                role: "system",
                content: "You are a helpful assistant for memory recall. Help users remember their memories in a warm, supportive way. Be gentle and encouraging."
            )
        ]
        
        // Add conversation history
        for chatMessage in conversationHistory {
            if chatMessage.role == "user" || chatMessage.role == "assistant" {
                apiMessages.append(OpenAIRequest.Message(
                    role: chatMessage.role,
                    content: chatMessage.content
                ))
            }
        }
        
        // Add current user message
        apiMessages.append(OpenAIRequest.Message(
            role: "user",
            content: message
        ))
        
        // Create request with streaming enabled
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: apiMessages,
            temperature: 0.7,
            stream: true
        )
        
        // Create URL request
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Create streaming task
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            // Read error data
            var errorData = Data()
            for try await byte in asyncBytes {
                errorData.append(byte)
            }
            
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: errorData) {
                let errorMsg = errorResponse.error?.message ?? "Unknown API error"
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMsg)"])
            } else {
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (\(httpResponse.statusCode)): \(errorMessage)"])
            }
        }
        
        // Parse Server-Sent Events stream
        var buffer = ""
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                
                if jsonString == "[DONE]" {
                    break
                }
                
                guard let jsonData = jsonString.data(using: .utf8) else { continue }
                
                do {
                    let streamResponse = try JSONDecoder().decode(StreamResponse.self, from: jsonData)
                    if let delta = streamResponse.choices.first?.delta.content {
                        // Send chunk immediately - no delay here
                        // Voice needs chunks immediately, display will be slowed separately
                        await onChunk(delta)
                    }
                } catch {
                    // Skip malformed JSON
                    continue
                }
            }
        }
    }
}

// Stream response structures
struct StreamResponse: Codable {
    let choices: [StreamChoice]
    
    struct StreamChoice: Codable {
        let delta: StreamDelta
        
        struct StreamDelta: Codable {
            let content: String?
        }
    }
}

