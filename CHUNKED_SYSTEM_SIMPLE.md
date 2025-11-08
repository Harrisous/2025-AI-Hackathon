# 5-Minute Audio Chunks - Simple Explanation

## The Idea 💡

Instead of recording one giant audio file all day, we break it into **5-minute pieces** (chunks). Each chunk has many images captured during those 5 minutes.

---

## Visual Example

### Timeline View
```
14:00 ─────────────────────► 14:05 ─────────────────────► 14:10
      [   Chunk 1 (5min)   ]       [   Chunk 2 (5min)   ]
      
      📸 📸 📸 📸 📸 📸 📸         📸 📸 📸 📸 📸 📸 📸
      (60 images)                  (60 images)
```

### What Gets Stored

**Chunk 1 (14:00 - 14:05)**
```
Audio: audio_chunk_20251107_140000.wav (5 minutes of sound)
Images:
  - image_20251107_140000.jpg  ← 14:00:00
  - image_20251107_140005.jpg  ← 14:00:05
  - image_20251107_140010.jpg  ← 14:00:10
  - ... (60 images total, one every 5 seconds)
  - image_20251107_140455.jpg  ← 14:04:55
```

---

## How Matching Works

### Question: Which images belong to which audio?

**Answer: Use timestamps!**

```python
# Audio chunk starts at 14:00:00 and ends at 14:05:00

Image at 14:02:30 → MATCHES ✅ (between 14:00 and 14:05)
Image at 14:06:15 → NO MATCH ❌ (after 14:05)
```

### Simple Rule
```
If image_time is between audio_start and audio_end:
    → Image belongs to this audio chunk
```

---

## Real Example

### Scenario: Patient talks to Father from 14:00 to 14:05

**What happens:**

1. **14:00:00** - Audio recording starts
2. **14:00:00** - 📸 Image 1 (Father's face)
3. **14:00:05** - 📸 Image 2 (Father's face)
4. **14:00:10** - 📸 Image 3 (Father's face)
5. ... (continues every 5 seconds)
6. **14:04:55** - 📸 Image 60 (Father's face)
7. **14:05:00** - Audio recording stops

**Result:**
- 1 audio file with 5 minutes of conversation
- 60 images of Father's face
- All linked by timestamps!

---

## Why This Is Smart

### ✅ **Easy to Upload**
- Small chunks upload faster
- If one fails, others still work
- Can upload while recording next chunk

### ✅ **Easy to Process**
- Process one 5-minute chunk at a time
- Don't need to load huge files
- Can work on multiple chunks in parallel

### ✅ **Easy to Find**
- "Show me 2pm to 3pm" → Get 12 chunks
- "Who did I talk to at 2:15pm?" → Check chunk starting at 2:15
- "Show all photos from 2pm" → Get images from that chunk

### ✅ **Easy to Match**
- Audio chunk: 14:00 - 14:05
- Images: All between 14:00 and 14:05
- Perfect match!

---

## File Sizes

### Per 5-Minute Chunk:
- **Audio**: ~26 MB (5 minutes of sound)
- **Images**: ~420 KB (60 images × 7 KB each)
- **Total**: ~26.5 MB

### Per Hour:
- **12 chunks** × 26.5 MB = ~318 MB

### Per Day (12 hours):
- **144 chunks** × 26.5 MB = ~3.8 GB

---

## How Your Backend Uses This

### When Raspberry Pi Sends Data:
```python
# Raspberry Pi sends:
- audio_chunk_20251107_140000.wav
- image_20251107_140000.jpg
- image_20251107_140005.jpg
- image_20251107_140010.jpg
- ... (all 60 images)

# Your backend saves them all
# Timestamps automatically link them!
```

### When You Process Later:
```python
# Get audio chunk
audio = load("audio_chunk_20251107_140000.wav")

# Get matching images (14:00:00 to 14:05:00)
images = query_images_by_time("20251107_140000", "20251107_140500")

# Now you have:
# - 5 minutes of audio
# - 60 images from that same time
# - Process them together!

# Speech-to-text on audio
conversation = speech_to_text(audio)
# "Hi Dad, how are you today?"

# Face recognition on images
person = recognize_face(images[0])
# "Father"

# Result:
# "From 14:00 to 14:05, you talked to Father.
#  Conversation: 'Hi Dad, how are you today?'"
```

---

## Query Examples

### 1. Find specific time
```python
# "What happened at 2pm?"
chunk = get_audio_chunk("20251107_140000")
images = get_images_for_chunk("20251107_140000")
```

### 2. Find time range
```python
# "Show me 2pm to 3pm"
chunks = get_audio_chunks_range("20251107_140000", "20251107_150000")
# Returns 12 chunks (one per 5 minutes)
```

### 3. Find person
```python
# "When did I talk to Dad?"
# (You'll build this next)
for chunk in all_chunks:
    images = get_images_for_chunk(chunk)
    if "Father" in recognize_faces(images):
        print(f"Talked to Father at {chunk.start_time}")
```

---

## Summary

### The System:
1. **Record** audio in 5-minute chunks
2. **Capture** images every 5 seconds
3. **Match** using timestamps
4. **Upload** to your backend
5. **Process** to identify people and conversations

### The Magic:
- Timestamps automatically link everything
- No manual matching needed
- Easy to query and process
- Scalable for hours/days of recording

### Your Part:
- ✅ Backend receives and stores (DONE!)
- ✅ Timestamps preserved (DONE!)
- 🚧 Build face recognition (NEXT)
- 🚧 Build speech-to-text (NEXT)
- 🚧 Build query interface (NEXT)

**The foundation is ready - timestamps make everything work together!** 🎯
