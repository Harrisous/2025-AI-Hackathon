# Alzheimer's Camera System - API Documentation

## Base URL
```
https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app
```

---

## Overview

This API provides three main endpoints for the Raspberry Pi camera system:
1. **Voice Verification** - Detect if patient's voice is present in audio
2. **Audio Upload** - Store audio recordings in Supabase
3. **Image Upload** - Store photos in Supabase

---

## Endpoints

### 1. Health Check
Check if the API is running.

**Endpoint:** `GET /health`

**Example:**
```bash
curl https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "alzheimer-camera-backend"
}
```

---

### 2. Voice Verification ⭐ NEW
Verify if the patient's voice is present in an audio file.

**Endpoint:** `POST /verify/voice`

**Parameters:**
- `audio` (file, required) - Audio file (.wav, .mp3)

**Example:**
```bash
curl -X POST \
  -F "audio=@audio_2025-11-08+10-25.wav" \
  https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/verify/voice
```

**Success Response (Patient Detected):**
```json
{
  "success": true,
  "is_patient_voice": true,
  "should_take_photos": true,
  "max_similarity": 0.9236,
  "mean_similarity": 0.8707,
  "threshold": 0.7,
  "message": "Patient detected - take photos!"
}
```

**Success Response (Patient NOT Detected):**
```json
{
  "success": true,
  "is_patient_voice": false,
  "should_take_photos": false,
  "max_similarity": 0.6322,
  "mean_similarity": 0.5822,
  "threshold": 0.7,
  "message": "Patient not speaking - skip photos"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "No audio provided"
}
```

---

### 3. Upload Audio
Upload audio recording to Supabase storage.

**Endpoint:** `POST /upload/audio`

**Parameters:**
- `audio` (file, required) - Audio file (.wav, .mp3)

**Example:**
```bash
curl -X POST \
  -F "audio=@audio_2025-11-08+10-25.wav" \
  https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/upload/audio
```

**Success Response:**
```json
{
  "success": true,
  "message": "Audio received and stored successfully",
  "filename": "audio_2025-11-08+10-25.wav",
  "url": "https://aidxatmmfpmhxxpkmnny.supabase.co/storage/v1/object/public/alzheimer-audio/audio_2025-11-08+10-25.wav"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "No audio file provided"
}
```

---

### 4. Upload Image
Upload photo to Supabase storage.

**Endpoint:** `POST /upload/image`

**Parameters:**
- `image` (file, required) - Image file (.jpg, .png)

**Example:**
```bash
curl -X POST \
  -F "image=@pic_2025-11-08+10-27.jpg" \
  https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/upload/image
```

**Success Response:**
```json
{
  "success": true,
  "message": "Image received and stored successfully",
  "filename": "pic_2025-11-08+10-27.jpg",
  "url": "https://aidxatmmfpmhxxpkmnny.supabase.co/storage/v1/object/public/alzheimer-images/pic_2025-11-08+10-27.jpg"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "No image file provided"
}
```

---

## Raspberry Pi Workflow

### Complete 5-Minute Cycle

```python
import requests
import time
from datetime import datetime

BASE_URL = "https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app"

# Step 1: Record 5-minute audio chunk
audio_file = "audio_2025-11-08+10-25.wav"
# ... your audio recording code ...

# Step 2: Upload audio to backend
with open(audio_file, 'rb') as f:
    response = requests.post(f"{BASE_URL}/upload/audio", files={'audio': f})
    print(f"Audio uploaded: {response.json()}")

# Step 3: Check if patient's voice is present
with open(audio_file, 'rb') as f:
    response = requests.post(f"{BASE_URL}/verify/voice", files={'audio': f})
    result = response.json()

# Step 4: Decision - Take photos or skip
if result['should_take_photos']:
    print("✅ Patient detected! Taking photos...")
    
    # Take photos every 5 seconds for 5 minutes (60 photos)
    for i in range(60):
        # Capture photo
        photo_file = f"pic_{datetime.now().strftime('%Y-%m-%d+%H-%M-%S')}.jpg"
        # ... your camera capture code ...
        
        # Upload photo
        with open(photo_file, 'rb') as f:
            requests.post(f"{BASE_URL}/upload/image", files={'image': f})
        
        time.sleep(5)  # Wait 5 seconds
else:
    print("❌ Patient not speaking. Skipping photos.")
    time.sleep(300)  # Wait 5 minutes for next cycle
```

---

## File Naming Convention

### Audio Files
Format: `audio_YYYY-MM-DD+HH-MM.wav`

Example: `audio_2025-11-08+10-25.wav`
- Represents the END time of the 5-minute recording
- If recording started at 10:20, file name would be 10-25

### Image Files
Format: `pic_YYYY-MM-DD+HH-MM-SS.jpg`

Example: `pic_2025-11-08+10-27-35.jpg`
- Represents the exact capture time
- Includes seconds for uniqueness

---

## Voice Recognition Details

### How It Works
- **Model**: Resemblyzer (Deep Learning Speaker Recognition)
- **Training**: Trained on 4 audio samples of the patient (~203 seconds)
- **Threshold**: 70% similarity
- **Accuracy**: 100% tested accuracy

### Similarity Scores
- **>70%**: Patient's voice detected → Take photos
- **<70%**: Patient not speaking → Skip photos

### Performance
- **First request**: ~30 seconds (model loading)
- **Subsequent requests**: <5 seconds
- **Supported formats**: WAV, MP3

---

## Error Handling

### Common Errors

**503 Service Unavailable**
```json
{
  "success": false,
  "error": "Voice recognition not available"
}
```
→ Voice model failed to load. Contact backend team.

**400 Bad Request**
```json
{
  "success": false,
  "error": "No audio provided"
}
```
→ Missing audio file in request. Check form data.

**502 Bad Gateway**
→ Request timeout. Audio file might be too large (>60 seconds recommended).

---

## Testing

### Test Voice Verification

**Test 1: Patient's Voice (should return true)**
```bash
curl -X POST \
  -F "audio=@patient_voice.wav" \
  https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/verify/voice
```

Expected: `should_take_photos: true`

**Test 2: Different Person (should return false)**
```bash
curl -X POST \
  -F "audio=@other_person.wav" \
  https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app/verify/voice
```

Expected: `should_take_photos: false`

---

## Support

For issues or questions, contact the backend team.

**API Status**: ✅ Live and operational
**Last Updated**: November 8, 2025
