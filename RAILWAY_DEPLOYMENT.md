# Deploy Backend to Railway - Step by Step

## What is Railway?
Railway is a cloud platform that lets you deploy your backend for free. Your friend can then access it from anywhere!

---

## Step-by-Step Deployment

### Step 1: Prepare Your Code ✅

**Already done!** Your code is ready with:
- ✅ `app.py` - Your backend
- ✅ `requirements.txt` - Dependencies
- ✅ `Procfile` - Tells Railway how to run your app
- ✅ `runtime.txt` - Python version

### Step 2: Push to GitHub

1. **Initialize git** (if not already done):
```bash
cd /Users/johnrohit/Documents/hackathon-alzeimer/2025-AI-Hackathon
git init
git add .
git commit -m "Backend ready for deployment"
```

2. **Create GitHub repository**:
   - Go to https://github.com/new
   - Name: `alzheimer-camera-backend`
   - Make it **Public** or **Private** (your choice)
   - Don't initialize with README (we already have files)
   - Click "Create repository"

3. **Push to GitHub**:
```bash
git remote add origin https://github.com/YOUR_USERNAME/alzheimer-camera-backend.git
git branch -M main
git push -u origin main
```

### Step 3: Deploy to Railway

1. **Go to Railway**:
   - Visit: https://railway.app
   - Click "Start a New Project"
   - Login with GitHub

2. **Deploy from GitHub**:
   - Click "Deploy from GitHub repo"
   - Select your repository: `alzheimer-camera-backend`
   - Railway will automatically detect it's a Python app

3. **Wait for deployment**:
   - Railway will install dependencies
   - Build your app
   - Deploy it
   - Takes ~2-3 minutes

4. **Get your URL**:
   - Click on your deployment
   - Go to "Settings" tab
   - Click "Generate Domain"
   - You'll get a URL like: `https://your-app-name.up.railway.app`

### Step 4: Test Your Deployment

```bash
# Test health endpoint
curl https://your-app-name.up.railway.app/health

# Should return:
# {"status": "healthy", "service": "raspberry-pi-backend", ...}
```

---

## Alternative: Deploy to Render (Easier)

If Railway doesn't work, try Render:

### Step 1: Go to Render
- Visit: https://render.com
- Sign up with GitHub

### Step 2: Create Web Service
- Click "New +" → "Web Service"
- Connect your GitHub repository
- Settings:
  - **Name**: `alzheimer-backend`
  - **Environment**: `Python 3`
  - **Build Command**: `pip install -r requirements.txt`
  - **Start Command**: `gunicorn app:app`
  - **Plan**: Free

### Step 3: Deploy
- Click "Create Web Service"
- Wait 2-3 minutes
- You'll get a URL like: `https://alzheimer-backend.onrender.com`

---

## Alternative: Use ngrok (Quickest for Testing)

If you just want to test quickly without deploying:

### Step 1: Install ngrok
```bash
# On Mac:
brew install ngrok

# Or download from: https://ngrok.com/download
```

### Step 2: Run your backend locally
```bash
python3 app.py
# Running on port 5001
```

### Step 3: Expose with ngrok
```bash
# In another terminal:
ngrok http 5001
```

### Step 4: Get public URL
```
Forwarding: https://abc123.ngrok.io -> http://localhost:5001
```

**Share this URL with your friend**: `https://abc123.ngrok.io`

⚠️ **Note**: ngrok URL changes every time you restart. Good for testing, not for production.

---

## Update Your Friend's Code

Once deployed, your friend needs to update the backend URL:

### In `simple_upload_example.py`:
```python
# OLD (local):
BACKEND_URL = "http://172.28.93.21:5001"

# NEW (Railway):
BACKEND_URL = "https://your-app-name.up.railway.app"

# NEW (Render):
BACKEND_URL = "https://alzheimer-backend.onrender.com"

# NEW (ngrok):
BACKEND_URL = "https://abc123.ngrok.io"
```

---

## Test the Deployment

### From Your Computer:
```bash
# Test health
curl https://your-app-name.up.railway.app/health

# Test upload (with a test file)
curl -X POST -F "image=@test_image.jpg" https://your-app-name.up.railway.app/upload/image
```

### From Your Friend's Raspberry Pi:
```python
from simple_upload_example import check_backend, upload_image

# Should print "✓ Backend is reachable!"
check_backend()

# Test upload
upload_image('/path/to/test.jpg')
```

---

## Troubleshooting

### Issue: "Application failed to start"
**Solution**: Check Railway logs
- Go to your Railway project
- Click "Deployments" tab
- Click on latest deployment
- Check logs for errors

### Issue: "Port already in use"
**Solution**: Railway automatically assigns port
- Make sure your `app.py` uses: `port = int(os.environ.get('PORT', 5001))`
- Already fixed in your code! ✅

### Issue: "Files not persisting"
**Solution**: Railway's filesystem is ephemeral
- For hackathon: Files will persist during the session
- For production: Need to use cloud storage (S3, Google Cloud Storage)
- Current setup works fine for testing!

### Issue: "Timeout on large files"
**Solution**: Increase timeout
- In Railway: Settings → Environment → Add variable
- `GUNICORN_TIMEOUT=300` (5 minutes)

---

## Cost

### Railway:
- **Free tier**: $5 credit/month
- **Usage**: ~$0.01/hour when active
- **Good for**: Hackathon, testing
- **Upgrade**: $5/month for more resources

### Render:
- **Free tier**: 750 hours/month
- **Limitation**: Sleeps after 15 min of inactivity
- **Good for**: Testing, demos
- **Upgrade**: $7/month for always-on

### ngrok:
- **Free tier**: Unlimited
- **Limitation**: URL changes on restart
- **Good for**: Quick testing
- **Upgrade**: $8/month for fixed URL

---

## Recommended Approach

### For Hackathon (Quick):
1. ✅ Use **ngrok** (5 minutes setup)
2. Share URL with friend
3. Start testing immediately

### For Demo Day (Reliable):
1. ✅ Deploy to **Railway** or **Render**
2. Get permanent URL
3. Share with friend
4. Works reliably for demos

### For Production (Later):
1. Deploy to Railway/Render
2. Add cloud storage (S3)
3. Add authentication
4. Add monitoring

---

## Quick Start Commands

### Option 1: ngrok (Fastest)
```bash
# Terminal 1:
python3 app.py

# Terminal 2:
ngrok http 5001

# Share the ngrok URL with your friend!
```

### Option 2: Railway (Best)
```bash
# Push to GitHub
git add .
git commit -m "Ready for deployment"
git push

# Then deploy via Railway dashboard
# Get URL and share with friend
```

---

## What to Share with Your Friend

Once deployed, send your friend:

1. **Backend URL**: `https://your-app-name.up.railway.app`
2. **Test command**:
   ```bash
   curl https://your-app-name.up.railway.app/health
   ```
3. **Updated code**: Tell them to change `BACKEND_URL` in `simple_upload_example.py`

---

## Next Steps

1. ✅ Choose deployment method (ngrok for quick test, Railway for reliable)
2. ✅ Deploy your backend
3. ✅ Get public URL
4. ✅ Test with curl
5. ✅ Share URL with friend
6. ✅ Friend updates their code
7. ✅ Test end-to-end!

**Let me know which method you want to use and I'll help you deploy!** 🚀
