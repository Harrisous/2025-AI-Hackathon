"""
Raspberry Pi Client Example
This script shows how to send images and audio from Raspberry Pi to the backend
"""

import requests
import json
from datetime import datetime
import time

# Configure your backend URL
BACKEND_URL = "http://YOUR_BACKEND_IP:5000"  # Replace with your backend server IP


class RaspberryPiClient:
    """Client for sending data from Raspberry Pi to backend"""
    
    def __init__(self, backend_url):
        self.backend_url = backend_url
        self.session = requests.Session()
    
    def check_connection(self):
        """Check if backend is reachable"""
        try:
            response = self.session.get(f"{self.backend_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"✓ Connected to backend: {response.json()}")
                return True
            else:
                print(f"✗ Backend returned status {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"✗ Cannot connect to backend: {e}")
            return False
    
    def send_image(self, image_path):
        """
        Send an image to the backend
        
        Args:
            image_path: Path to the image file
            
        Returns:
            dict: Response from backend or None if failed
        """
        try:
            print(f"Sending image: {image_path}")
            
            with open(image_path, 'rb') as f:
                files = {'image': f}
                response = self.session.post(
                    f"{self.backend_url}/upload/image",
                    files=files,
                    timeout=30
                )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✓ Image uploaded successfully!")
                print(f"  File ID: {result.get('file_id')}")
                print(f"  Size: {result.get('size')} bytes")
                return result
            else:
                print(f"✗ Upload failed: {response.status_code}")
                print(f"  Error: {response.json()}")
                return None
                
        except Exception as e:
            print(f"✗ Error sending image: {e}")
            return None
    
    def send_audio(self, audio_path):
        """
        Send an audio file to the backend
        
        Args:
            audio_path: Path to the audio file
            
        Returns:
            dict: Response from backend or None if failed
        """
        try:
            print(f"Sending audio: {audio_path}")
            
            with open(audio_path, 'rb') as f:
                files = {'audio': f}
                response = self.session.post(
                    f"{self.backend_url}/upload/audio",
                    files=files,
                    timeout=30
                )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✓ Audio uploaded successfully!")
                print(f"  File ID: {result.get('file_id')}")
                print(f"  Size: {result.get('size')} bytes")
                return result
            else:
                print(f"✗ Upload failed: {response.status_code}")
                print(f"  Error: {response.json()}")
                return None
                
        except Exception as e:
            print(f"✗ Error sending audio: {e}")
            return None
    
    def send_batch(self, image_path, audio_path):
        """
        Send both image and audio in a single request
        
        Args:
            image_path: Path to the image file
            audio_path: Path to the audio file
            
        Returns:
            dict: Response from backend or None if failed
        """
        try:
            print(f"Sending batch: image={image_path}, audio={audio_path}")
            
            files = {}
            if image_path:
                files['image'] = open(image_path, 'rb')
            if audio_path:
                files['audio'] = open(audio_path, 'rb')
            
            response = self.session.post(
                f"{self.backend_url}/upload/batch",
                files=files,
                timeout=30
            )
            
            # Close file handles
            for f in files.values():
                f.close()
            
            if response.status_code == 200:
                result = response.json()
                print(f"✓ Batch uploaded successfully!")
                if result.get('image'):
                    print(f"  Image ID: {result['image'].get('file_id')}")
                if result.get('audio'):
                    print(f"  Audio ID: {result['audio'].get('file_id')}")
                return result
            else:
                print(f"✗ Upload failed: {response.status_code}")
                print(f"  Error: {response.json()}")
                return None
                
        except Exception as e:
            print(f"✗ Error sending batch: {e}")
            return None


# Example usage for Raspberry Pi
if __name__ == "__main__":
    print("=" * 60)
    print("Raspberry Pi Client for Backend Upload")
    print("=" * 60)
    
    # Initialize client
    client = RaspberryPiClient(BACKEND_URL)
    
    # Check connection
    if not client.check_connection():
        print("\nPlease check:")
        print("1. Backend server is running")
        print("2. BACKEND_URL is correctly configured")
        print("3. Network connection is working")
        exit(1)
    
    print("\n" + "=" * 60)
    print("Example Usage:")
    print("=" * 60)
    print("""
# Send a single image
client.send_image('/path/to/captured_image.jpg')

# Send a single audio file
client.send_audio('/path/to/recorded_audio.wav')

# Send both together
client.send_batch('/path/to/image.jpg', '/path/to/audio.wav')

# Example: Continuous capture loop
while True:
    # Capture image with camera
    image_path = capture_image()  # Your camera code
    
    # Record audio
    audio_path = record_audio()   # Your audio recording code
    
    # Send to backend
    result = client.send_batch(image_path, audio_path)
    
    if result:
        print("Data sent successfully!")
    else:
        print("Failed to send data, will retry...")
    
    time.sleep(60)  # Wait before next capture
    """)
