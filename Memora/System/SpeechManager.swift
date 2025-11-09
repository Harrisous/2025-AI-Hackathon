//
//  SpeechManager.swift
//  Memora
//
//  Created by Rae Wang on 11/8/25.
//

import Foundation
import AVFoundation

struct OpenAITTSRequest: Codable {
    let model: String
    let input: String
    let voice: String
    let speed: Double
}

@MainActor
class SpeechManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private let audioDelegate: AudioPlayerDelegate
    private let apiKey: String
    @Published var isSpeaking = false
    @Published var isMuted = false
    @Published var isPaused = false
    
    // Streaming speech support
    private var speechQueue: [String] = []
    var isProcessingQueue = false // Made internal so delegate can access it
    private var currentStreamingText = ""
    private var lastSpokenIndex = 0
    
    init(apiKey: String) {
        self.apiKey = apiKey
        self.audioDelegate = AudioPlayerDelegate(manager: nil)
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // Set manager after initialization
        self.audioDelegate.manager = self
    }
    
    func speak(_ text: String) {
        // Stop any current speech
        stopSpeaking()
        
        // Don't speak if muted
        guard !isMuted else {
            return
        }
        
        // Fetch audio from OpenAI TTS
        Task {
            await fetchAndPlayAudio(text: text)
        }
    }
    
    private func fetchAndPlayAudio(text: String, waitForCompletion: Bool = false) async {
        do {
            // Create request
            let requestBody = OpenAITTSRequest(
                model: "tts-1",
                input: text,
                voice: "nova", // Warm and cheerful voice
                speed: 1
            )
            
            guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            // Fetch audio data
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Failed to get audio from OpenAI TTS")
                return
            }
            
            // Play audio
                   await MainActor.run {
                       playAudio(data: data, waitForCompletion: waitForCompletion)
                   }
            
        } catch {
            print("Error fetching TTS audio: \(error)")
        }
    }
    
    private func playAudio(data: Data, waitForCompletion: Bool = false) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isSpeaking = true
            isPaused = false
        } catch {
            print("Error playing audio: \(error)")
            isSpeaking = false
            if waitForCompletion {
                // Continue processing queue even if one fails
                isProcessingQueue = false
                if !speechQueue.isEmpty {
                    processSpeechQueue()
                }
            }
        }
    }
    
    // Start streaming speech - will speak sentences as they complete
    func startStreamingSpeech() {
        currentStreamingText = ""
        lastSpokenIndex = 0
        isProcessingQueue = false
        speechQueue.removeAll()
    }
    
    // Update streaming text and speak complete sentences
    func updateStreamingText(_ newText: String) {
        guard !isMuted else { return }
        
        // Only process if text has grown
        guard newText.count > lastSpokenIndex else { return }
        
        currentStreamingText = newText
        
        // Find complete sentences in the unspoken portion - process immediately
        var searchStart = newText.startIndex
        if lastSpokenIndex > 0 {
            searchStart = newText.index(newText.startIndex, offsetBy: lastSpokenIndex)
        }
        
        // Look for sentence endings and speak them immediately
        var currentPos = searchStart
        var sentenceStart = searchStart
        var foundSentence = false
        
        while currentPos < newText.endIndex {
            let char = newText[currentPos]
            
            // Check for sentence endings
            if char == "." || char == "!" || char == "?" {
                // Check next character
                let nextIndex = newText.index(after: currentPos)
                var isCompleteSentence = false
                
                if nextIndex >= newText.endIndex {
                    // End of text - complete sentence
                    isCompleteSentence = true
                } else {
                    let nextChar = newText[nextIndex]
                    // More lenient: accept sentence if followed by space, newline, or uppercase letter
                    if nextChar.isWhitespace || nextChar == "\n" || nextChar == "\r" || nextChar.isUppercase {
                        isCompleteSentence = true
                    }
                }
                
                if isCompleteSentence {
                    let sentence = String(newText[sentenceStart...currentPos]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if sentence.count > 2 { // Reduced minimum length for quicker response
                        // Speak immediately - don't wait
                        speakSentence(sentence)
                        foundSentence = true
                        
                        // Move to after the sentence and any whitespace
                        var afterSentence = newText.index(after: currentPos)
                        while afterSentence < newText.endIndex && (newText[afterSentence].isWhitespace || newText[afterSentence] == "\n" || newText[afterSentence] == "\r") {
                            afterSentence = newText.index(after: afterSentence)
                        }
                        lastSpokenIndex = newText.distance(from: newText.startIndex, to: afterSentence)
                        sentenceStart = afterSentence
                        currentPos = afterSentence
                        continue
                    }
                }
            }
            
            currentPos = newText.index(after: currentPos)
        }
    }
    
    // Finish streaming - speak any remaining text
    func finishStreamingSpeech() {
        if lastSpokenIndex < currentStreamingText.count {
            let remainingText = String(currentStreamingText.dropFirst(lastSpokenIndex)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !remainingText.isEmpty {
                speakSentence(remainingText)
            }
        }
        currentStreamingText = ""
        lastSpokenIndex = 0
    }
    
    private func extractCompleteSentences(from text: String) -> [String] {
        var sentences: [String] = []
        var currentSentence = ""
        
        var i = text.startIndex
        while i < text.endIndex {
            let char = text[i]
            currentSentence.append(char)
            
            // Check for sentence endings
            if char == "." || char == "!" || char == "?" {
                // Check if next character is space, newline, or end of string
                let nextIndex = text.index(after: i)
                if nextIndex >= text.endIndex {
                    // End of text - this is a complete sentence
                    if currentSentence.count > 3 {
                        sentences.append(currentSentence)
                        currentSentence = ""
                    }
                } else {
                    let nextChar = text[nextIndex]
                    if nextChar.isWhitespace || nextChar == "\n" || nextChar == "\r" {
                        // Sentence ending followed by whitespace
                        if currentSentence.count > 3 {
                            sentences.append(currentSentence)
                            currentSentence = ""
                        }
                    }
                }
            }
            i = text.index(after: i)
        }
        
        return sentences
    }
    
    private func speakSentence(_ sentence: String) {
        // Immediately start processing - don't wait for queue
        // This makes TTS start speaking as soon as a sentence is detected
        if !isProcessingQueue {
            // If not currently speaking, start immediately
            isProcessingQueue = true
            Task {
                await fetchAndPlayAudio(text: sentence, waitForCompletion: true)
            }
        } else {
            // If already speaking, add to queue
            speechQueue.append(sentence)
        }
    }
    
    func processSpeechQueue() {
        guard !isProcessingQueue && !speechQueue.isEmpty else { return }
        
        isProcessingQueue = true
        let sentence = speechQueue.removeFirst()
        
        Task {
            await fetchAndPlayAudio(text: sentence, waitForCompletion: true)
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
        isPaused = false
    }
    
    func pauseSpeaking() {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            isSpeaking = false
            isPaused = true
        }
    }
    
    func continueSpeaking() {
        if let player = audioPlayer, isPaused {
            player.play()
            isSpeaking = true
            isPaused = false
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stopSpeaking()
        }
    }
}

// Delegate to track audio playback state
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    weak var manager: SpeechManager?
    
    init(manager: SpeechManager? = nil) {
        self.manager = manager
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard let manager = manager else { return }
            
            // If we're processing a queue, continue with next item
            if manager.isProcessingQueue {
                manager.isProcessingQueue = false
                manager.processSpeechQueue()
            } else {
                manager.isSpeaking = false
                manager.isPaused = false
            }
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            guard let manager = manager else { return }
            
            // If we're processing a queue, continue with next item even on error
            if manager.isProcessingQueue {
                manager.isProcessingQueue = false
                manager.processSpeechQueue()
            } else {
                manager.isSpeaking = false
                manager.isPaused = false
            }
        }
    }
}
