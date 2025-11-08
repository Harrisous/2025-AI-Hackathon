# Quick Deploy with ngrok - 2 Minutes! ⚡

## Fastest Way to Share Your Backend

### Step 1: Start Your Backend (Terminal 1)
```bash
cd /Users/johnrohit/Documents/hackathon-alzeimer/2025-AI-Hackathon
python3 app.py
```

You should see:
```
* Running on http://127.0.0.1:5001
* Running on http://172.28.93.21:5001
```

### Step 2: Expose with ngrok (Terminal 2)
```bash
ngrok http 5001
```

You'll see something like:
```
Forwarding: https://abc123-xyz.ngrok-free.app -> http://localhost:5001
```

### Step 3: Copy the Public URL
Copy the `https://abc123-xyz.ngrok-free.app` URL

### Step 4: Test It
```bash
curl https://abc123-xyz.ngrok-free.app/health
```

Should return:
```json
{"status": "healthy", "service": "raspberry-pi-backend", ...}
```

### Step 5: Share with Your Friend

Send your friend:
1. **The ngrok URL**: `https://abc123-xyz.ngrok-free.app`
2. **Tell them to update** `simple_upload_example.py`:
   ```python
   BACKEND_URL = "https://abc123-xyz.ngrok-free.app"
   ```

### Step 6: Friend Tests
Your friend runs on Raspberry Pi:
```python
from simple_upload_example import check_backend
check_backend()  # Should print "✓ Backend is reachable!"
```

---

## That's It! 🎉

Your backend is now accessible from anywhere!

⚠️ **Note**: 
- Keep both terminals running
- ngrok URL changes when you restart
- Perfect for testing during hackathon!

---

## When You're Ready for Permanent Deployment

Use Railway or Render (see `RAILWAY_DEPLOYMENT.md`)
