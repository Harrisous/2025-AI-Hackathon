# api.py
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


# memory_trainer.py
#!/usr/bin/env python3
"""
Memory Trainer - AI agent for memory training sessions
"""

import os
import time
import threading
from datetime import datetime
from typing import Optional
from openai import OpenAI
from qa_database import QADatabase, QA


class MemoryTrainer:
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-5-mini-2025-08-07"):
        self.client = OpenAI(api_key=api_key or os.getenv("OPENAI_API_KEY"))
        self.model = model
        self.db = QADatabase()
        self.conversation_history = []
        self.session_data = {
            "start_time": None,
            "qa_results": {},  # id -> {correct: bool, attempts: int}
        }
    
    def _add_message(self, role: str, content: str):
        """Add message to conversation history"""
        self.conversation_history.append({"role": role, "content": content})
    
    def _call_llm(self, system_prompt: str = None) -> Optional[str]:
        """Call LLM with current conversation state"""
        messages = []
        
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        messages.extend(self.conversation_history)
        
        try:
            # GPT-5 only supports default temperature (1)
            response = self.client.chat.completions.create(
                model=self.model,
                messages=messages,
            )
            return response.choices[0].message.content
        except Exception as e:
            print(f"Error calling LLM: {e}")
            return None
    
    def _get_user_input(self, prompt: str, timeout: int = 60, max_retries: int = 3) -> Optional[str]:
        """Get user input with timeout and retry logic"""
        for attempt in range(max_retries):
            print(f"\n{prompt}")
            
            # Use threading for cross-platform timeout
            user_input = [None]
            
            def get_input():
                try:
                    user_input[0] = input("> ").strip()
                except:
                    pass
            
            input_thread = threading.Thread(target=get_input, daemon=True)
            input_thread.start()
            input_thread.join(timeout=timeout)
            
            if input_thread.is_alive():
                print(f"\n⏱ Timeout ({timeout}s). Please try again.")
                continue
            
            if user_input[0]:
                return user_input[0]
            
            print("No response received. Please try again.")
        
        print(f"No response after {max_retries} attempts.")
        return None
    
    def _select_questions(self, k: int = 3) -> list[QA]:
        """Select top k questions by last use time (ascending)"""
        all_qas = self.db.get_all_qas()
        sorted_qas = sorted(all_qas, key=lambda qa: qa.last_use_time)
        return sorted_qas[:k]
    
    def _warm_up(self, max_duration: int = 300) -> bool:
        """Warm up phase (brief casual conversation)"""
        print("\n" + "="*50)
        print("MEMORY TRAINING SESSION - WARM UP")
        print("="*50)
        print(f"⏱ Time limit: {max_duration}s")
        
        start_time = time.time()
        
        system_prompt = """You are a friendly, empathetic memory training assistant. 
This is the WARM-UP phase only - just casual conversation, NO memory exercises or tests yet.
Keep it brief (1-2 sentences). Ask how they're feeling today.
Do NOT give memory tasks, word lists, or exercises during warm-up."""
        
        # LLM initiates warm up
        greeting = self._call_llm(system_prompt)
        if not greeting:
            return False
        
        self._add_message("assistant", greeting)
        print(f"\nA: {greeting}")
        
        # Check time limit
        elapsed = time.time() - start_time
        if elapsed >= max_duration:
            print(f"\n⏱ Warm-up time limit reached ({max_duration}s)")
            return True
        
        # Get user response with timeout
        remaining_time = int(max_duration - elapsed)
        user_response = self._get_user_input("You:", timeout=min(60, remaining_time), max_retries=3)
        if not user_response:
            return False
        
        self._add_message("user", user_response)
        
        # Check time limit again
        elapsed = time.time() - start_time
        if elapsed >= max_duration:
            print(f"\n⏱ Warm-up time limit reached ({max_duration}s)")
            return True
        
        # Brief acknowledgment to transition to training
        transition_prompt = """Acknowledge their response briefly (1 sentence) and say you'll now start the memory questions.
Do NOT create new memory exercises - the questions are coming from the database next."""
        
        followup = self._call_llm(system_prompt=transition_prompt)
        if not followup:
            return False
        
        self._add_message("assistant", followup)
        print(f"\nA: {followup}")
        
        elapsed = time.time() - start_time
        print(f"\n⏱ Warm-up completed in {elapsed:.0f}s")
        
        return True
    
    def _evaluate_answer(self, question: str, expected_answer: str, user_answer: str, attempt: int) -> dict:
        """Evaluate user's answer using LLM"""
        hint_instruction = ""
        if attempt == 0:
            hint_instruction = "Provide a very subtle hint - ask a guiding question or mention context WITHOUT revealing the answer."
        elif attempt == 1:
            hint_instruction = "Provide a slightly more specific hint - give category/context but still DO NOT reveal the answer directly."
        
        eval_prompt = f"""Evaluate if the user's answer is correct.

Question: {question}
Expected answer: {expected_answer}
User's answer: {user_answer}

IMPORTANT: When providing hints, NEVER give away the answer directly. Guide them with questions or context clues only.
{hint_instruction}

Examples of GOOD hints: "Think about who you spent time with", "What family member?", "Who do you usually meet for lunch?"
Examples of BAD hints (DO NOT USE): "Your daughter", "It was your daughter", "The answer is..."

Respond with ONLY a JSON object:
{{"correct": true/false, "feedback": "brief feedback", "hint": "hint if incorrect or empty string"}}"""
        
        response = self._call_llm(system_prompt=eval_prompt)
        if not response:
            return {"correct": False, "feedback": "Unable to evaluate", "hint": ""}
        
        # Parse JSON response
        try:
            import json
            # Extract JSON from response (handle markdown code blocks)
            response = response.strip()
            if response.startswith("```"):
                lines = response.split("\n")
                response = "\n".join(lines[1:-1])
            return json.loads(response)
        except:
            return {"correct": False, "feedback": "Unable to evaluate", "hint": ""}
    
    def _ask_question(self, qa: QA, timeout_per_attempt: int = 60) -> bool:
        """Ask a question and handle response with retries"""
        print(f"\n{'-'*50}")
        print(f"A: {qa.question}")
        
        max_attempts = 3
        
        for attempt in range(max_attempts):
            user_answer = self._get_user_input("Your answer:", timeout=timeout_per_attempt, max_retries=2)
            if not user_answer:
                self.session_data["qa_results"][qa.id] = {"correct": False, "attempts": attempt + 1}
                return False
            
            # Evaluate answer
            evaluation = self._evaluate_answer(qa.question, qa.answer, user_answer, attempt)
            
            if evaluation["correct"]:
                print(f"\nA: ✓ Correct! {evaluation['feedback']}")
                self.session_data["qa_results"][qa.id] = {"correct": True, "attempts": attempt + 1}
                return True
            else:
                if attempt < max_attempts - 1:
                    hint = evaluation.get("hint", "Think about it again.")
                    print(f"\nA: Not quite. {hint}")
                else:
                    print(f"\nA: The answer was: {qa.answer}")
                    self.session_data["qa_results"][qa.id] = {"correct": False, "attempts": attempt + 1}
        
        return False
    
    def _summarize_session(self):
        """Summarize session and reinforce positives"""
        print("\n" + "="*50)
        print("SESSION SUMMARY")
        print("="*50)
        
        results = self.session_data["qa_results"]
        correct_count = sum(1 for r in results.values() if r["correct"])
        total_count = len(results)
        
        summary_prompt = f"""Provide an encouraging summary of the memory training session.
- Questions answered: {total_count}
- Correct answers: {correct_count}
- Success rate: {correct_count/total_count*100:.0f}%

Be positive, highlight achievements, and provide gentle encouragement. Keep it brief (2-3 sentences)."""
        
        summary = self._call_llm(system_prompt=summary_prompt)
        if summary:
            print(f"\nA: {summary}")
        
        print(f"\n📊 Stats: {correct_count}/{total_count} correct ({correct_count/total_count*100:.0f}%)")
    
    def _update_database(self):
        """Update QA database with session results"""
        now = datetime.now()
        
        for qa_id, result in self.session_data["qa_results"].items():
            qa = self.db.get_qa(qa_id)
            if qa:
                qa.practice_times += 1
                qa.last_use_time = now
                
                # Update success rate
                old_total = qa.success_rate * (qa.practice_times - 1)
                new_success = 1.0 if result["correct"] else 0.0
                qa.success_rate = (old_total + new_success) / qa.practice_times
                
                self.db.update_qa(qa_id, qa)
        
        print(f"\n✓ Database updated ({len(self.session_data['qa_results'])} QAs)")
    
    def _save_session_log(self):
        """Save conversation history to file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = f"session_log_{timestamp}.txt"
        
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write(f"Memory Training Session - {timestamp}\n")
            f.write("="*50 + "\n\n")
            
            for msg in self.conversation_history:
                f.write(f"{msg['role'].upper()}: {msg['content']}\n\n")
            
            f.write("\n" + "="*50 + "\n")
            f.write("SESSION RESULTS\n")
            f.write("="*50 + "\n")
            
            for qa_id, result in self.session_data["qa_results"].items():
                qa = self.db.get_qa(qa_id)
                status = "✓" if result["correct"] else "✗"
                f.write(f"{status} {qa.question} (attempts: {result['attempts']})\n")
        
        print(f"✓ Session log saved: {log_file}")
    
    def run_session(self, num_questions: int = 3, warmup_timeout: int = 300, 
                   question_timeout: int = 60, max_session_duration: int = 1800):
        """Run complete training session with timeouts"""
        self.session_data["start_time"] = datetime.now()
        start_time = time.time()
        
        print("\n🧠 Memory Training Session Starting...")
        print(f"⏱ Maximum session duration: {max_session_duration // 60}m")
        
        # Phase 1: Warm up
        if not self._warm_up(max_duration=warmup_timeout):
            print("\n✗ Session ended during warm-up")
            return
        
        # Check overall time limit
        elapsed = time.time() - start_time
        if elapsed >= max_session_duration:
            print(f"\n⏱ Session time limit reached ({max_session_duration}s)")
            self._finalize_session()
            return
        
        # Phase 2: Select questions
        questions = self._select_questions(num_questions)
        print(f"\n\n{'='*50}")
        print(f"TRAINING PHASE - {len(questions)} QUESTIONS")
        print("="*50)
        print(f"⏱ Time per question: {question_timeout}s per attempt")
        
        # Phase 3: Ask questions
        for i, qa in enumerate(questions, 1):
            # Check overall time limit
            elapsed = time.time() - start_time
            if elapsed >= max_session_duration:
                print(f"\n⏱ Session time limit reached ({max_session_duration}s)")
                break
            
            print(f"\n[Question {i}/{len(questions)}]")
            self._ask_question(qa, timeout_per_attempt=question_timeout)
        
        # Phase 4: Finalize session
        self._finalize_session()
    
    def _finalize_session(self):
        """Finalize session with summary, database update, and logging"""
        # Summarize
        self._summarize_session()
        
        # Update database and save logs
        self._update_database()
        self._save_session_log()
        
        duration = (datetime.now() - self.session_data["start_time"]).seconds
        print(f"\n✓ Session completed in {duration // 60}m {duration % 60}s")


def main():
    import os
    os.environ["OPENAI_API_KEY"] = "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"
    
    import argparse
    
    parser = argparse.ArgumentParser(description='AI Memory Training Session')
    parser.add_argument('--num-questions', type=int, default=3, help='Number of questions to ask')
    parser.add_argument('--model', default='gpt-5-mini-2025-08-07', help='OpenAI model to use')
    parser.add_argument('--warmup-timeout', type=int, default=300, help='Warm-up phase timeout in seconds (default: 300s/5min)')
    parser.add_argument('--question-timeout', type=int, default=60, help='Timeout per question attempt in seconds (default: 60s)')
    parser.add_argument('--max-session', type=int, default=1800, help='Maximum session duration in seconds (default: 1800s/30min)')
    
    args = parser.parse_args()
    
    trainer = MemoryTrainer(model=args.model)
    
    try:
        trainer.run_session(
            num_questions=args.num_questions,
            warmup_timeout=args.warmup_timeout,
            question_timeout=args.question_timeout,
            max_session_duration=args.max_session
        )
    except KeyboardInterrupt:
        print("\n\n✗ Session interrupted by user")
    except Exception as e:
        print(f"\n✗ Error: {e}")


if __name__ == "__main__":
    main()


# qa_database.py
from datetime import datetime
from dataclasses import dataclass


@dataclass
class QA:
    id: str
    question: str
    answer: str
    creation_time: datetime
    practice_times: int
    success_rate: float
    last_use_time: datetime


class QADatabase:
    def __init__(self):
        self._db = {}
        self._init_test_data()
    
    def _init_test_data(self):
        now = datetime.now()
        test_qas = [
            QA("1", "Who was having lunch with you yesterday?", "My daughter", now, 0, 0.0, now),
            QA("2", "Where were you having lunch yesterday?", "At the Italian restaurant downtown", now, 0, 0.0, now),
            QA("3", "What did you talk about with your daughter yesterday?", "Her new job promotion", now, 0, 0.0, now)
        ]
        for qa in test_qas:
            self._db[qa.id] = qa
    
    def add_qa(self, qa: QA):
        self._db[qa.id] = qa
    
    def get_qa(self, id: str) -> QA:
        return self._db.get(id)
    
    def get_all_qas(self) -> list[QA]:
        return list(self._db.values())
    
    def update_qa(self, id: str, qa: QA):
        self._db[id] = qa
    
    def delete_qa(self, id: str):
        self._db.pop(id, None)

---

memory_trainer.py is the python script that runs the memory training session. But I want it to be the backend for the iPad app. So we implement the flask api @api.py. This app already has a clean chatbot UI, the server is http://10.197.154.239:8000, let's use the server as the backend for the iPad app to implement the same memory training session. 
