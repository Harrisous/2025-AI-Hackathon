# 🎯 Backend Ready for Raspberry Pi Integration

## Quick Start

### Backend URL
```
http://172.28.93.21:5001
```

### Test Connection
```bash
curl http://172.28.93.21:5001/health
```

## Files to Copy to Raspberry Pi

1. **`simple_upload_example.py`** - Easiest way to get started
2. **`raspberry_pi_client.py`** - Full-featured client library
3. **`RASPBERRY_PI_INTEGRATION.md`** - Complete documentation

## Simplest Integration (3 Steps)

### Step 1: Copy the file
```bash
# Copy simple_upload_example.py to your Raspberry Pi
scp simple_upload_example.py pi@raspberry-pi-ip:/home/pi/
```

### Step 2: Install requests
```bash
# On Raspberry Pi
pip3 install requests
```

### Step 3: Use in your code
```python
from simple_upload_example import upload_image, upload_audio, upload_both

# After capturing image with your camera
upload_image('/path/to/captured_image.jpg')

# After recording audio
upload_audio('/path/to/recorded_audio.wav')

# Or send both together
upload_both('/path/to/image.jpg', '/path/to/audio.wav')
```

## What You Get Back

Every upload returns immediate confirmation:

```python
{
  "success": True,
  "file_id": "image_20251107_210027_448104",
  "filename": "image_20251107_210027_448104.jpg",
  "size": 7147,
  "timestamp": "2025-11-07T21:00:27.449646"
}
```

## Example: Integrate with Your Camera Code

```python
import time
from simple_upload_example import upload_both, check_backend
from your_camera_module import capture_image, record_audio

# Check backend first
if not check_backend():
    print("Backend not available!")
    exit(1)

# Your capture loop
while True:
    # Your existing camera code
    image_path = capture_image()  # Your function
    audio_path = record_audio()   # Your function
    
    # Upload to backend
    result = upload_both(image_path, audio_path)
    
    if result and result.get('success'):
        print(f"✓ Uploaded successfully!")
        print(f"  Image ID: {result['image']['file_id']}")
        print(f"  Audio ID: {result['audio']['file_id']}")
    else:
        print("✗ Upload failed, will retry...")
    
    time.sleep(60)  # Wait before next capture
```

## API Endpoints Available

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Check if backend is running |
| `/upload/image` | POST | Upload image only |
| `/upload/audio` | POST | Upload audio only |
| `/upload/batch` | POST | Upload both together |
| `/files` | GET | List all uploaded files |
| `/metadata/<file_id>` | GET | Get file metadata |

## Supported File Types

**Images**: JPG, PNG, GIF, BMP  
**Audio**: WAV, MP3, OGG, FLAC, M4A, AAC  
**Max Size**: 100MB per file

## No Git Merge Needed!

You can work on your separate branch. Just:
1. Use the backend URL: `http://172.28.93.21:5001`
2. Call the upload functions
3. That's it!

The backend is already running and tested. All files will be stored in organized folders ready for processing.

## Need Help?

Check `RASPBERRY_PI_INTEGRATION.md` for:
- Detailed examples
- Troubleshooting guide
- Full API documentation
- Error handling examples

## Status: ✅ READY TO USE

Backend is running, tested, and waiting for your uploads!
