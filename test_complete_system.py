"""
Complete System Test
Simulates the Raspberry Pi capturing and sending data
"""

import time
from simple_upload_example import upload_both, check_backend
from PIL import Image
import numpy as np
import wave
import struct

def create_test_image(filename, label):
    """Create a test image with text"""
    from PIL import ImageDraw, ImageFont
    
    # Create a colorful image
    img = Image.new('RGB', (640, 480), color=(73, 109, 137))
    d = ImageDraw.Draw(img)
    
    # Add text
    d.text((10, 10), label, fill=(255, 255, 0))
    d.text((10, 50), f"Captured at: {time.strftime('%H:%M:%S')}", fill=(255, 255, 255))
    
    img.save(filename)
    print(f"📸 Created test image: {filename}")
    return filename


def create_test_audio(filename, duration=2):
    """Create a test audio file (beep sound)"""
    sample_rate = 44100
    frequency = 440  # A4 note
    
    # Generate sine wave
    samples = []
    for i in range(int(sample_rate * duration)):
        value = int(32767 * 0.3 * np.sin(2 * np.pi * frequency * i / sample_rate))
        samples.append(value)
    
    # Save as WAV
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(struct.pack('h' * len(samples), *samples))
    
    print(f"🎤 Created test audio: {filename}")
    return filename


def simulate_conversation(person_name, conversation_text):
    """Simulate a conversation being captured"""
    print("\n" + "=" * 60)
    print(f"🗣️  SIMULATING CONVERSATION WITH: {person_name}")
    print(f"💬 Conversation: \"{conversation_text}\"")
    print("=" * 60)
    
    # Create test files
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    image_file = f"test_capture_{person_name}_{timestamp}.jpg"
    audio_file = f"test_audio_{person_name}_{timestamp}.wav"
    
    # Simulate camera capture
    print("\n1️⃣ Camera capturing image...")
    create_test_image(image_file, f"Photo of: {person_name}")
    time.sleep(0.5)
    
    # Simulate audio recording
    print("2️⃣ Microphone recording conversation...")
    create_test_audio(audio_file, duration=2)
    time.sleep(0.5)
    
    # Upload to backend
    print("3️⃣ Raspberry Pi sending to backend...")
    result = upload_both(image_file, audio_file)
    
    if result and result.get('success'):
        print("\n✅ SUCCESS! Data received by backend")
        print(f"   📸 Image ID: {result['image']['file_id']}")
        print(f"   🎤 Audio ID: {result['audio']['file_id']}")
        print(f"   📊 Image Size: {result['image']['size']} bytes")
        print(f"   📊 Audio Size: {result['audio']['size']} bytes")
        print(f"   ⏰ Timestamp: {result['image']['timestamp']}")
        
        # Clean up test files
        import os
        os.remove(image_file)
        os.remove(audio_file)
        print("\n🧹 Cleaned up temporary files")
        
        return True
    else:
        print("\n❌ FAILED! Could not send to backend")
        return False


def main():
    print("=" * 60)
    print("🧪 COMPLETE SYSTEM TEST")
    print("Testing Alzheimer's Camera System End-to-End")
    print("=" * 60)
    
    # Step 1: Check backend
    print("\n📡 Step 1: Checking backend connection...")
    if not check_backend():
        print("❌ Backend is not running!")
        print("Please start the backend first: python3 app.py")
        return
    
    print("✅ Backend is ready!\n")
    time.sleep(1)
    
    # Step 2: Simulate multiple conversations
    print("📋 Step 2: Simulating patient conversations...\n")
    time.sleep(1)
    
    conversations = [
        ("Father", "Hi Dad, how are you today?"),
        ("Mother", "Mom, did you take your medicine?"),
        ("Sister", "Hey sis, want to go for a walk?"),
    ]
    
    success_count = 0
    for person, conversation in conversations:
        if simulate_conversation(person, conversation):
            success_count += 1
        time.sleep(2)  # Wait between conversations
    
    # Step 3: Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY")
    print("=" * 60)
    print(f"✅ Successful uploads: {success_count}/{len(conversations)}")
    print(f"📁 Files stored in: data/images/ and data/audio/")
    print("\n🔍 Next steps:")
    print("   1. Check data/images/ folder - you should see 3 images")
    print("   2. Check data/audio/ folder - you should see 3 audio files")
    print("   3. Each file has metadata in data/metadata/")
    print("\n💡 This simulates what the Raspberry Pi will do!")
    print("=" * 60)


if __name__ == "__main__":
    main()
