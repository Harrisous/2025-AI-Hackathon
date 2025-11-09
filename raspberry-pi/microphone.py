import sounddevice as sd        # To record audio from microphone
from scipy.io.wavfile import write  # To save audio as WAV file
import asyncio                  # To handle asynchronous tasks
import time
import numpy as np
import os
import threading
from datetime import datetime

class Microphone:
    def __init__(self, samplerate=44100, channels=1):
        """
        Initialize the Microphone object.

        Parameters:
        samplerate (int): Audio sample rate in Hz (default: 44100)
        channels (int): Number of audio channels (default: 1 for mono)
        """
        self.samplerate = samplerate
        self.channels = channels
        self.is_recording = False
        self.frames = []
        self.thread = None

    def start_recording(self):
        """
        Start recording audio in a separate thread.
        This method resets previous audio frames.
        """
        self.is_recording = True
        self.frames = []
        self.thread = threading.Thread(target=self._record)
        self.thread.start()

    def stop_recording(self, save_path=None):
        """
        Stop the recording process and save the recorded audio to a file.

        Parameters:
        save_path (str): File path for saving the recorded audio (default: 'recorded_audio.wav')
        """
        self.is_recording = False
        if self.thread:
            self.thread.join()
        if self.frames:
            audio = np.concatenate(self.frames, axis=0)
            if not save_path:
                formatted_time = datetime.now().strftime("%Y-%m-%d+%H-%M-%S")
                save_path = os.path.join("temp", f"audio_{formatted_time}.wav")
            write(save_path, self.samplerate, audio)
        return save_path

    def _record(self):
        """
        Internal method running in a separate thread to capture audio frames.
        """
        def callback(indata, frames, time, status):
            if self.is_recording:
                self.frames.append(indata.copy())
        with sd.InputStream(samplerate=self.samplerate,
                            channels=self.channels,
                            callback=callback):
            while self.is_recording:
                sd.sleep(100)