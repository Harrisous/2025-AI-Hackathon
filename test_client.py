"""
Test client to simulate Raspberry Pi sending images and audio
Use this to test the backend API
"""

import requests
from pathlib import Path
import json

# Backend URL (change if deployed elsewhere)
BASE_URL = "http://localhost:5000"


def test_health():
    """Test health check endpoint"""
    print("\n=== Testing Health Check ===")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_upload_image(image_path):
    """Test image upload"""
    print("\n=== Testing Image Upload ===")
    
    if not Path(image_path).exists():
        print(f"Error: Image file not found at {image_path}")
        return False
    
    with open(image_path, 'rb') as f:
        files = {'image': f}
        response = requests.post(f"{BASE_URL}/upload/image", files=files)
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_upload_audio(audio_path):
    """Test audio upload"""
    print("\n=== Testing Audio Upload ===")
    
    if not Path(audio_path).exists():
        print(f"Error: Audio file not found at {audio_path}")
        return False
    
    with open(audio_path, 'rb') as f:
        files = {'audio': f}
        response = requests.post(f"{BASE_URL}/upload/audio", files=files)
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_batch_upload(image_path, audio_path):
    """Test batch upload (image + audio together)"""
    print("\n=== Testing Batch Upload ===")
    
    files = {}
    
    if Path(image_path).exists():
        files['image'] = open(image_path, 'rb')
    else:
        print(f"Warning: Image file not found at {image_path}")
    
    if Path(audio_path).exists():
        files['audio'] = open(audio_path, 'rb')
    else:
        print(f"Warning: Audio file not found at {audio_path}")
    
    if not files:
        print("Error: No valid files to upload")
        return False
    
    response = requests.post(f"{BASE_URL}/upload/batch", files=files)
    
    # Close file handles
    for f in files.values():
        f.close()
    
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_list_files():
    """Test listing all files"""
    print("\n=== Testing List Files ===")
    response = requests.get(f"{BASE_URL}/files")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


def test_get_metadata(file_id):
    """Test getting metadata for a file"""
    print(f"\n=== Testing Get Metadata for {file_id} ===")
    response = requests.get(f"{BASE_URL}/metadata/{file_id}")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200


if __name__ == "__main__":
    print("=" * 60)
    print("Raspberry Pi Backend Test Client")
    print("=" * 60)
    
    # Test health check
    test_health()
    
    # Example usage - replace with actual file paths
    print("\n" + "=" * 60)
    print("To test uploads, provide file paths:")
    print("Example:")
    print("  test_upload_image('path/to/image.jpg')")
    print("  test_upload_audio('path/to/audio.wav')")
    print("  test_batch_upload('path/to/image.jpg', 'path/to/audio.wav')")
    print("=" * 60)
    
    # Uncomment and modify these lines with actual file paths to test
    # test_upload_image('test_image.jpg')
    # test_upload_audio('test_audio.wav')
    # test_batch_upload('test_image.jpg', 'test_audio.wav')
    # test_list_files()
