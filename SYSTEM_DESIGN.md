# Alzheimer's Patient Camera System - Complete Design

## 🎯 Goal
Help Alzheimer's patients remember conversations and people by automatically capturing images and audio when they talk to someone.

## 📋 System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PATIENT (Wears Camera)                    │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │   Camera     │         │  Microphone  │                 │
│  │ (on neck)    │         │              │                 │
│  └──────┬───────┘         └──────┬───────┘                 │
│         │                        │                          │
│         └────────┬───────────────┘                          │
│                  │                                          │
│         ┌────────▼────────┐                                │
│         │  Raspberry Pi   │                                │
│         │  - Detects talk │                                │
│         │  - Captures     │                                │
│         │  - Sends data   │                                │
│         └────────┬────────┘                                │
└──────────────────┼─────────────────────────────────────────┘
                   │
                   │ WiFi/Network
                   │
┌──────────────────▼─────────────────────────────────────────┐
│              YOUR BACKEND (Your Computer)                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Flask API - Receives & Stores                       │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                           │
│  ┌──────────────▼───────────────────────────────────────┐  │
│  │  Storage                                             │  │
│  │  - data/images/   (photos of people)                │  │
│  │  - data/audio/    (conversation recordings)         │  │
│  │  - data/metadata/ (timestamps, file info)           │  │
│  └──────────────┬───────────────────────────────────────┘  │
│                 │                                           │
│  ┌──────────────▼───────────────────────────────────────┐  │
│  │  AI Processing (Next Step)                           │  │
│  │  - Face Recognition → "This is your father"         │  │
│  │  - Speech-to-Text → "What was said"                 │  │
│  │  - Memory Database → "You talked to dad at 2pm"     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 How It Works (Step by Step)

### Step 1: Patient Wears Camera
- Small camera around neck (like a necklace)
- Microphone attached
- Raspberry Pi in pocket/bag

### Step 2: Automatic Detection
```python
# Raspberry Pi continuously checks:
while True:
    # Every 5 seconds, take a photo
    if time_to_capture():
        photo = capture_image()
    
    # Check if someone is talking
    if is_conversation_happening():
        audio = record_conversation()
        
        # Send both to your backend
        upload_both(photo, audio)
```

### Step 3: Backend Receives & Stores
```python
# Your backend (already built!)
POST /upload/batch
→ Saves image to data/images/
→ Saves audio to data/audio/
→ Returns confirmation: "Got it! ✅"
```

### Step 4: AI Processing (You'll build this next)
```python
# Process the stored files
image = load_image("data/images/image_123.jpg")
audio = load_audio("data/audio/audio_123.wav")

# Who is this person?
person = face_recognition(image)
# → "This is your father"

# What did they say?
conversation = speech_to_text(audio)
# → "Hi dad, how are you today?"

# Save to memory database
save_memory({
    "person": "Father",
    "conversation": "Hi dad, how are you today?",
    "time": "2025-11-07 14:30",
    "image": "image_123.jpg"
})
```

## 📁 File Structure

### On Raspberry Pi:
```
/home/pi/
├── simple_upload_example.py      # Upload functions
├── continuous_capture_system.py  # Main program
└── temp/                         # Temporary storage
    ├── image_20251107_143000.jpg
    └── audio_20251107_143000.wav
```

### On Your Backend:
```
2025-AI-Hackathon/
├── app.py                        # Backend API (✅ Done)
├── data/                         # Storage (✅ Done)
│   ├── images/                   # All captured faces
│   ├── audio/                    # All conversations
│   └── metadata/                 # File information
└── processing/                   # Next: AI processing
    ├── face_recognition.py       # Identify people
    ├── speech_to_text.py         # Convert audio to text
    └── memory_database.py        # Store memories
```

## 🎬 Example Scenario

**2:30 PM - Patient meets their father**

1. **Camera captures**: Photo of father's face
2. **Microphone records**: "Hi, how are you today?"
3. **Raspberry Pi sends**: Both to your backend
4. **Backend stores**: 
   - `image_20251107_143000.jpg`
   - `audio_20251107_143000.wav`
5. **AI processes**:
   - Face recognition: "This is Father"
   - Speech-to-text: "Hi, how are you today?"
6. **Memory saved**: "At 2:30 PM, you talked to your Father. He said: 'Hi, how are you today?'"

**Later, patient can review**: "Who did I talk to today?" → Shows photo of father + conversation

## 🔧 What You Need to Build

### ✅ Already Done:
1. Backend API (receives images & audio)
2. Storage system (organized folders)
3. Upload confirmation system

### 🚧 Next Steps (Your Part):
1. **Face Recognition**
   - Use OpenCV or face_recognition library
   - Train on family photos
   - Identify: "This is Father/Mother/Sister"

2. **Speech-to-Text**
   - Use Whisper, Google Speech API, or similar
   - Convert audio → text
   - Extract conversation content

3. **Memory Database**
   - Store: Who, When, What was said, Photo
   - Allow searching: "When did I last talk to mom?"
   - Show timeline of conversations

### 🚧 Your Friend's Part (Raspberry Pi):
1. Set up camera (picamera2)
2. Set up microphone (pyaudio)
3. Run `continuous_capture_system.py`
4. Test conversation detection

## 💡 Simple Version to Start

### Minimum Viable Product (MVP):

**Raspberry Pi** (Your friend):
```python
# Every 10 seconds
while True:
    photo = take_photo()
    audio = record_10_seconds()
    upload_both(photo, audio)
    sleep(10)
```

**Your Backend** (You):
```python
# Already done! ✅
# Files automatically saved in data/images/ and data/audio/
```

**Processing** (You - Next):
```python
# Simple version
for image_file in data/images/:
    person = "Unknown"  # Later: use face recognition
    
for audio_file in data/audio/:
    text = "..."  # Later: use speech-to-text
    
# For now, just list all files with timestamps
```

## 🎯 Key Points

1. **Continuous Operation**: Camera runs all day, only saves when conversation detected
2. **Automatic**: Patient doesn't need to do anything
3. **Privacy**: Only records when talking (conversation detection)
4. **Storage**: Everything organized by timestamp
5. **Processing**: Happens on your backend, not on Raspberry Pi

## 📦 Dependencies

### Raspberry Pi:
```bash
pip3 install requests pyaudio picamera2 numpy
```

### Your Backend:
```bash
# Already installed ✅
pip3 install Flask Flask-CORS

# For next steps (AI processing):
pip3 install opencv-python face-recognition whisper
```

## 🚀 Getting Started

1. **Your friend**: Run `continuous_capture_system.py` on Raspberry Pi
2. **You**: Backend is already running! ✅
3. **Next**: Build face recognition and speech-to-text processing

The backend is ready - files will start appearing in `data/images/` and `data/audio/` as soon as your friend starts the Raspberry Pi system!
