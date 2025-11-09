# Deploy Image Memory Chat to Railway

## Quick Deploy Steps

### 1. Go to Railway
https://railway.app

### 2. New Project
- Click "New Project"
- Select "Deploy from GitHub repo"
- Choose: `johnjoel2001/2025-AI-Hackathon-raspberry-api-api`
- Branch: `john/image-RAG`

### 3. Configure Service
- **Root Directory:** `rag_agent`
- **Start Command:** `python image_chat_ui.py`
- **Build Command:** `pip install -r requirements.txt`

### 4. Environment Variables
Add these in Railway dashboard:
```
OPENAI_API_KEY=sk-proj-...
SUPABASE_URL=https://aidxatmnfpmhxxpkmnny.supabase.co
SUPABASE_KEY=eyJ...
PORT=5005
```

### 5. Deploy!
Railway will auto-deploy and give you a URL like:
```
https://image-chat-production.up.railway.app
```

---

## Alternative: Use Existing Text Chat Deployment

If you already deployed the text chat (memerai_ui.py), you can:

1. **Keep both running** - Deploy image chat as separate service
2. **Use different ports** - Text on 5004, Image on 5005
3. **Share environment variables** - Same Supabase/OpenAI keys

---

## Testing After Deploy

```bash
# Test start endpoint
curl -X POST https://your-app.up.railway.app/api/start \
  -H "Content-Type: application/json"

# Should return:
{
  "success": true,
  "session_id": "...",
  "greeting": "Good morning John! 🌅",
  "image_url": "https://...",
  "question": "Do you remember who this person is?",
  "total_questions": 2
}
```

---

## Files Needed for Deployment

✅ `image_chat_ui.py` - Main Flask app
✅ `image_memory_chat.py` - Core logic
✅ `family_context.py` - Family data
✅ `requirements.txt` - Dependencies
✅ `templates/image_chat.html` - UI
✅ `runtime.txt` - Python version

All files are already in the `rag_agent` folder!

---

## Troubleshooting

### If deployment fails:
1. Check Railway logs
2. Verify environment variables are set
3. Make sure Supabase has images with `detected_persons`
4. Test locally first: `python image_chat_ui.py`

### Common issues:
- **No photos found** → Check Supabase `images` table has data
- **Template not found** → Make sure `templates/` folder is included
- **Import errors** → Check all dependencies in `requirements.txt`

---

## What Gets Deployed

The Image Memory Chat API with:
- Photo-based person recognition
- Progressive hints
- Supabase integration
- Beautiful web UI
- REST API for iOS/mobile apps

**Your iOS friend can then use the Railway URL instead of ngrok!** 🚀
