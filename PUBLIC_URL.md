# 🌐 Public Backend URL - Share This with Your Friend!

## Your Backend is Live! ✅

**Public URL**: `https://sparklingly-kempt-terese.ngrok-free.dev`

---

## For Your Friend (Raspberry Pi Team)

### Step 1: Update the Backend URL

In `simple_upload_example.py`, change line 10:

```python
# OLD:
BACKEND_URL = "http://172.28.93.21:5001"

# NEW:
BACKEND_URL = "https://sparklingly-kempt-terese.ngrok-free.dev"
```

### Step 2: Test Connection

```python
from simple_upload_example import check_backend

check_backend()
# Should print: "✓ Backend is reachable!"
```

### Step 3: Test Upload

```python
from simple_upload_example import upload_image

upload_image('/path/to/test_image.jpg')
# Should print: "✓ SUCCESS!"
```

---

## Test Commands (From Anywhere)

### Health Check:
```bash
curl https://sparklingly-kempt-terese.ngrok-free.dev/health
```

### Upload Test Image:
```bash
curl -X POST -F "image=@test_image.jpg" https://sparklingly-kempt-terese.ngrok-free.dev/upload/image
```

### Upload Test Audio:
```bash
curl -X POST -F "audio=@test_audio.wav" https://sparklingly-kempt-terese.ngrok-free.dev/upload/audio
```

---

## API Endpoints

All endpoints are now accessible at:
`https://sparklingly-kempt-terese.ngrok-free.dev`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Check if backend is running |
| `/upload/image` | POST | Upload single image |
| `/upload/audio` | POST | Upload single audio |
| `/upload/batch` | POST | Upload image + audio together |
| `/files` | GET | List all uploaded files |
| `/metadata/<file_id>` | GET | Get file metadata |
| `/query/images_by_time` | GET | Query images by time range |
| `/query/audio_chunks` | GET | List all audio chunks |

---

## Important Notes

⚠️ **Keep Your Computer Running**:
- Your local backend must be running (`python3 app.py`)
- ngrok must be running
- If you close either, the URL stops working

⏰ **URL Validity**:
- This URL works as long as ngrok is running
- If you restart ngrok, you'll get a new URL
- Share the new URL with your friend

🔒 **Security**:
- This is for testing/hackathon use
- No authentication required
- Don't share sensitive data

---

## Quick Reference for Your Friend

**Backend URL**: `https://sparklingly-kempt-terese.ngrok-free.dev`

**Python Code**:
```python
import requests

BACKEND_URL = "https://sparklingly-kempt-terese.ngrok-free.dev"

# Upload image
with open('photo.jpg', 'rb') as f:
    response = requests.post(f"{BACKEND_URL}/upload/image", files={'image': f})
    print(response.json())

# Upload audio
with open('audio.wav', 'rb') as f:
    response = requests.post(f"{BACKEND_URL}/upload/audio", files={'audio': f})
    print(response.json())
```

---

## Status

✅ **Backend**: Running  
✅ **ngrok**: Active  
✅ **Public URL**: https://sparklingly-kempt-terese.ngrok-free.dev  
✅ **Ready for Testing**: YES!

**Your friend can now test from their Raspberry Pi!** 🎉
