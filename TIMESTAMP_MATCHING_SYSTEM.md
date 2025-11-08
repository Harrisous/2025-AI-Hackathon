# Timestamp Matching System

## Overview

The system records audio in **5-minute chunks** and captures **images every 5 seconds**. Timestamps are used to match which images belong to which audio chunk.

---

## How It Works

### Timeline Example

```
Time:     14:00:00                    14:05:00                    14:10:00
          |                           |                           |
Audio:    [====== Chunk 1 (5min) =====][====== Chunk 2 (5min) =====]
          |                           |                           |
Images:   📸  📸  📸  📸  📸  📸  📸   📸  📸  📸  📸  📸  📸  📸
          ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
          |   |   |   |   |   |   |   |   |   |   |   |   |   |
          Every 5 seconds            Every 5 seconds
```

### Chunk 1 (14:00:00 - 14:05:00)
- **Audio**: `audio_chunk_20251107_140000.wav`
- **Start**: 14:00:00
- **End**: 14:05:00
- **Matched Images** (60 images):
  - `image_20251107_140000.jpg` (14:00:00)
  - `image_20251107_140005.jpg` (14:00:05)
  - `image_20251107_140010.jpg` (14:00:10)
  - ... (every 5 seconds)
  - `image_20251107_140455.jpg` (14:04:55)

### Chunk 2 (14:05:00 - 14:10:00)
- **Audio**: `audio_chunk_20251107_140500.wav`
- **Start**: 14:05:00
- **End**: 14:10:00
- **Matched Images** (60 images):
  - `image_20251107_140500.jpg` (14:05:00)
  - `image_20251107_140505.jpg` (14:05:05)
  - ... and so on

---

## Timestamp Matching Logic

### Rule
An image belongs to an audio chunk if:
```
audio_chunk.start_time <= image.timestamp <= audio_chunk.end_time
```

### Example
```python
Audio Chunk:
  - Start: 14:00:00
  - End: 14:05:00

Image 1:
  - Timestamp: 14:02:30
  - Matches? YES (14:00:00 <= 14:02:30 <= 14:05:00)

Image 2:
  - Timestamp: 14:06:15
  - Matches? NO (14:06:15 > 14:05:00)
```

---

## File Naming Convention

### Audio Chunks
```
audio_chunk_YYYYMMDD_HHMMSS.wav

Examples:
- audio_chunk_20251107_140000.wav  (Started at 14:00:00)
- audio_chunk_20251107_140500.wav  (Started at 14:05:00)
- audio_chunk_20251107_141000.wav  (Started at 14:10:00)
```

### Images
```
image_YYYYMMDD_HHMMSS_microseconds.jpg

Examples:
- image_20251107_140000_123456.jpg  (Captured at 14:00:00.123456)
- image_20251107_140005_234567.jpg  (Captured at 14:00:05.234567)
- image_20251107_140010_345678.jpg  (Captured at 14:00:10.345678)
```

---

## Data Structure

### Backend Storage
```
data/
├── audio/
│   ├── audio_chunk_20251107_140000.wav  (5 min, ~26 MB)
│   ├── audio_chunk_20251107_140500.wav  (5 min, ~26 MB)
│   └── audio_chunk_20251107_141000.wav  (5 min, ~26 MB)
│
├── images/
│   ├── image_20251107_140000_123456.jpg  (~7 KB)
│   ├── image_20251107_140005_234567.jpg  (~7 KB)
│   ├── image_20251107_140010_345678.jpg  (~7 KB)
│   └── ... (60 images per 5-minute chunk)
│
└── metadata/
    ├── audio_chunk_20251107_140000.json
    ├── image_20251107_140000_123456.json
    └── ...
```

### Metadata Example

**Audio Chunk Metadata** (`audio_chunk_20251107_140000.json`):
```json
{
  "file_id": "audio_chunk_20251107_140000",
  "file_type": "audio",
  "chunk_start_time": "2025-11-07T14:00:00.000000",
  "chunk_end_time": "2025-11-07T14:05:00.000000",
  "duration_seconds": 300,
  "file_size": 26460044,
  "upload_timestamp": "2025-11-07T14:05:02.123456",
  "status": "received"
}
```

**Image Metadata** (`image_20251107_140000_123456.json`):
```json
{
  "file_id": "image_20251107_140000_123456",
  "file_type": "image",
  "capture_timestamp": "2025-11-07T14:00:00.123456",
  "file_size": 6724,
  "upload_timestamp": "2025-11-07T14:05:02.234567",
  "status": "received",
  "belongs_to_audio_chunk": "audio_chunk_20251107_140000"
}
```

---

## Processing Logic (Your Next Step)

### Step 1: Query by Time Range
```python
# Find all data from 2pm to 3pm
audio_chunks = get_audio_chunks(start="14:00:00", end="15:00:00")
# Returns: [chunk_1400, chunk_1405, chunk_1410, ..., chunk_1455]

for chunk in audio_chunks:
    images = get_images_for_chunk(chunk.chunk_id)
    # Process chunk and images together
```

### Step 2: Match Conversations with Faces
```python
# For audio chunk 14:00:00 - 14:05:00
audio_chunk = load_audio("audio_chunk_20251107_140000.wav")
images = load_images_for_chunk("audio_chunk_20251107_140000")

# Speech-to-text
conversation = speech_to_text(audio_chunk)
# "Hi Dad, how are you today? Did you sleep well?"

# Face recognition on images
faces_detected = []
for img in images:
    face = recognize_face(img)
    if face:
        faces_detected.append({
            'person': face.name,  # "Father"
            'timestamp': img.timestamp,
            'confidence': face.confidence
        })

# Result: "From 14:00 to 14:05, you talked to Father"
```

### Step 3: Timeline Reconstruction
```python
# Build timeline for the day
timeline = []

for audio_chunk in get_all_chunks_for_day("2025-11-07"):
    images = get_images_for_chunk(audio_chunk.chunk_id)
    conversation = speech_to_text(audio_chunk)
    people = identify_people_in_images(images)
    
    timeline.append({
        'time': audio_chunk.start_time,
        'duration': 5,  # minutes
        'people': people,  # ["Father"]
        'conversation': conversation,
        'images': images
    })

# Show patient:
# 14:00 - Talked to Father: "Hi Dad, how are you?"
# 14:05 - Talked to Mother: "Did you take medicine?"
# 14:10 - Talked to Sister: "Want to go for a walk?"
```

---

## Benefits of 5-Minute Chunks

### 1. **Manageable File Sizes**
- Audio: ~26 MB per chunk (vs. hours of continuous recording)
- Easy to upload over WiFi
- Easy to process

### 2. **Natural Conversation Boundaries**
- Most conversations are < 5 minutes
- Easy to segment and review

### 3. **Efficient Processing**
- Process one chunk at a time
- Parallel processing possible
- Can prioritize recent chunks

### 4. **Easy Matching**
- Simple timestamp comparison
- ~60 images per audio chunk
- Clear relationship between audio and images

### 5. **Fault Tolerance**
- If one chunk fails to upload, others are unaffected
- Can retry individual chunks
- No data loss from connection issues

---

## Statistics

### Per 5-Minute Chunk:
- **Audio**: 1 file (~26 MB)
- **Images**: ~60 files (~420 KB total)
- **Total**: ~26.5 MB per chunk

### Per Hour:
- **Audio chunks**: 12 chunks (~312 MB)
- **Images**: ~720 images (~5 MB)
- **Total**: ~317 MB per hour

### Per Day (12 hours active):
- **Audio chunks**: 144 chunks (~3.7 GB)
- **Images**: ~8,640 images (~60 MB)
- **Total**: ~3.8 GB per day

---

## Query Examples

### Find specific conversation
```python
# "When did I last talk to Dad?"
conversations = search_conversations(person="Father")
# Returns all chunks where Father was detected

# "What did I say to Mom at 2pm?"
chunk = get_chunk_at_time("14:00:00")
conversation = speech_to_text(chunk.audio)
```

### Find person in images
```python
# "Show me all photos of my sister today"
images = search_images(person="Sister", date="2025-11-07")
# Returns all images where Sister was detected
```

### Timeline view
```python
# "What did I do this afternoon?"
timeline = get_timeline(start="12:00:00", end="18:00:00")
# Returns chronological list of conversations and people
```

---

## Implementation Status

### ✅ Completed:
- Backend receives and stores files
- Timestamp-based file naming
- Metadata tracking

### 🚧 Next Steps:
1. **Enhance metadata** to include chunk relationships
2. **Build query functions** to find images by audio chunk
3. **Implement face recognition** to identify people
4. **Implement speech-to-text** to extract conversations
5. **Build timeline view** to show daily activities

---

## Summary

The timestamp matching system provides:
- ✅ **Organized data**: Clear relationship between audio and images
- ✅ **Efficient storage**: Manageable chunk sizes
- ✅ **Easy processing**: Process one chunk at a time
- ✅ **Flexible queries**: Find data by time, person, or conversation
- ✅ **Scalable**: Works for hours or days of recording

**The foundation is ready - now you can build the AI processing layer!**
