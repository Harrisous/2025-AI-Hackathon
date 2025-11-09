from picamera2 import Picamera2
from datetime import datetime
import os

class Camera:
    def __init__(self):
        """
        Initialize Picamera2 Camera object.
        """
        self.picam2 = None

    def open(self):
        """
        Initialize and start the Picamera2 device.
        """
        self.picam2 = Picamera2()
        self.picam2.start()

    def close(self):
        """
        Stop the Picamera2 device.
        """
        if self.picam2 is not None:
            self.picam2.stop()
            self.picam2 = None

    def capture_frame(self, save_path=None):
        """
        Capture a single frame from the camera and save it locally.
        """
        if self.picam2 is None:
            self.open()
        formatted_time = datetime.now().strftime("%Y-%m-%d+%H-%M-%S")
        if not save_path:
            save_path = os.path.join("temp", f"pic_{formatted_time}.jpg")
        self.picam2.capture_file(save_path)
        return save_path
