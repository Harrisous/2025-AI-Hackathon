# Memora

A beautiful iOS app designed to support memory training and cognitive health through AI-powered interactive sessions, memory galleries, and comprehensive cognitive assessments.

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-blue.svg)

## Overview

Memora is an iOS application that helps individuals with memory challenges through personalized training sessions, memory storage, and cognitive assessments. The app features an elegant journal-style interface and leverages AI to create adaptive memory training experiences.

## Features

### 🧠 Memory Training
- **Image Training**: Upload and practice recalling images and associated information
- **Text Training**: Interactive text-based memory exercises with AI-generated questions
- **Adaptive Learning**: AI-powered sessions that adjust to individual performance
- **Progress Tracking**: Monitor performance with detailed feedback and statistics

### 🖼️ Memory Gallery
- **Visual Memory Bank**: Store and organize memories with images
- **Easy Upload**: Simple interface to add new memories with photos
- **Memory Cards**: Beautiful card-based interface to browse stored memories
- **Persistent Storage**: Memories are saved locally on your device

### 🧪 Cognitive Assessment
- **MoCA Test**: Integrated Montreal Cognitive Assessment (MoCA) PDF viewer
- **Standardized Testing**: Access to professional cognitive screening tools

### 👨‍👩‍👧‍👦 Caregiver Dashboard
- **Web Integration**: Access to caregiver dashboard for monitoring and support
- **Progress Tracking**: View training sessions and performance metrics

### 🎯 Additional Features
- **Siri Shortcuts**: Start memory training sessions using voice commands
- **Daily Reminders**: Scheduled notifications to encourage regular practice
- **Chat Interface**: Conversational AI assistant for memory recall
- **Speech Integration**: Text-to-speech and speech recognition capabilities
- **Beautiful UI**: Journal-inspired design with custom color palette

## Architecture

### Project Structure

```
Memora/
├── AppIntents/              # Siri Shortcuts integration
│   ├── StartMemoryRecallIntent.swift
│   └── MemeraiShortcuts.swift
├── CaregiverDashboard/      # Caregiver dashboard view
├── Config/                  # API configuration
│   └── APIConfig.swift
├── Models/                  # Data models
│   ├── MemoryEntry.swift
│   └── ChatMessage.swift
├── Services/                # Business logic and API services
│   ├── MemoryTrainingService.swift
│   ├── OpenAIService.swift
│   ├── ImageTrainingService.swift
│   ├── TextTrainingService.swift
│   └── MemoryStorage.swift
├── System/                  # System integrations
│   ├── NotificationManager.swift
│   ├── SpeechManager.swift
│   └── Haptics.swift
├── UI/                      # User interface
│   ├── Components/          # Reusable UI components
│   ├── HomePage/            # Main home screen
│   ├── Launch/              # Launch screen
│   ├── MemoryGallery/       # Memory gallery views
│   ├── MemoryTest/          # MoCA test viewer
│   ├── Recall/              # Memory training views
│   └── Settings/            # Settings view
└── ViewModels/              # View models for state management
    ├── ChatViewModel.swift
    ├── MemoryTrainingViewModel.swift
    ├── TextTrainingViewModel.swift
    └── ImageTrainingViewModel.swift
```

## Requirements

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
- OpenAI API key (for AI features)
- Backend API access (for memory training)

## Installation

### Prerequisites

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Memora
   ```

2. **Open the project**
   - Open `Memerai.xcodeproj` in Xcode

3. **Configure API Keys**
   - Open `Memora/Config/APIConfig.swift`
   - Add your OpenAI API key
   - Configure backend API URLs
   - ⚠️ **Important**: Never commit API keys to version control. Consider using environment variables or secure key storage.

4. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### API Configuration

The app requires the following API configurations:

- **OpenAI API**: For chat and AI-powered features
- **Memory Training Backend**: Text training API (Railway)
- **Image Training Backend**: Image training API (ngrok)

Update these in `Memora/Config/APIConfig.swift`:

```swift
static let openAIAPIKey = "your-openai-api-key"
static let textTrainingBackendURL = "your-backend-url"
static let imageTrainingBackendURL = "your-image-training-url"
```

## Usage

### Starting a Memory Training Session

1. Launch the app
2. Tap "Start Memory Training" on the home screen
3. Choose between "Image Training" or "Text Training"
4. Follow the interactive prompts and answer questions
5. Review your performance at the end of the session

### Using Siri Shortcuts

1. Add the "Start Memory Recall" shortcut in the Shortcuts app
2. Say "Hey Siri, Start Memory Recall" to launch a training session

### Adding Memories

1. Navigate to "Memory Gallery"
2. Tap "Upload Image"
3. Select an image and add associated information
4. Memories are automatically saved and can be used in training sessions

### Cognitive Assessment

1. Navigate to "Memory Test"
2. View the MoCA (Montreal Cognitive Assessment) PDF
3. Use this for standardized cognitive screening

## Technologies

- **SwiftUI**: Modern declarative UI framework
- **App Intents**: Siri Shortcuts integration
- **Combine**: Reactive programming for state management
- **URLSession**: Network requests and API communication
- **PDFKit**: PDF viewing for cognitive assessments
- **Safari Services**: Web view integration for caregiver dashboard
- **Core Data / File Storage**: Local memory storage
- **UserNotifications**: Daily reminder notifications

## API Integration

### OpenAI Integration
- Uses GPT-4o-mini for conversational AI
- Streaming responses for real-time chat experience
- Conversation history management

### Memory Training Backend
- RESTful API for session management
- Phases: Warmup → Training → Summary
- Question-answer tracking and scoring

## Privacy & Security

- Memories are stored locally on your device
- API keys should be stored securely (consider using iOS Keychain)
- No personal data is shared without explicit consent
- Follow best practices for healthcare data privacy

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is part of the 2025 AI Hackathon. Please check the license file for more details.

## Authors

- **Rae Wang** - Initial work and development

## Acknowledgments

- Built for the 2025 AI Hackathon
- Uses OpenAI's GPT models for AI capabilities
- MoCA (Montreal Cognitive Assessment) for cognitive screening
- Special thanks to all contributors and testers

## Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

**Note**: This app is designed to support cognitive health and memory training. It is not a replacement for professional medical advice. Always consult with healthcare professionals for medical concerns.

