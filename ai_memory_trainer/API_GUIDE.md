# Memory Trainer API Documentation

Flask REST API for the Memory Trainer app. Designed for use with iPad chatbot UI.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Set OpenAI API key
export OPENAI_API_KEY="your-key-here"

# Run server
python api.py
```

Server runs on `http://localhost:5000`

## Session Flow

1. **Start Session** → Get warmup greeting
2. **Send Warmup Response** → Get transition message
3. **Start Training** → Receive first question
4. **Submit Answer** → Get feedback/hint
5. **Next Question** (if move_to_next=true) → Get next question
6. Repeat 4-5 until completed
7. **Get Summary** → Session stats and encouragement

## API Endpoints

### Session Management

#### `POST /api/session/start`
Start new training session and get warmup greeting.

**Request:**
```json
{
  "api_key": "optional-if-env-set",
  "model": "gpt-5-mini-2025-08-07"
}
```

**Response:**
```json
{
  "success": true,
  "session_id": "uuid",
  "message": "Hi! How are you feeling today?",
  "phase": "warmup"
}
```

#### `POST /api/session/{session_id}/warmup`
Send user response during warmup phase.

**Request:**
```json
{
  "message": "I'm feeling good today!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Great! Let's start with some memory questions.",
  "phase": "warmup_complete",
  "ready_for_training": true
}
```

#### `POST /api/session/{session_id}/training/start`
Start the training phase with questions.

**Request:**
```json
{
  "num_questions": 3
}
```

**Response:**
```json
{
  "success": true,
  "phase": "training",
  "question": "Who was having lunch with you yesterday?",
  "question_number": 1,
  "total_questions": 3,
  "qa_id": "1"
}
```

#### `POST /api/session/{session_id}/answer`
Submit answer to current question.

**Request:**
```json
{
  "answer": "My daughter"
}
```

**Response (Correct):**
```json
{
  "success": true,
  "correct": true,
  "feedback": "Excellent! That's right.",
  "move_to_next": true
}
```

**Response (Incorrect - with retries left):**
```json
{
  "success": true,
  "correct": false,
  "feedback": "Not quite.",
  "hint": "Think about who you spent time with.",
  "attempt": 1,
  "attempts_remaining": 2,
  "move_to_next": false
}
```

**Response (Incorrect - no retries left):**
```json
{
  "success": true,
  "correct": false,
  "feedback": "The answer was: My daughter",
  "move_to_next": true,
  "attempts_exhausted": true
}
```

#### `POST /api/session/{session_id}/next`
Get the next question (call after `move_to_next: true`).

**Response:**
```json
{
  "success": true,
  "phase": "training",
  "question": "Where were you having lunch yesterday?",
  "question_number": 2,
  "total_questions": 3,
  "qa_id": "2"
}
```

**Response (All completed):**
```json
{
  "success": true,
  "phase": "completed",
  "message": "All questions completed!",
  "total_questions": 3
}
```

#### `GET /api/session/{session_id}/summary`
Get session summary and stats.

**Response:**
```json
{
  "success": true,
  "summary": "Great work! You answered 2 out of 3 questions correctly...",
  "stats": {
    "correct": 2,
    "total": 3,
    "percentage": 66.7
  },
  "duration_seconds": 180
}
```

#### `POST /api/session/{session_id}/end`
End session, get summary, and cleanup.

**Response:** Same as `/summary`

#### `GET /api/session/{session_id}/status`
Get current session status.

**Response:**
```json
{
  "success": true,
  "session_id": "uuid",
  "phase": "training",
  "current_question_index": 1,
  "total_questions": 3,
  "results": {
    "1": {"correct": true, "attempts": 1}
  }
}
```

### Q&A Database Management

#### `GET /api/qa`
Get all Q&A pairs.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "question": "Who was having lunch with you yesterday?",
      "answer": "My daughter",
      "practice_times": 5,
      "success_rate": 0.8,
      "last_use_time": "2025-11-09T10:30:00",
      "creation_time": "2025-11-01T10:00:00"
    }
  ]
}
```

#### `GET /api/qa/{qa_id}`
Get specific Q&A by ID.

#### `POST /api/qa`
Create new Q&A pair.

**Request:**
```json
{
  "question": "What did you have for breakfast?",
  "answer": "Oatmeal with berries"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "generated-uuid",
    "question": "What did you have for breakfast?",
    "answer": "Oatmeal with berries"
  }
}
```

#### `PUT /api/qa/{qa_id}`
Update existing Q&A.

**Request:**
```json
{
  "question": "Updated question",
  "answer": "Updated answer"
}
```

#### `DELETE /api/qa/{qa_id}`
Delete Q&A pair.

### Health Check

#### `GET /api/health`
Check API status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-11-09T10:30:00"
}
```

## Example iPad App Flow

```javascript
// 1. Start session
const startRes = await fetch('http://localhost:5000/api/session/start', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' }
});
const { session_id, message } = await startRes.json();

// Display message in chat UI
displayMessage('assistant', message);

// 2. User responds to warmup
const warmupRes = await fetch(`http://localhost:5000/api/session/${session_id}/warmup`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ message: userInput })
});
const warmupData = await warmupRes.json();
displayMessage('assistant', warmupData.message);

// 3. Start training
const trainingRes = await fetch(`http://localhost:5000/api/session/${session_id}/training/start`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ num_questions: 3 })
});
const { question } = await trainingRes.json();
displayMessage('assistant', question);

// 4. Submit answer
const answerRes = await fetch(`http://localhost:5000/api/session/${session_id}/answer`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ answer: userAnswer })
});
const answerData = await answerRes.json();

if (answerData.correct) {
  displayMessage('assistant', answerData.feedback);
  // Get next question
  if (answerData.move_to_next) {
    const nextRes = await fetch(`http://localhost:5000/api/session/${session_id}/next`, {
      method: 'POST'
    });
    const nextData = await nextRes.json();
    
    if (nextData.phase === 'completed') {
      // Show summary
      const summaryRes = await fetch(`http://localhost:5000/api/session/${session_id}/summary`);
      const summary = await summaryRes.json();
      displayMessage('assistant', summary.summary);
    } else {
      displayMessage('assistant', nextData.question);
    }
  }
} else {
  // Show hint and allow retry
  displayMessage('assistant', answerData.hint);
}
```

## Error Handling

All endpoints return consistent error format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad request (missing/invalid data)
- `404` - Not found (session/QA doesn't exist)
- `500` - Server error

## Swift/iOS Example

```swift
// Start session
let url = URL(string: "http://localhost:5000/api/session/start")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data else { return }
    
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let sessionId = json["session_id"] as? String,
       let message = json["message"] as? String {
        // Display message in chat UI
        DispatchQueue.main.async {
            self.addMessage(role: "assistant", text: message)
            self.sessionId = sessionId
        }
    }
}
task.resume()
```

## Notes

- Sessions are stored in-memory. Use Redis or database for production.
- CORS is enabled for all origins (configure for production).
- OpenAI API key required (env variable or per-request).
- Default model: `gpt-5-mini-2025-08-07`
- QA database is shared across all sessions
- For production, add authentication/authorization middleware

