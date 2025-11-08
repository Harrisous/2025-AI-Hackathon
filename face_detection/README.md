# Face Detection and Recognition on Raspberry Pi

Minimal implementation using MediaPipe Face Detector and MobileFaceNet embeddings.

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Download MediaPipe Face Detector model:**
```bash
wget https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/1/blaze_face_short_range.tflite -O detector.tflite
```

3. **Download MobileFaceNet ONNX model:**

```bash
# From a public repository (example)
wget https://github.com/onnx/models/raw/main/validated/vision/body_analysis/arcface/model/arcfaceresnet100-8.onnx -O mobilefacenet.onnx
```

Option B - Convert from PyTorch (if you have a .pth file):
```python
# See conversion script in docs
```
