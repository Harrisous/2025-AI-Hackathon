#!/usr/bin/env python3
"""
Face Detection and Recognition using face_recognition package
Minimal implementation
"""

import cv2
import numpy as np
import face_recognition
from pathlib import Path
import pickle


class FaceRecognition:
    def __init__(self, known_faces_path="data/known_faces.pkl"):
        # Load or initialize face database
        self.known_faces = self._load_known_faces(known_faces_path)
        self.threshold = 0.6
        
    def _load_known_faces(self, path):
        """Load known faces from pickle file"""
        if Path(path).exists():
            with open(path, 'rb') as f:
                return pickle.load(f)
        return {}
    
    def identify_face(self, embedding):
        """Identify face by comparing with known faces"""
        if not self.known_faces:
            return None, float('inf')
        
        names = list(self.known_faces.keys())
        known_embeddings = list(self.known_faces.values())
        
        # Calculate distances
        distances = face_recognition.face_distance(known_embeddings, embedding)
        min_distance = min(distances)
        
        if min_distance < self.threshold:
            identity = names[distances.argmin()]
        else:
            identity = None
        
        return identity, min_distance
    
    def process_image(self, image_path):
        """Process a single image: detect faces, recognize, and save with bounding boxes"""
        # Read image
        image = cv2.imread(str(image_path))
        if image is None:
            print(f"Error loading image: {image_path}")
            return
        
        rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Detect faces and get encodings
        face_locations = face_recognition.face_locations(rgb_image)
        face_encodings = face_recognition.face_encodings(rgb_image, face_locations)
        
        result = list() # to store the results
        # Process each detected face
        for (top, right, bottom, left), encoding in zip(face_locations, face_encodings):
            # Identify face
            identity, distance = self.identify_face(encoding)
            if identity != None:
                result.append(identity)
        return result

def main():
    from camera import Camera
    import os
    import time

    known_faces = os.path.join("data","known_faces.pkl")
    threshold = 0.3
    
    # Initialize face recognition
    recognizer = FaceRecognition(known_faces)
    recognizer.threshold = threshold

    # Process images
    try:
        cam = Camera()
        cam.open()
        print("Video monitoring...")
        last_pic_time = time.time() - 10
        while True:
            img_path = cam.capture_frame(save_path=os.path.join("temp", "monitor.jpg"))
            if img_path and os.path.isfile(img_path):
                result = recognizer.process_image(img_path)
            else:
                print("Camera failed to capture image or file not found!")
            print(result)
            time.sleep(1)
        cam.close()
    except:
        cam.close()

if __name__ == "__main__":
    main()
