#!/bin/bash
# Quick start script for Memory Trainer API

echo "🧠 Starting Memory Trainer API Server..."
echo ""

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  Warning: OPENAI_API_KEY environment variable not set"
    echo "   Set it with: export OPENAI_API_KEY='your-key-here'"
    echo ""
fi

# Install dependencies if needed
if ! python -c "import flask" 2>/dev/null; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
    echo ""
fi

# Run the API server
echo "🚀 Server starting on http://localhost:8000"
echo "   Press Ctrl+C to stop"
echo ""
python api.py

