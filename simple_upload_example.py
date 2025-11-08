"""
Simple Upload Example for Raspberry Pi
Copy this file to your Raspberry Pi and modify the file paths
"""

import requests
import json

# BACKEND URL - Your friend should use this exact URL
BACKEND_URL = "http://172.28.93.21:5001"

def upload_image(image_path):
    """Upload an image to the backend"""
    try:
        print(f"Uploading image: {image_path}")
        
        with open(image_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(
                f"{BACKEND_URL}/upload/image",
                files=files,
                timeout=30
            )
        
        if response.status_code == 200:
            result = response.json()
            print("✓ SUCCESS!")
            print(f"  File ID: {result['file_id']}")
            print(f"  Size: {result['size']} bytes")
            print(f"  Timestamp: {result['timestamp']}")
            return result
        else:
            print(f"✗ FAILED! Status: {response.status_code}")
            print(f"  Error: {response.json()}")
            return None
            
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return None


def upload_audio(audio_path):
    """Upload an audio file to the backend"""
    try:
        print(f"Uploading audio: {audio_path}")
        
        with open(audio_path, 'rb') as f:
            files = {'audio': f}
            response = requests.post(
                f"{BACKEND_URL}/upload/audio",
                files=files,
                timeout=30
            )
        
        if response.status_code == 200:
            result = response.json()
            print("✓ SUCCESS!")
            print(f"  File ID: {result['file_id']}")
            print(f"  Size: {result['size']} bytes")
            print(f"  Timestamp: {result['timestamp']}")
            return result
        else:
            print(f"✗ FAILED! Status: {response.status_code}")
            print(f"  Error: {response.json()}")
            return None
            
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return None


def upload_both(image_path, audio_path):
    """Upload both image and audio together"""
    try:
        print(f"Uploading batch: image={image_path}, audio={audio_path}")
        
        files = {
            'image': open(image_path, 'rb'),
            'audio': open(audio_path, 'rb')
        }
        
        response = requests.post(
            f"{BACKEND_URL}/upload/batch",
            files=files,
            timeout=30
        )
        
        # Close files
        for f in files.values():
            f.close()
        
        if response.status_code == 200:
            result = response.json()
            print("✓ SUCCESS!")
            if result.get('image'):
                print(f"  Image ID: {result['image']['file_id']}")
            if result.get('audio'):
                print(f"  Audio ID: {result['audio']['file_id']}")
            return result
        else:
            print(f"✗ FAILED! Status: {response.status_code}")
            print(f"  Error: {response.json()}")
            return None
            
    except Exception as e:
        print(f"✗ ERROR: {e}")
        return None


def check_backend():
    """Check if backend is reachable"""
    try:
        response = requests.get(f"{BACKEND_URL}/health", timeout=5)
        if response.status_code == 200:
            print("✓ Backend is reachable!")
            print(f"  Response: {response.json()}")
            return True
        else:
            print(f"✗ Backend returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Cannot reach backend: {e}")
        return False


# EXAMPLE USAGE
if __name__ == "__main__":
    print("=" * 60)
    print("Raspberry Pi Upload Example")
    print("=" * 60)
    
    # First, check if backend is reachable
    print("\n1. Checking backend connection...")
    if not check_backend():
        print("\nERROR: Cannot connect to backend!")
        print("Make sure:")
        print("  - Backend server is running")
        print("  - Both devices are on the same network")
        print("  - URL is correct: http://172.28.93.21:5001")
        exit(1)
    
    print("\n" + "=" * 60)
    print("Backend is ready! Now you can upload files.")
    print("=" * 60)
    
    # REPLACE THESE PATHS WITH YOUR ACTUAL FILE PATHS
    print("\nTo upload files, call:")
    print("  upload_image('/path/to/your/image.jpg')")
    print("  upload_audio('/path/to/your/audio.wav')")
    print("  upload_both('/path/to/image.jpg', '/path/to/audio.wav')")
    
    # Example (uncomment and modify paths to test):
    # upload_image('/home/pi/captured_image.jpg')
    # upload_audio('/home/pi/recorded_audio.wav')
    # upload_both('/home/pi/image.jpg', '/home/pi/audio.wav')
