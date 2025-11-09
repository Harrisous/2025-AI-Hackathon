# Caregiver Dashboard - Real Metrics Integration

## Overview

The dashboard now tracks real cognitive metrics from your deployed MemorEye APIs:

- **Memory API:** https://2025-ai-hackathon-raspberry-api-api-production-5bd5.up.railway.app
- **Image API:** https://2025-ai-hackathon-raspberry-api-api-production-bfcb.up.railway.app

## Metrics Tracked

### 1. **Learning Curve**
- Shows performance improvement over sessions
- Tracks correct answers per session
- Displays last 10 sessions

### 2. **Forgetting Curve**
- Measures memory retention over time (1h, 8h, 1d, 2d, 5d, 7d)
- Differentiates short-term vs long-term memory
- Based on actual session timestamps

### 3. **Q/A Correct Rate**
- Overall percentage of correct vs incorrect answers
- Pie chart visualization
- Calculated from all stored sessions

### 4. **Attempts to Answer**
- Distribution of how many attempts needed
- Categories: 1 attempt, 2 attempts, 3+ attempts
- Shows first-attempt success rate

### 5. **Improvement Over Time**
- Weekly progress tracking
- Shows trend over 6 weeks
- Averages scores per week

## How It Works

### Data Storage
- Sessions stored in browser `localStorage`
- Each session includes:
  - Session ID
  - Timestamp
  - Correct answers count
  - Total questions
  - Attempts per question
  - Memory type (short_term / long_term)
  - API type (text / image)

### Data Flow
```
iOS App → Railway API → Session Results → localStorage → Dashboard Metrics
```

### Memory Classification

**Long-Term Memory (Family/People):**
- Photo recognition (Image API)
- Family member names
- Relationships

**Short-Term Memory (Recent Events):**
- Yesterday's birthday (Text API)
- Who visited
- What gifts received
- What was eaten

## Setup

### 1. Install Dependencies
```bash
cd caregiver-dashboard
npm install
```

### 2. Run Dashboard
```bash
npm run dev
```

### 3. Test with Sample Data
The dashboard will show dummy data initially. To populate with real data:

1. Use the iOS app to complete sessions
2. Sessions are automatically tracked
3. Dashboard updates every 30 seconds

## API Integration

### Storing Session Results

When a session completes in your iOS app, send results to the dashboard:

```typescript
import { storeSessionResult } from './api/metrics';

// After session completes
storeSessionResult({
  sessionId: "abc123",
  timestamp: new Date().toISOString(),
  correctAnswers: 5,
  totalQuestions: 7,
  attempts: {
    "q1": 1,  // Correct on first attempt
    "q2": 2,  // Correct on second attempt
    "q3": 1,
    "q4": 3,  // Needed 3 attempts
    "q5": 1,
    "q6": 1,
    "q7": 2
  },
  memoryType: "short_term",  // or "long_term"
  apiType: "text"  // or "image"
});
```

### Testing API Connection

```typescript
import { testAPIConnection } from './api/metrics';

const status = await testAPIConnection();
console.log('Memory API:', status.memory ? '✅' : '❌');
console.log('Image API:', status.image ? '✅' : '❌');
```

## Features

✅ **Real-time Updates** - Metrics refresh every 30 seconds
✅ **Persistent Storage** - Data saved in localStorage
✅ **Memory Type Tracking** - Distinguishes short vs long-term
✅ **API Type Tracking** - Separates text vs image sessions
✅ **Weekly Aggregation** - Groups sessions by week
✅ **Forgetting Curve Analysis** - Time-based retention tracking

## Charts

### Forgetting Curve (Line Chart)
- X-axis: Time intervals (1h, 8h, 1d, 2d, 5d, 7d)
- Y-axis: Recall percentage
- Shows memory decay over time

### Learning Curve (Line Chart)
- X-axis: Session number (S1, S2, S3...)
- Y-axis: Score percentage
- Shows improvement across sessions

### Q/A Correct Rate (Pie Chart)
- Green: Correct answers
- Orange: Incorrect answers
- Overall accuracy

### Attempts to Answer (Bar Chart)
- 1 attempt (green): First-try success
- 2 attempts (orange): Needed hint
- 3+ attempts (yellow): Multiple hints

### Improvement Over Time (Line Chart)
- X-axis: Week number (W1, W2, W3...)
- Y-axis: Average score
- Long-term progress tracking

## Future Enhancements

- [ ] Export metrics to PDF
- [ ] Compare short-term vs long-term memory
- [ ] Alert caregivers on declining performance
- [ ] Sync across devices
- [ ] Backend API for multi-patient tracking

---

**Your caregiver dashboard now shows real cognitive metrics from the MemorEye APIs!** 📊🧠
