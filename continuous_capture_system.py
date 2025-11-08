"""
Continuous Capture System for Alzheimer's Patient Camera
This runs on the Raspberry Pi and continuously:
1. Captures images from the neck camera
2. Records audio when conversation is detected
3. Sends everything to the backend for processing
"""

import time
import os
from datetime import datetime
from simple_upload_example import upload_both, check_backend
import threading
import queue

# Configuration
BACKEND_URL = "http://172.28.93.21:5001"
CAPTURE_INTERVAL = 5  # Capture image every 5 seconds
AUDIO_CHUNK_DURATION = 10  # Record audio in 10-second chunks when conversation detected
TEMP_FOLDER = "/tmp/alzheimer_capture"

# Create temp folder
os.makedirs(TEMP_FOLDER, exist_ok=True)

# Queue for storing capture data
capture_queue = queue.Queue()


def capture_image():
    """
    Capture image from neck camera
    Replace this with your actual camera code
    """
    # Example using picamera2 (Raspberry Pi Camera)
    try:
        from picamera2 import Picamera2
        camera = Picamera2()
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        image_path = f"{TEMP_FOLDER}/image_{timestamp}.jpg"
        
        camera.capture_file(image_path)
        print(f"📸 Captured image: {image_path}")
        return image_path
    except Exception as e:
        print(f"Error capturing image: {e}")
        return None


def is_conversation_happening():
    """
    Detect if conversation is happening
    Replace this with actual audio detection logic
    
    Options:
    1. Simple: Check if audio level is above threshold
    2. Advanced: Use voice activity detection (VAD)
    3. ML-based: Use speech detection model
    """
    # PLACEHOLDER - Replace with actual detection
    # For now, returns True to always record
    # You can add microphone level detection here
    
    import pyaudio
    import numpy as np
    
    try:
        # Initialize audio
        p = pyaudio.PyAudio()
        stream = p.open(format=pyaudio.paInt16,
                       channels=1,
                       rate=44100,
                       input=True,
                       frames_per_buffer=1024)
        
        # Read audio chunk
        data = stream.read(1024, exception_on_overflow=False)
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Convert to numpy array
        audio_data = np.frombuffer(data, dtype=np.int16)
        
        # Calculate volume (RMS)
        volume = np.sqrt(np.mean(audio_data**2))
        
        # Threshold for conversation (adjust based on testing)
        CONVERSATION_THRESHOLD = 500
        
        if volume > CONVERSATION_THRESHOLD:
            print(f"🎤 Conversation detected! Volume: {volume}")
            return True
        else:
            return False
            
    except Exception as e:
        print(f"Error detecting conversation: {e}")
        return False


def record_audio(duration=10):
    """
    Record audio for specified duration
    Replace this with your actual audio recording code
    """
    try:
        import pyaudio
        import wave
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        audio_path = f"{TEMP_FOLDER}/audio_{timestamp}.wav"
        
        # Audio settings
        CHUNK = 1024
        FORMAT = pyaudio.paInt16
        CHANNELS = 1
        RATE = 44100
        
        p = pyaudio.PyAudio()
        
        stream = p.open(format=FORMAT,
                       channels=CHANNELS,
                       rate=RATE,
                       input=True,
                       frames_per_buffer=CHUNK)
        
        print(f"🎤 Recording audio for {duration} seconds...")
        
        frames = []
        for i in range(0, int(RATE / CHUNK * duration)):
            data = stream.read(CHUNK, exception_on_overflow=False)
            frames.append(data)
        
        stream.stop_stream()
        stream.close()
        p.terminate()
        
        # Save to file
        wf = wave.open(audio_path, 'wb')
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(p.get_sample_size(FORMAT))
        wf.setframerate(RATE)
        wf.writeframes(b''.join(frames))
        wf.close()
        
        print(f"🎤 Recorded audio: {audio_path}")
        return audio_path
        
    except Exception as e:
        print(f"Error recording audio: {e}")
        return None


def upload_worker():
    """
    Background worker that uploads captured data
    Runs in separate thread to not block capture
    """
    while True:
        try:
            # Get data from queue (blocks until available)
            data = capture_queue.get()
            
            if data is None:  # Poison pill to stop thread
                break
            
            image_path = data.get('image')
            audio_path = data.get('audio')
            
            # Upload to backend
            print(f"📤 Uploading to backend...")
            result = upload_both(image_path, audio_path)
            
            if result and result.get('success'):
                print(f"✅ Upload successful!")
                print(f"   Image ID: {result['image']['file_id']}")
                print(f"   Audio ID: {result['audio']['file_id']}")
                
                # Clean up temp files after successful upload
                if os.path.exists(image_path):
                    os.remove(image_path)
                if os.path.exists(audio_path):
                    os.remove(audio_path)
            else:
                print(f"❌ Upload failed, keeping files for retry")
            
            capture_queue.task_done()
            
        except Exception as e:
            print(f"Error in upload worker: {e}")
            time.sleep(5)


def main():
    """
    Main loop - continuously captures and uploads
    """
    print("=" * 60)
    print("Alzheimer's Patient Camera System")
    print("=" * 60)
    
    # Check backend connection
    print("\n🔍 Checking backend connection...")
    if not check_backend():
        print("❌ Cannot connect to backend!")
        print("Please make sure backend is running at:", BACKEND_URL)
        return
    
    print("✅ Backend connected!")
    
    # Start upload worker thread
    print("\n🚀 Starting upload worker...")
    upload_thread = threading.Thread(target=upload_worker, daemon=True)
    upload_thread.start()
    
    print("\n📹 Starting continuous capture...")
    print("Press Ctrl+C to stop\n")
    
    last_image_time = 0
    current_audio_path = None
    recording = False
    
    try:
        while True:
            current_time = time.time()
            
            # Capture image every CAPTURE_INTERVAL seconds
            if current_time - last_image_time >= CAPTURE_INTERVAL:
                image_path = capture_image()
                last_image_time = current_time
                
                # Check if conversation is happening
                if is_conversation_happening():
                    if not recording:
                        # Start recording
                        print("🎤 Conversation started, recording...")
                        current_audio_path = record_audio(AUDIO_CHUNK_DURATION)
                        recording = True
                        
                        # Add to upload queue
                        if image_path and current_audio_path:
                            capture_queue.put({
                                'image': image_path,
                                'audio': current_audio_path
                            })
                            print(f"📦 Added to upload queue (Queue size: {capture_queue.qsize()})")
                        
                        recording = False
                else:
                    # No conversation, just upload image with silent audio or skip
                    print("🔇 No conversation detected")
            
            # Small sleep to prevent CPU overuse
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\n\n⏹️  Stopping capture system...")
        capture_queue.put(None)  # Stop upload worker
        upload_thread.join(timeout=5)
        print("✅ Stopped successfully")


if __name__ == "__main__":
    main()
