import threading
import time
import os
from persistqueue import Queue
import requests
from typing import Literal
from microphone import Microphone
from camera import Camera
from recognize_faces import FaceRecognition

api_url_base = "https://2025-ai-hackathon-raspberry-api-api-production.up.railway.app"
QUEUE_PATH = "temp/queue"
queue = Queue(QUEUE_PATH, autosave=True)

def check_network(url="https://www.google.com", timeout=3):
    try:
        requests.get(url, timeout=timeout)
        return True
    except:
        return False

def uploader(save_path, api_url_base, file_type: Literal["image", "audio"], tags=None):  # Only 'image' or 'audio' used
    key = 'image' if file_type == 'image' else 'audio'
    content_type = 'image/jpeg' if file_type == 'image' else 'audio/wav'
    api_url = f"{api_url_base}/upload/{file_type}"
    files = None
    data = {"folder": "temp"}
    if file_type == "image" and tags:
        # SPI expects comma-separated string for detected_persons
        data["detected_persons"] = ",".join(tags) if isinstance(tags, list) else str(tags)
    with open(save_path, 'rb') as f:
        files = {key: (os.path.basename(save_path), f, content_type)}
        try:
            response = requests.post(api_url, files=files, data=data, timeout=10)
        except Exception as e:
            print(e)
            return None
    return response

def audio_worker(interval=30):
    mic = Microphone()
    while True:
        mic.start_recording()
        time.sleep(interval)
        path = mic.stop_recording()
        print(f"Audio saved: {path}")
        queue.put({"type": "audio", "path": path})

def video_worker():
    known_faces = os.path.join("data", "known_faces.pkl")
    threshold = 0.6
    recognizer = FaceRecognition(known_faces)
    recognizer.threshold = threshold
    cam = Camera()
    try:
        cam.open()
        print("Video monitoring...")
        last_pic_time = time.time() - 10
        while True:
            img_path = cam.capture_frame(save_path=os.path.join("temp", "monitor.jpg"))
            result = None
            if img_path and os.path.isfile(img_path):
                result = recognizer.process_image(img_path)  # should return list of names
                print(result)
            if result and (time.time() - last_pic_time >= 10):
                snapshot_path = cam.capture_frame()
                print(f"Detected face, image saved: {snapshot_path}")
                queue.put({"type": "image", "path": snapshot_path, "tags": result})
                last_pic_time = time.time()
            time.sleep(1)
    finally:
        cam.close()

def upload_worker():
    while True:
        if not queue.empty() and check_network():
            item = queue.get()
            resp = uploader(item["path"], api_url_base, file_type=item["type"], tags=item.get("tags"))
            print(f"Uploaded {item['path']}, status: {getattr(resp,'status_code',None)}")
            if resp and getattr(resp, 'status_code', None) == 200:
                try:
                    os.remove(item["path"])
                    print(f"Deleted {item['path']} after upload.")
                except Exception as e:
                    print(f"Delete error: {e}")
            queue.task_done()
        else:
            time.sleep(5)

def main():
    if not os.path.exists("temp"):
        os.makedirs("temp")
    threads = [
        threading.Thread(target=audio_worker, daemon=True),
        threading.Thread(target=video_worker, daemon=True),
        threading.Thread(target=upload_worker, daemon=True)
    ]
    for t in threads:
        t.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutdown: sync remaining queue before exit…")
        if check_network():
            print("Network available: uploading remaining queue.")
            while not queue.empty():
                item = queue.get()
                resp = uploader(item["path"], api_url_base, file_type=item["type"], tags=item.get("tags"))
                print(f"Uploaded {item['path']}, status: {getattr(resp,'status_code',None)}")
                if resp and getattr(resp, 'status_code', None) == 200:
                    try:
                        os.remove(item["path"])
                        print(f"Deleted {item['path']} after upload.")
                    except Exception as e:
                        print(f"Delete error: {e}")
                queue.task_done()
        else:
            print("No network: queue saved for next start.")

if __name__ == "__main__":
    main()

