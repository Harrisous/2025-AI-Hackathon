"""
Chunked Audio System for Alzheimer's Camera
- Records audio in 5-minute chunks
- Captures images continuously
- Uses timestamps to match images with audio chunks
- Sends everything to backend with synchronized timestamps
"""

import time
import os
from datetime import datetime, timedelta
import threading
import queue
from simple_upload_example import upload_image, upload_audio, check_backend

# Configuration
BACKEND_URL = "http://172.28.93.21:5001"
AUDIO_CHUNK_DURATION = 300  # 5 minutes = 300 seconds
IMAGE_CAPTURE_INTERVAL = 5  # Capture image every 5 seconds
TEMP_FOLDER = "/tmp/alzheimer_capture"

# Create temp folder
os.makedirs(TEMP_FOLDER, exist_ok=True)

# Queues for managing uploads
upload_queue = queue.Queue()


class AudioChunk:
    """Represents a 5-minute audio chunk with timestamp"""
    def __init__(self, start_time, end_time, file_path):
        self.start_time = start_time
        self.end_time = end_time
        self.file_path = file_path
        self.chunk_id = start_time.strftime("%Y%m%d_%H%M%S")
    
    def __repr__(self):
        return f"AudioChunk({self.chunk_id}, {self.start_time} to {self.end_time})"


class ImageCapture:
    """Represents a captured image with timestamp"""
    def __init__(self, timestamp, file_path):
        self.timestamp = timestamp
        self.file_path = file_path
        self.image_id = timestamp.strftime("%Y%m%d_%H%M%S_%f")
    
    def matches_audio_chunk(self, audio_chunk):
        """Check if this image belongs to the audio chunk"""
        return audio_chunk.start_time <= self.timestamp <= audio_chunk.end_time
    
    def __repr__(self):
        return f"Image({self.image_id}, {self.timestamp})"


def capture_image():
    """
    Capture image from camera
    Replace with actual camera code
    """
    try:
        from picamera2 import Picamera2
        camera = Picamera2()
        
        timestamp = datetime.now()
        image_path = f"{TEMP_FOLDER}/image_{timestamp.strftime('%Y%m%d_%H%M%S_%f')}.jpg"
        
        camera.capture_file(image_path)
        print(f"📸 Captured: {image_path}")
        
        return ImageCapture(timestamp, image_path)
    except Exception as e:
        print(f"Error capturing image: {e}")
        # For testing: create dummy image
        from PIL import Image, ImageDraw
        timestamp = datetime.now()
        image_path = f"{TEMP_FOLDER}/image_{timestamp.strftime('%Y%m%d_%H%M%S_%f')}.jpg"
        
        img = Image.new('RGB', (640, 480), color=(100, 150, 200))
        d = ImageDraw.Draw(img)
        d.text((10, 10), f"Captured at: {timestamp.strftime('%H:%M:%S')}", fill=(255, 255, 255))
        img.save(image_path)
        
        return ImageCapture(timestamp, image_path)


def record_audio_chunk(duration=300):
    """
    Record audio for 5 minutes
    Replace with actual audio recording code
    """
    try:
        import pyaudio
        import wave
        
        start_time = datetime.now()
        chunk_id = start_time.strftime("%Y%m%d_%H%M%S")
        audio_path = f"{TEMP_FOLDER}/audio_chunk_{chunk_id}.wav"
        
        print(f"🎤 Recording audio chunk: {chunk_id} (5 minutes)...")
        
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
        
        frames = []
        for i in range(0, int(RATE / CHUNK * duration)):
            data = stream.read(CHUNK, exception_on_overflow=False)
            frames.append(data)
            
            # Print progress every 30 seconds
            if i % (30 * RATE // CHUNK) == 0:
                elapsed = i * CHUNK / RATE
                print(f"   Recording... {int(elapsed)}s / {duration}s")
        
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
        
        end_time = datetime.now()
        print(f"✅ Audio chunk recorded: {audio_path}")
        
        return AudioChunk(start_time, end_time, audio_path)
        
    except Exception as e:
        print(f"Error recording audio: {e}")
        # For testing: create dummy audio
        import wave
        import struct
        import numpy as np
        
        start_time = datetime.now()
        chunk_id = start_time.strftime("%Y%m%d_%H%M%S")
        audio_path = f"{TEMP_FOLDER}/audio_chunk_{chunk_id}.wav"
        
        # Create 5-second test audio instead of 5 minutes for testing
        sample_rate = 44100
        duration_test = 5  # 5 seconds for testing
        samples = [int(32767 * 0.3 * np.sin(2 * np.pi * 440 * i / sample_rate)) 
                  for i in range(int(sample_rate * duration_test))]
        
        with wave.open(audio_path, 'w') as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(sample_rate)
            wav_file.writeframes(struct.pack('h' * len(samples), *samples))
        
        end_time = start_time + timedelta(seconds=duration)
        return AudioChunk(start_time, end_time, audio_path)


def upload_worker():
    """
    Background worker that uploads captured data
    Matches images with audio chunks based on timestamps
    """
    while True:
        try:
            data = upload_queue.get()
            
            if data is None:  # Stop signal
                break
            
            if data['type'] == 'audio_chunk':
                audio_chunk = data['audio_chunk']
                images = data['images']
                
                print(f"\n📤 Uploading audio chunk: {audio_chunk.chunk_id}")
                print(f"   Time range: {audio_chunk.start_time.strftime('%H:%M:%S')} to {audio_chunk.end_time.strftime('%H:%M:%S')}")
                print(f"   Matched images: {len(images)}")
                
                # Upload audio chunk
                audio_result = upload_audio(audio_chunk.file_path)
                
                if audio_result and audio_result.get('success'):
                    print(f"   ✅ Audio uploaded: {audio_result['file_id']}")
                    
                    # Upload all matched images
                    uploaded_images = 0
                    for img in images:
                        img_result = upload_image(img.file_path)
                        if img_result and img_result.get('success'):
                            uploaded_images += 1
                            print(f"   ✅ Image uploaded: {img_result['file_id']} (captured at {img.timestamp.strftime('%H:%M:%S')})")
                        
                        # Clean up image file
                        if os.path.exists(img.file_path):
                            os.remove(img.file_path)
                    
                    print(f"   📊 Summary: {uploaded_images}/{len(images)} images uploaded")
                    
                    # Clean up audio file
                    if os.path.exists(audio_chunk.file_path):
                        os.remove(audio_chunk.file_path)
                else:
                    print(f"   ❌ Audio upload failed, keeping files for retry")
            
            upload_queue.task_done()
            
        except Exception as e:
            print(f"Error in upload worker: {e}")
            time.sleep(5)


def main():
    """
    Main loop - continuously captures images and records audio in chunks
    """
    print("=" * 70)
    print("🎥 Alzheimer's Camera System - Chunked Audio Mode")
    print("=" * 70)
    
    # Check backend
    print("\n🔍 Checking backend connection...")
    if not check_backend():
        print("❌ Cannot connect to backend!")
        return
    
    print("✅ Backend connected!\n")
    
    # Start upload worker
    print("🚀 Starting upload worker...")
    upload_thread = threading.Thread(target=upload_worker, daemon=True)
    upload_thread.start()
    
    print(f"📋 Configuration:")
    print(f"   - Audio chunk duration: {AUDIO_CHUNK_DURATION} seconds (5 minutes)")
    print(f"   - Image capture interval: {IMAGE_CAPTURE_INTERVAL} seconds")
    print(f"   - Images per chunk: ~{AUDIO_CHUNK_DURATION // IMAGE_CAPTURE_INTERVAL}")
    print("\n📹 Starting continuous capture...")
    print("Press Ctrl+C to stop\n")
    
    captured_images = []
    audio_thread = None
    current_audio_chunk = None
    
    try:
        # Start first audio recording in background
        def record_audio_background():
            return record_audio_chunk(AUDIO_CHUNK_DURATION)
        
        audio_thread = threading.Thread(target=lambda: globals().update({'current_audio_chunk': record_audio_background()}))
        audio_thread.start()
        audio_start_time = datetime.now()
        
        while True:
            # Capture image
            img = capture_image()
            captured_images.append(img)
            
            # Check if audio chunk is complete
            elapsed = (datetime.now() - audio_start_time).total_seconds()
            
            if elapsed >= AUDIO_CHUNK_DURATION:
                # Wait for audio recording to finish
                audio_thread.join()
                audio_chunk = current_audio_chunk
                
                # Match images with this audio chunk
                matched_images = [img for img in captured_images 
                                 if img.matches_audio_chunk(audio_chunk)]
                
                print(f"\n🎬 Audio chunk complete!")
                print(f"   Chunk ID: {audio_chunk.chunk_id}")
                print(f"   Duration: {(audio_chunk.end_time - audio_chunk.start_time).total_seconds():.1f}s")
                print(f"   Images captured: {len(matched_images)}")
                
                # Add to upload queue
                upload_queue.put({
                    'type': 'audio_chunk',
                    'audio_chunk': audio_chunk,
                    'images': matched_images
                })
                
                # Clear captured images
                captured_images = []
                
                # Start next audio chunk
                audio_thread = threading.Thread(target=lambda: globals().update({'current_audio_chunk': record_audio_background()}))
                audio_thread.start()
                audio_start_time = datetime.now()
            
            # Wait before next image capture
            time.sleep(IMAGE_CAPTURE_INTERVAL)
            
    except KeyboardInterrupt:
        print("\n\n⏹️  Stopping capture system...")
        
        # Upload remaining images if any
        if captured_images and audio_thread:
            audio_thread.join()
            upload_queue.put({
                'type': 'audio_chunk',
                'audio_chunk': current_audio_chunk,
                'images': captured_images
            })
        
        upload_queue.put(None)  # Stop upload worker
        upload_thread.join(timeout=10)
        print("✅ Stopped successfully")


if __name__ == "__main__":
    main()
