# Raspberry Pi Camera Backend

Backend API for receiving and storing images and audio from a Raspberry Pi camera system.

## Features

- ✅ **Image Upload**: Receive and store images (JPG, PNG, etc.)
- ✅ **Audio Upload**: Receive and store audio files (WAV, MP3, etc.)
- ✅ **Batch Upload**: Accept both image and audio in a single request
- ✅ **Confirmation Response**: Immediate acknowledgment of received files
- ✅ **Metadata Tracking**: Store metadata for each uploaded file
- ✅ **Organized Storage**: Separate folders for images, audio, and metadata
- ✅ **Health Check**: Monitor backend status

## Project Structure

```
2025-AI-Hackathon/
├── app.py                      # Main Flask backend API
├── requirements.txt            # Python dependencies
├── test_client.py             # Test client for local testing
├── raspberry_pi_client.py     # Example client for Raspberry Pi
├── README.md                  # This file
└── data/                      # Created automatically
    ├── images/                # Stored images
    ├── audio/                 # Stored audio files
    └── metadata/              # JSON metadata for each file
```

## Setup Instructions

### 1. Install Dependencies

```bash
# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install required packages
pip install -r requirements.txt
```

### 2. Run the Backend Server

```bash
python app.py
```

The server will start on `http://0.0.0.0:5000` (accessible from network)

### 3. Test the Backend

```bash
# In another terminal, test the health endpoint
curl http://localhost:5000/health

# Or use the test client
python test_client.py
```

## API Endpoints

### Health Check
```
GET /health
```
Returns server status and timestamp.

**Response:**
```json
{
  "status": "healthy",
  "service": "raspberry-pi-backend",
  "timestamp": "2025-11-07T20:55:00.000000"
}
```

### Upload Image
```
POST /upload/image
Content-Type: multipart/form-data
```

**Parameters:**
- `image`: Image file (JPG, PNG, GIF, BMP)

**Response:**
```json
{
  "success": true,
  "message": "Image received and stored successfully",
  "file_id": "image_20251107_205500_123456",
  "filename": "image_20251107_205500_123456.jpg",
  "size": 245678,
  "timestamp": "2025-11-07T20:55:00.123456"
}
```

### Upload Audio
```
POST /upload/audio
Content-Type: multipart/form-data
```

**Parameters:**
- `audio`: Audio file (WAV, MP3, OGG, FLAC, M4A, AAC)

**Response:**
```json
{
  "success": true,
  "message": "Audio received and stored successfully",
  "file_id": "audio_20251107_205500_123456",
  "filename": "audio_20251107_205500_123456.wav",
  "size": 1234567,
  "timestamp": "2025-11-07T20:55:00.123456"
}
```

### Batch Upload (Image + Audio)
```
POST /upload/batch
Content-Type: multipart/form-data
```

**Parameters:**
- `image`: Image file (optional)
- `audio`: Audio file (optional)

**Response:**
```json
{
  "success": true,
  "image": {
    "file_id": "image_20251107_205500_123456",
    "filename": "image_20251107_205500_123456.jpg",
    "size": 245678,
    "timestamp": "2025-11-07T20:55:00.123456"
  },
  "audio": {
    "file_id": "audio_20251107_205500_123456",
    "filename": "audio_20251107_205500_123456.wav",
    "size": 1234567,
    "timestamp": "2025-11-07T20:55:00.123456"
  },
  "errors": []
}
```

### List Files
```
GET /files
```

**Response:**
```json
{
  "success": true,
  "images": {
    "count": 10,
    "files": ["image_20251107_205500_123456.jpg", ...]
  },
  "audio": {
    "count": 10,
    "files": ["audio_20251107_205500_123456.wav", ...]
  }
}
```

### Get Metadata
```
GET /metadata/<file_id>
```

**Response:**
```json
{
  "success": true,
  "metadata": {
    "file_id": "image_20251107_205500_123456",
    "file_type": "image",
    "original_filename": "photo.jpg",
    "saved_filename": "image_20251107_205500_123456.jpg",
    "file_size": 245678,
    "upload_timestamp": "2025-11-07T20:55:00.123456",
    "status": "received"
  }
}
```

## Raspberry Pi Integration

### Example Code for Raspberry Pi

```python
from raspberry_pi_client import RaspberryPiClient

# Initialize client with your backend URL
client = RaspberryPiClient("http://YOUR_BACKEND_IP:5000")

# Check connection
if client.check_connection():
    # Send image
    client.send_image("/path/to/image.jpg")
    
    # Send audio
    client.send_audio("/path/to/audio.wav")
    
    # Or send both together
    client.send_batch("/path/to/image.jpg", "/path/to/audio.wav")
```

### Using curl from Raspberry Pi

```bash
# Upload image
curl -X POST -F "image=@photo.jpg" http://YOUR_BACKEND_IP:5000/upload/image

# Upload audio
curl -X POST -F "audio=@recording.wav" http://YOUR_BACKEND_IP:5000/upload/audio

# Upload both
curl -X POST -F "image=@photo.jpg" -F "audio=@recording.wav" http://YOUR_BACKEND_IP:5000/upload/batch
```

## Configuration

Edit `app.py` to customize:

- **Port**: Change `port=5000` in `app.run()`
- **Upload folder**: Modify `UPLOAD_FOLDER = 'data'`
- **Max file size**: Adjust `MAX_CONTENT_LENGTH` (default: 100MB)
- **Allowed extensions**: Update `ALLOWED_IMAGE_EXTENSIONS` or `ALLOWED_AUDIO_EXTENSIONS`

## Storage Structure

Files are stored with timestamps for easy organization:

```
data/
├── images/
│   ├── image_20251107_205500_123456.jpg
│   ├── image_20251107_205501_234567.jpg
│   └── ...
├── audio/
│   ├── audio_20251107_205500_123456.wav
│   ├── audio_20251107_205501_234567.wav
│   └── ...
└── metadata/
    ├── image_20251107_205500_123456.json
    ├── audio_20251107_205500_123456.json
    └── ...
```

## Next Steps for Processing

After files are stored, you can:

1. **Image Processing**: 
   - Access images from `data/images/`
   - Use OpenCV, PIL, or other libraries
   - Implement object detection, face recognition, etc.

2. **Audio Processing**:
   - Access audio from `data/audio/`
   - Use librosa, pydub, or speech recognition libraries
   - Implement speech-to-text, audio analysis, etc.

3. **Metadata Analysis**:
   - Query metadata from `data/metadata/`
   - Track upload patterns, file sizes, timestamps

## Troubleshooting

### Backend not accessible from Raspberry Pi
- Ensure backend is running with `host='0.0.0.0'`
- Check firewall settings
- Verify both devices are on the same network
- Use the correct IP address (not localhost)

### File upload fails
- Check file size (must be under MAX_CONTENT_LENGTH)
- Verify file extension is allowed
- Ensure sufficient disk space

### Connection timeout
- Increase timeout in client code
- Check network stability
- Verify backend URL is correct

## Security Notes

For production use, consider:
- Add authentication (API keys, JWT tokens)
- Use HTTPS instead of HTTP
- Implement rate limiting
- Add file validation and sanitization
- Set up proper logging and monitoring

## License

MIT License - Feel free to modify for your hackathon project!
