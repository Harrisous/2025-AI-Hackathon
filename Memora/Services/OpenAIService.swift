//
//  OpenAIService.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation

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

@MainActor
class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessageStreaming(
        _ message: String,
        conversationHistory: [ChatMessage],
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        var messages: [OpenAIRequest.Message] = []
        
        // Add conversation history
        for chatMessage in conversationHistory {
            messages.append(OpenAIRequest.Message(
                role: chatMessage.role,
                content: chatMessage.content
            ))
        }
        
        // Add current user message
        messages.append(OpenAIRequest.Message(role: "user", content: message))
        
        let requestBody = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: messages,
            temperature: 0.7,
            stream: true
        )
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            var errorMessage = "API Error (\(httpResponse.statusCode))"
            if let data = try? await asyncBytes.reduce(into: Data()) { $0.append($1) },
               let errorString = String(data: data, encoding: .utf8) {
                errorMessage = errorString
            }
            throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        // Process streaming response (SSE format)
        var buffer = Data()
        
        for try await byte in asyncBytes {
            buffer.append(byte)
            
            // Check if we have a complete line
            if byte == 10 { // newline character
                if let line = String(data: buffer, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    buffer.removeAll()
                    
                    if line.isEmpty {
                        continue
                    }
                    
                    // Check for SSE format: "data: {...}"
                    if line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                        
                        if jsonString == "[DONE]" {
                            return
                        }
                        
                        guard let jsonData = jsonString.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let firstChoice = choices.first,
                              let delta = firstChoice["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }
                        
                        await onChunk(content)
                    }
                }
            }
        }
        
        // Process any remaining data in buffer
        if !buffer.isEmpty, let remaining = String(data: buffer, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !remaining.isEmpty {
            if remaining.hasPrefix("data: ") {
                let jsonString = String(remaining.dropFirst(6))
                if jsonString != "[DONE]",
                   let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    await onChunk(content)
                }
            }
        }
    }
}

