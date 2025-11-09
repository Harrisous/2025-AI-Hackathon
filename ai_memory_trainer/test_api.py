#!/usr/bin/env python3
"""
Simple test script for Memory Trainer API
"""

import requests
import json
import time

BASE_URL = "http://localhost:8000"


def test_api():
    print("🧪 Testing Memory Trainer API\n")
    
    # 1. Health check
    print("1. Health Check...")
    res = requests.get(f"{BASE_URL}/api/health")
    print(f"   Status: {res.json()}")
    
    # 2. Start session
    print("\n2. Starting Session...")
    res = requests.post(f"{BASE_URL}/api/session/start", json={})
    data = res.json()
    session_id = data['session_id']
    print(f"   Session ID: {session_id}")
    print(f"   Warmup Message: {data['message']}")
    
    # 3. Respond to warmup
    print("\n3. Responding to Warmup...")
    res = requests.post(
        f"{BASE_URL}/api/session/{session_id}/warmup",
        json={"message": "I'm feeling good!"}
    )
    data = res.json()
    print(f"   Response: {data['message']}")
    
    # 4. Start training
    print("\n4. Starting Training...")
    res = requests.post(
        f"{BASE_URL}/api/session/{session_id}/training/start",
        json={"num_questions": 3}
    )
    data = res.json()
    print(f"   Question 1: {data['question']}")
    
    # 5. Submit correct answer
    print("\n5. Submitting Answer...")
    res = requests.post(
        f"{BASE_URL}/api/session/{session_id}/answer",
        json={"answer": "My daughter"}
    )
    data = res.json()
    print(f"   Correct: {data['correct']}")
    print(f"   Feedback: {data['feedback']}")
    
    # 6. Get next question
    if data.get('move_to_next'):
        print("\n6. Getting Next Question...")
        res = requests.post(f"{BASE_URL}/api/session/{session_id}/next")
        data = res.json()
        
        if data['phase'] == 'completed':
            print("   All questions completed!")
        else:
            print(f"   Question 2: {data['question']}")
            
            # Submit wrong answer to test hints
            print("\n7. Submitting Wrong Answer...")
            res = requests.post(
                f"{BASE_URL}/api/session/{session_id}/answer",
                json={"answer": "wrong answer"}
            )
            data = res.json()
            print(f"   Correct: {data['correct']}")
            print(f"   Hint: {data.get('hint', 'N/A')}")
    
    # 8. Get session status
    print("\n8. Checking Session Status...")
    res = requests.get(f"{BASE_URL}/api/session/{session_id}/status")
    data = res.json()
    print(f"   Phase: {data['phase']}")
    print(f"   Progress: {data['current_question_index']}/{data['total_questions']}")
    
    # 9. End session
    print("\n9. Ending Session...")
    res = requests.post(f"{BASE_URL}/api/session/{session_id}/end")
    data = res.json()
    print(f"   Summary: {data['summary']}")
    print(f"   Stats: {data['stats']}")
    
    # 10. Test QA endpoints
    print("\n10. Testing QA Database...")
    res = requests.get(f"{BASE_URL}/api/qa")
    data = res.json()
    print(f"   Total QAs: {len(data['data'])}")
    
    print("\n✅ API Test Complete!")


if __name__ == "__main__":
    try:
        test_api()
    except requests.exceptions.ConnectionError:
        print("❌ Error: Could not connect to API server.")
        print("   Make sure the server is running: python api.py")
    except Exception as e:
        print(f"❌ Error: {e}")

