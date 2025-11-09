#!/usr/bin/env python3
"""
Flask API for Memory Trainer - Backend for iPad app
"""

import os
import uuid
from datetime import datetime
from typing import Optional
from flask import Flask, request, jsonify
from flask_cors import CORS
from memory_trainer import MemoryTrainer
from qa_database import QADatabase, QA

app = Flask(__name__)
CORS(app)  # Enable CORS for iPad app

# In-memory session storage (use Redis/DB for production)
sessions = {}

# Shared QA database instance
_qa_db = None


def get_qa_db():
    """Get shared QA database instance"""
    global _qa_db
    if _qa_db is None:
        _qa_db = QADatabase()
    return _qa_db


class APIMemoryTrainer(MemoryTrainer):
    """Extended MemoryTrainer for API usage (non-blocking)"""
    
    def __init__(self, session_id: str, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.session_id = session_id
        self.current_qa = None
        self.current_attempt = 0
        self.phase = "not_started"  # not_started, warmup, training, completed
        self.current_question_index = 0
        self.selected_questions = []
        # Use shared database
        self.db = get_qa_db()
    
    def start_warmup(self) -> dict:
        """Start warmup phase and return initial greeting"""
        self.session_data["start_time"] = datetime.now()
        self.phase = "warmup"
        
        system_prompt = """You are a friendly, empathetic memory training assistant. 
This is the WARM-UP phase only - just casual conversation, NO memory exercises or tests yet.
Keep it brief (1-2 sentences). Ask how they're feeling today.
Do NOT give memory tasks, word lists, or exercises during warm-up."""
        
        greeting = self._call_llm(system_prompt)
        if greeting:
            self._add_message("assistant", greeting)
            return {"success": True, "message": greeting, "phase": "warmup"}
        
        return {"success": False, "error": "Failed to generate greeting"}
    
    def handle_warmup_response(self, user_message: str) -> dict:
        """Handle user response during warmup"""
        self._add_message("user", user_message)
        
        transition_prompt = """Acknowledge their response briefly (1 sentence) and say you'll now start the memory questions.
Do NOT create new memory exercises - the questions are coming from the database next."""
        
        response = self._call_llm(system_prompt=transition_prompt)
        if response:
            self._add_message("assistant", response)
            return {
                "success": True,
                "message": response,
                "phase": "warmup_complete",
                "ready_for_training": True
            }
        
        return {"success": False, "error": "Failed to process response"}
    
    def start_training(self, num_questions: int = 3) -> dict:
        """Start training phase with selected questions"""
        self.phase = "training"
        self.selected_questions = self._select_questions(num_questions)
        self.current_question_index = 0
        
        if not self.selected_questions:
            return {"success": False, "error": "No questions available"}
        
        # Ask first question
        return self.get_next_question()
    
    def get_next_question(self) -> dict:
        """Get the next question in the training sequence"""
        if self.current_question_index >= len(self.selected_questions):
            self.phase = "completed"
            return {
                "success": True,
                "phase": "completed",
                "message": "All questions completed!",
                "total_questions": len(self.selected_questions)
            }
        
        self.current_qa = self.selected_questions[self.current_question_index]
        self.current_attempt = 0
        
        return {
            "success": True,
            "phase": "training",
            "question": self.current_qa.question,
            "question_number": self.current_question_index + 1,
            "total_questions": len(self.selected_questions),
            "qa_id": self.current_qa.id
        }
    
    def submit_answer(self, user_answer: str) -> dict:
        """Submit answer and get evaluation"""
        if not self.current_qa:
            return {"success": False, "error": "No active question"}
        
        evaluation = self._evaluate_answer(
            self.current_qa.question,
            self.current_qa.answer,
            user_answer,
            self.current_attempt
        )
        
        if evaluation["correct"]:
            # Record success
            self.session_data["qa_results"][self.current_qa.id] = {
                "correct": True,
                "attempts": self.current_attempt + 1
            }
            
            # Move to next question
            self.current_question_index += 1
            
            return {
                "success": True,
                "correct": True,
                "feedback": evaluation["feedback"],
                "move_to_next": True
            }
        else:
            self.current_attempt += 1
            
            if self.current_attempt >= 3:
                # Failed after 3 attempts
                self.session_data["qa_results"][self.current_qa.id] = {
                    "correct": False,
                    "attempts": self.current_attempt
                }
                
                result = {
                    "success": True,
                    "correct": False,
                    "feedback": f"The answer was: {self.current_qa.answer}",
                    "move_to_next": True,
                    "attempts_exhausted": True
                }
                
                # Move to next question
                self.current_question_index += 1
                return result
            else:
                # Give hint and allow retry
                return {
                    "success": True,
                    "correct": False,
                    "feedback": evaluation.get("feedback", "Not quite."),
                    "hint": evaluation.get("hint", "Try again."),
                    "attempt": self.current_attempt,
                    "attempts_remaining": 3 - self.current_attempt,
                    "move_to_next": False
                }
    
    def get_summary(self) -> dict:
        """Get session summary"""
        results = self.session_data["qa_results"]
        correct_count = sum(1 for r in results.values() if r["correct"])
        total_count = len(results)
        
        if total_count == 0:
            return {
                "success": True,
                "summary": "No questions were answered in this session.",
                "stats": {"correct": 0, "total": 0, "percentage": 0}
            }
        
        summary_prompt = f"""Provide an encouraging summary of the memory training session.
- Questions answered: {total_count}
- Correct answers: {correct_count}
- Success rate: {correct_count/total_count*100:.0f}%

Be positive, highlight achievements, and provide gentle encouragement. Keep it brief (2-3 sentences)."""
        
        summary = self._call_llm(system_prompt=summary_prompt)
        
        # Update database
        self._update_database()
        
        duration = (datetime.now() - self.session_data["start_time"]).seconds
        
        return {
            "success": True,
            "summary": summary or "Great job completing the session!",
            "stats": {
                "correct": correct_count,
                "total": total_count,
                "percentage": round(correct_count/total_count*100, 1)
            },
            "duration_seconds": duration
        }


# =============================================================================
# API Endpoints
# =============================================================================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})


@app.route('/api/session/start', methods=['POST'])
def start_session():
    """Start a new training session"""
    try:
        data = request.json or {}
        session_id = str(uuid.uuid4())
        
        # Get API key from request or environment
        api_key = data.get('api_key') or os.getenv("OPENAI_API_KEY")
        model = data.get('model', 'gpt-5-mini-2025-08-07')
        
        trainer = APIMemoryTrainer(
            session_id=session_id,
            api_key=api_key,
            model=model
        )
        
        # Start warmup phase
        result = trainer.start_warmup()
        
        if result["success"]:
            sessions[session_id] = trainer
            result["session_id"] = session_id
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/warmup', methods=['POST'])
def warmup_response(session_id):
    """Send user message during warmup phase"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        data = request.json
        user_message = data.get('message', '')
        
        if not user_message:
            return jsonify({"success": False, "error": "Message is required"}), 400
        
        result = trainer.handle_warmup_response(user_message)
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/training/start', methods=['POST'])
def start_training(session_id):
    """Start training phase with questions"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        data = request.json or {}
        num_questions = data.get('num_questions', 3)
        
        result = trainer.start_training(num_questions)
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/answer', methods=['POST'])
def submit_answer(session_id):
    """Submit answer to current question"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        data = request.json
        user_answer = data.get('answer', '')
        
        if not user_answer:
            return jsonify({"success": False, "error": "Answer is required"}), 400
        
        result = trainer.submit_answer(user_answer)
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/next', methods=['POST'])
def next_question(session_id):
    """Get next question in training"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        result = trainer.get_next_question()
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/summary', methods=['GET'])
def get_summary(session_id):
    """Get session summary and stats"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        result = trainer.get_summary()
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/end', methods=['POST'])
def end_session(session_id):
    """End session and clean up"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        result = trainer.get_summary()
        
        # Clean up session
        del sessions[session_id]
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/session/<session_id>/status', methods=['GET'])
def get_status(session_id):
    """Get current session status"""
    try:
        trainer = sessions.get(session_id)
        if not trainer:
            return jsonify({"success": False, "error": "Session not found"}), 404
        
        return jsonify({
            "success": True,
            "session_id": session_id,
            "phase": trainer.phase,
            "current_question_index": trainer.current_question_index,
            "total_questions": len(trainer.selected_questions),
            "results": trainer.session_data["qa_results"]
        }), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


# =============================================================================
# QA Database Management Endpoints
# =============================================================================

@app.route('/api/qa', methods=['GET'])
def get_all_qas():
    """Get all Q&A pairs"""
    try:
        db = get_qa_db()
        qas = db.get_all_qas()
        
        qa_list = [
            {
                "id": qa.id,
                "question": qa.question,
                "answer": qa.answer,
                "practice_times": qa.practice_times,
                "success_rate": qa.success_rate,
                "last_use_time": qa.last_use_time.isoformat(),
                "creation_time": qa.creation_time.isoformat()
            }
            for qa in qas
        ]
        
        return jsonify({"success": True, "data": qa_list}), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/qa/<qa_id>', methods=['GET'])
def get_qa(qa_id):
    """Get specific Q&A by ID"""
    try:
        db = get_qa_db()
        qa = db.get_qa(qa_id)
        
        if not qa:
            return jsonify({"success": False, "error": "QA not found"}), 404
        
        return jsonify({
            "success": True,
            "data": {
                "id": qa.id,
                "question": qa.question,
                "answer": qa.answer,
                "practice_times": qa.practice_times,
                "success_rate": qa.success_rate,
                "last_use_time": qa.last_use_time.isoformat(),
                "creation_time": qa.creation_time.isoformat()
            }
        }), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/qa', methods=['POST'])
def create_qa():
    """Create new Q&A pair"""
    try:
        data = request.json
        question = data.get('question', '').strip()
        answer = data.get('answer', '').strip()
        
        if not question or not answer:
            return jsonify({
                "success": False,
                "error": "Question and answer are required"
            }), 400
        
        db = get_qa_db()
        qa_id = str(uuid.uuid4())
        now = datetime.now()
        
        qa = QA(
            id=qa_id,
            question=question,
            answer=answer,
            creation_time=now,
            practice_times=0,
            success_rate=0.0,
            last_use_time=now
        )
        
        db.add_qa(qa)
        
        return jsonify({
            "success": True,
            "data": {
                "id": qa.id,
                "question": qa.question,
                "answer": qa.answer
            }
        }), 201
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/qa/<qa_id>', methods=['PUT'])
def update_qa(qa_id):
    """Update existing Q&A pair"""
    try:
        db = get_qa_db()
        qa = db.get_qa(qa_id)
        
        if not qa:
            return jsonify({"success": False, "error": "QA not found"}), 404
        
        data = request.json
        
        if 'question' in data:
            qa.question = data['question'].strip()
        if 'answer' in data:
            qa.answer = data['answer'].strip()
        
        db.update_qa(qa_id, qa)
        
        return jsonify({
            "success": True,
            "data": {
                "id": qa.id,
                "question": qa.question,
                "answer": qa.answer
            }
        }), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/api/qa/<qa_id>', methods=['DELETE'])
def delete_qa(qa_id):
    """Delete Q&A pair"""
    try:
        db = get_qa_db()
        qa = db.get_qa(qa_id)
        
        if not qa:
            return jsonify({"success": False, "error": "QA not found"}), 404
        
        db.delete_qa(qa_id)
        
        return jsonify({"success": True, "message": "QA deleted"}), 200
        
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


if __name__ == '__main__':
    # Development server
    app.run(host='0.0.0.0', port=8000, debug=True)

