
import React, { useState, useEffect, useRef } from 'react';
import { Screen, RecallMessage } from '../types';
import { GoogleGenAI } from '@google/genai';

const ArrowLeftIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
    </svg>
);

const SendIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
        <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path>
    </svg>
);

const MemoryRecallScreen: React.FC<{ navigateTo: (screen: Screen) => void }> = ({ navigateTo }) => {
  const [messages, setMessages] = useState<RecallMessage[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(scrollToBottom, [messages]);
  
  useEffect(() => {
    // Initial message from the agent
    setMessages([
        { id: 1, text: "Hello John. Let's talk about your day yesterday. What was the first thing you did in the morning?", sender: 'agent' }
    ]);
  }, []);

  const handleSend = async () => {
    if (input.trim() === '' || isLoading) return;

    const userMessage: RecallMessage = { id: Date.now(), text: input, sender: 'user' };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      // This is a placeholder for Gemini API call.
      // In a real app, you would manage chat history and send it to the model.
      const ai = new GoogleGenAI({ apiKey: process.env.API_KEY as string });
      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: `You are a memory coach for an Alzheimer's patient named John. Be gentle, patient, and encouraging. Ask one simple question at a time to help him recall his day. The user just said: "${input}". Your previous question was: "${messages[messages.length-1].text}". Now, ask the next question or give a gentle prompt.`,
        config: {
          temperature: 0.5,
        }
      });

      const agentResponse: RecallMessage = {
        id: Date.now() + 1,
        text: response.text,
        sender: 'agent',
      };
      setMessages(prev => [...prev, agentResponse]);
    } catch (error) {
      console.error("Error calling Gemini API:", error);
      const errorMessage: RecallMessage = {
        id: Date.now() + 1,
        text: "I'm having a little trouble remembering right now. Let's try again in a moment.",
        sender: 'agent',
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full bg-white text-[#362E2B]">
      <header className="flex items-center p-4 border-b border-gray-200 bg-[#F8F5F2]">
        <button onClick={() => navigateTo(Screen.HOME)} className="p-2 rounded-full hover:bg-gray-200">
          <ArrowLeftIcon />
        </button>
        <div className="ml-4">
          <h1 className="font-bold text-lg">Memory Recall</h1>
          <p className="text-sm text-green-600">Agent is active</p>
        </div>
      </header>
      
      <div className="flex-grow p-6 overflow-y-auto bg-gray-50">
        <div className="space-y-4">
          {messages.map((msg) => (
            <div key={msg.id} className={`flex items-end gap-2 ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}>
              {msg.sender === 'agent' && <div className="w-8 h-8 rounded-full bg-[#A7D2D3] flex-shrink-0"></div>}
              <div
                className={`max-w-xs md:max-w-md lg:max-w-lg px-4 py-3 rounded-2xl ${
                  msg.sender === 'user' 
                  ? 'bg-[#E5B8A2] text-white rounded-br-none' 
                  : 'bg-white text-gray-800 rounded-bl-none border border-gray-200'
                }`}
              >
                <p>{msg.text}</p>
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex items-end gap-2 justify-start">
               <div className="w-8 h-8 rounded-full bg-[#A7D2D3] flex-shrink-0"></div>
                <div className="max-w-xs md:max-w-md lg:max-w-lg px-4 py-3 rounded-2xl bg-white text-gray-800 rounded-bl-none border border-gray-200">
                    <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-pulse"></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-pulse delay-150"></div>
                        <div className="w-2 h-2 bg-gray-400 rounded-full animate-pulse delay-300"></div>
                    </div>
                </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>
      </div>

      <div className="p-4 bg-[#F8F5F2] border-t border-gray-200">
        <div className="flex items-center gap-4">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Type your memory..."
            className="flex-grow w-full px-4 py-3 bg-white border border-gray-300 rounded-full focus:outline-none focus:ring-2 focus:ring-[#A7D2D3]"
            disabled={isLoading}
          />
          <button
            onClick={handleSend}
            disabled={isLoading || input.trim() === ''}
            className="bg-[#A7D2D3] text-white p-3 rounded-full disabled:bg-gray-300 disabled:cursor-not-allowed hover:bg-opacity-90 transition-all"
          >
            <SendIcon />
          </button>
        </div>
      </div>
    </div>
  );
};

export default MemoryRecallScreen;
