# Simple Explanation - Alzheimer's Camera System

## The Problem
Alzheimer's patients forget:
- Who they talked to
- What was said
- When conversations happened

## The Solution
Automatic camera that:
1. Takes photos of people they talk to
2. Records the conversation
3. Helps them remember later

---

## How It Works (Super Simple)

### 1️⃣ Patient Wears Camera
```
     👤 Patient
     │
     ├─ 📷 Camera (around neck)
     ├─ 🎤 Microphone
     └─ 📱 Raspberry Pi (in pocket)
```

### 2️⃣ When Patient Talks to Someone
```
Patient: "Hi Dad!"
Dad: "Hello! How are you?"

Camera: 📸 *click* (takes photo of Dad)
Microphone: 🎤 *recording* (records conversation)
```

### 3️⃣ Raspberry Pi Sends to Your Computer
```
Raspberry Pi → WiFi → Your Computer

Sends:
- Photo of Dad's face
- Audio of conversation
```

### 4️⃣ Your Backend Saves Everything
```
Your Computer receives:
✅ Photo saved → data/images/dad_photo.jpg
✅ Audio saved → data/audio/conversation.wav
✅ Sends back: "Got it!"
```

### 5️⃣ AI Processes (You'll build this next)
```
Photo → Face Recognition → "This is Father"
Audio → Speech-to-Text → "Hi Dad! How are you?"

Saves to memory:
"At 2:30 PM, you talked to your Father.
He said: 'Hello! How are you?'"
```

---

## What Each Person Does

### Your Friend (Raspberry Pi Team)
**Their job**: Capture and send

```python
# Their code (simplified):
while True:
    # Check if someone is talking
    if microphone_hears_voice():
        photo = camera.take_picture()
        audio = microphone.record()
        
        # Send to your backend
        upload_both(photo, audio)
    
    wait(5_seconds)
```

**They need**:
- Camera module
- Microphone
- `simple_upload_example.py` (you give them this)
- Your backend URL: `http://172.28.93.21:5001`

### You (Backend Team)
**Your job**: Receive, store, and process

**Part 1 - Backend (✅ DONE!)**:
```python
# Your backend (already working!):
@app.route('/upload/batch')
def receive_files():
    save_image()  # → data/images/
    save_audio()  # → data/audio/
    return "Got it! ✅"
```

**Part 2 - Processing (TODO - Next step)**:
```python
# You'll build this next:
def process_files():
    # 1. Who is this person?
    face = recognize_face(image)
    # → "This is Father"
    
    # 2. What did they say?
    text = convert_speech_to_text(audio)
    # → "Hi Dad! How are you?"
    
    # 3. Save memory
    save_to_database({
        "person": "Father",
        "conversation": "Hi Dad! How are you?",
        "time": "2:30 PM",
        "photo": "dad_photo.jpg"
    })
```

---

## Current Status

### ✅ What's Working Now:

1. **Backend API**: Running at `http://172.28.93.21:5001`
2. **File Upload**: Receives images and audio
3. **Storage**: Saves to organized folders
4. **Confirmation**: Sends "Got it!" back to Raspberry Pi

### 🚧 What's Next:

**For Your Friend**:
- Set up camera on Raspberry Pi
- Set up microphone
- Run the continuous capture program
- Test sending files

**For You**:
- Build face recognition (identify people)
- Build speech-to-text (convert audio to text)
- Build memory database (store who/what/when)
- Build interface to show memories

---

## Example Day in the Life

**Morning - 9:00 AM**
- Patient talks to wife
- Camera: 📸 Photo of wife
- Mic: 🎤 "Good morning, did you sleep well?"
- Saved ✅

**Afternoon - 2:00 PM**
- Patient talks to son
- Camera: 📸 Photo of son
- Mic: 🎤 "Hi mom, I brought groceries"
- Saved ✅

**Evening - 6:00 PM**
- Patient asks: "Who did I talk to today?"
- System shows:
  ```
  9:00 AM - Wife: "Good morning, did you sleep well?"
  2:00 PM - Son: "Hi mom, I brought groceries"
  ```

---

## The Flow (One Conversation)

```
1. Patient meets Father
   ↓
2. Raspberry Pi detects conversation
   ↓
3. Camera takes photo of Father
   ↓
4. Microphone records conversation
   ↓
5. Raspberry Pi sends to your backend
   ↓
6. Your backend saves files
   ↓
7. Your backend confirms: "Got it! ✅"
   ↓
8. AI processes:
   - Photo → "This is Father"
   - Audio → "Hi, how are you?"
   ↓
9. Saved to memory database
   ↓
10. Patient can review later
```

---

## What You Have Right Now

### Files Created:
1. **`app.py`** - Your backend (running ✅)
2. **`simple_upload_example.py`** - For Raspberry Pi to use
3. **`continuous_capture_system.py`** - Full Raspberry Pi program
4. **`SYSTEM_DESIGN.md`** - Complete technical design

### What's Working:
- Backend receives files ✅
- Backend stores files ✅
- Backend confirms receipt ✅
- Tested and working ✅

### What Your Friend Needs:
- Copy `simple_upload_example.py` to Raspberry Pi
- Use URL: `http://172.28.93.21:5001`
- Call `upload_both(photo, audio)` after capturing

---

## Next Steps (Priority Order)

### Step 1: Test End-to-End
1. Your friend captures test photo + audio
2. Sends to your backend
3. Verify files appear in `data/images/` and `data/audio/`

### Step 2: Build Processing
1. Face recognition to identify people
2. Speech-to-text to get conversation
3. Database to store memories

### Step 3: Build Interface
1. Show timeline of conversations
2. Search: "When did I talk to Dad?"
3. Display photos + text

---

## Key Insight

**You don't need to understand Raspberry Pi code!**
**Your friend doesn't need to understand backend code!**

**The connection is simple**:
- They call: `upload_both(photo, audio)`
- You receive: Files in `data/images/` and `data/audio/`
- That's it!

It's like email:
- They send (Raspberry Pi)
- You receive (Backend)
- No need to know how the other side works!
