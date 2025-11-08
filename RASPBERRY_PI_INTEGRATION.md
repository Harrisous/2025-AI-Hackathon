# Raspberry Pi Integration Guide

## Backend Information

**Backend URL**: `http://172.28.93.21:5001`  
**Status**: Running and tested ✅

## Quick Integration

### Option 1: Using Python (Recommended)

Copy the `raspberry_pi_client.py` file to your Raspberry Pi and use it:

```python
from raspberry_pi_client import RaspberryPiClient

# Initialize client
client = RaspberryPiClient("http://172.28.93.21:5001")

# Check connection
if client.check_connection():
    print("Connected to backend!")
    
    # Send image
    result = client.send_image("/path/to/captured_image.jpg")
    if result and result.get('success'):
        print(f"✓ Image uploaded! ID: {result['file_id']}")
    
    # Send audio
    result = client.send_audio("/path/to/recorded_audio.wav")
    if result and result.get('success'):
        print(f"✓ Audio uploaded! ID: {result['file_id']}")
    
    # Or send both together
    result = client.send_batch("/path/to/image.jpg", "/path/to/audio.wav")
    if result and result.get('success'):
        print("✓ Both files uploaded!")
```

### Option 2: Using curl (Simple Testing)

```bash
# Test connection
curl http://172.28.93.21:5001/health

# Upload image
curl -X POST -F "image=@photo.jpg" http://172.28.93.21:5001/upload/image

# Upload audio
curl -X POST -F "audio=@recording.wav" http://172.28.93.21:5001/upload/audio

# Upload both
curl -X POST -F "image=@photo.jpg" -F "audio=@recording.wav" http://172.28.93.21:5001/upload/batch
```

### Option 3: Using Python Requests (Direct)

```python
import requests

BACKEND_URL = "http://172.28.93.21:5001"

# Upload image
with open('captured_image.jpg', 'rb') as f:
    response = requests.post(
        f"{BACKEND_URL}/upload/image",
        files={'image': f}
    )
    print(response.json())

# Upload audio
with open('recorded_audio.wav', 'rb') as f:
    response = requests.post(
        f"{BACKEND_URL}/upload/audio",
        files={'audio': f}
    )
    print(response.json())
```

## Example: Continuous Capture Loop

```python
import time
from raspberry_pi_client import RaspberryPiClient
from picamera2 import Picamera2  # Your camera library
import pyaudio  # Your audio library

# Initialize
client = RaspberryPiClient("http://172.28.93.21:5001")
camera = Picamera2()

# Check backend connection
if not client.check_connection():
    print("Cannot connect to backend!")
    exit(1)

print("Starting capture loop...")

while True:
    try:
        # Capture image
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        image_path = f"/tmp/capture_{timestamp}.jpg"
        camera.capture_file(image_path)
        
        # Record audio (your audio recording code here)
        audio_path = f"/tmp/audio_{timestamp}.wav"
        # record_audio(audio_path)  # Your function
        
        # Send to backend
        result = client.send_batch(image_path, audio_path)
        
        if result and result.get('success'):
            print(f"✓ Uploaded at {timestamp}")
            print(f"  Image ID: {result['image']['file_id']}")
            print(f"  Audio ID: {result['audio']['file_id']}")
        else:
            print(f"✗ Upload failed at {timestamp}")
        
        # Wait before next capture
        time.sleep(60)  # Capture every 60 seconds
        
    except Exception as e:
        print(f"Error: {e}")
        time.sleep(5)  # Wait before retry
```

## API Endpoints

### Health Check
```
GET http://172.28.93.21:5001/health
```

### Upload Image
```
POST http://172.28.93.21:5001/upload/image
Content-Type: multipart/form-data
Body: image=<file>
```

### Upload Audio
```
POST http://172.28.93.21:5001/upload/audio
Content-Type: multipart/form-data
Body: audio=<file>
```

### Batch Upload
```
POST http://172.28.93.21:5001/upload/batch
Content-Type: multipart/form-data
Body: image=<file>, audio=<file>
```

## Response Format

All uploads return JSON with confirmation:

```json
{
  "success": true,
  "message": "Image received and stored successfully",
  "file_id": "image_20251107_210027_448104",
  "filename": "image_20251107_210027_448104.jpg",
  "size": 7147,
  "timestamp": "2025-11-07T21:00:27.449646"
}
```

## Troubleshooting

### Cannot connect to backend
1. Make sure both devices are on the same network
2. Check that backend is running: `curl http://172.28.93.21:5001/health`
3. Verify firewall isn't blocking port 5001
4. Try pinging the backend: `ping 172.28.93.21`

### Upload fails
1. Check file exists and is readable
2. Verify file extension is supported (jpg, png, wav, mp3, etc.)
3. Check file size (must be under 100MB)
4. Look at the error message in the response

### Timeout errors
1. Increase timeout in requests: `timeout=30`
2. Check network stability
3. Try smaller files first

## Dependencies for Raspberry Pi

```bash
pip3 install requests
```

## Files to Copy to Raspberry Pi

1. `raspberry_pi_client.py` - The client library
2. This integration guide

## Testing Connection

Before integrating with your camera code, test the connection:

```bash
# On Raspberry Pi
curl http://172.28.93.21:5001/health
```

You should see:
```json
{
  "status": "healthy",
  "service": "raspberry-pi-backend",
  "timestamp": "2025-11-07T21:02:00.000000"
}
```

## Git Workflow

Your friend can work on their branch and just use the backend URL:

```bash
# On their branch
git checkout their-raspberry-pi-branch

# Add the client code
# Use BACKEND_URL = "http://172.28.93.21:5001"

# Test uploads
python3 test_upload.py
```

No need to merge branches - just use the API endpoints!
