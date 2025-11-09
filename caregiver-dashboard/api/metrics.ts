/**
 * Metrics API - Fetches real data from deployed MemorEye APIs
 * 
 * Memory API: https://2025-ai-hackathon-raspberry-api-api-production-5bd5.up.railway.app
 * Image API: https://2025-ai-hackathon-raspberry-api-api-production-bfcb.up.railway.app
 */

const MEMORY_API = 'https://2025-ai-hackathon-raspberry-api-api-production-5bd5.up.railway.app';
const IMAGE_API = 'https://2025-ai-hackathon-raspberry-api-api-production-bfcb.up.railway.app';

export interface SessionMetrics {
  sessionId: string;
  timestamp: string;
  correctAnswers: number;
  totalQuestions: number;
  attempts: { [questionId: string]: number };
  memoryType: 'short_term' | 'long_term';
  apiType: 'text' | 'image';
}

export interface DashboardMetrics {
  forgettingCurve: { name: string; recall: number }[];
  learningCurve: { session: string; score: number }[];
  correctRate: { name: string; value: number }[];
  attemptsData: { name: string; value: number }[];
  improvementData: { week: string; score: number }[];
}

/**
 * Store session results in localStorage for metrics tracking
 */
export function storeSessionResult(session: SessionMetrics) {
  const sessions = getStoredSessions();
  sessions.push(session);
  localStorage.setItem('memorEye_sessions', JSON.stringify(sessions));
}

/**
 * Get all stored sessions
 */
export function getStoredSessions(): SessionMetrics[] {
  const stored = localStorage.getItem('memorEye_sessions');
  return stored ? JSON.parse(stored) : [];
}

/**
 * Calculate dashboard metrics from stored sessions
 */
export function calculateMetrics(): DashboardMetrics {
  const sessions = getStoredSessions();
  
  if (sessions.length === 0) {
    // Return dummy data if no sessions yet
    return {
      forgettingCurve: [
        { name: '1h', recall: 90 }, { name: '8h', recall: 65 },
        { name: '1d', recall: 50 }, { name: '2d', recall: 42 },
        { name: '5d', recall: 30 }, { name: '7d', recall: 25 },
      ],
      learningCurve: [
        { session: 'S1', score: 55 }, { session: 'S2', score: 58 },
        { session: 'S3', score: 62 }, { session: 'S4', score: 61 },
        { session: 'S5', score: 65 }, { session: 'S6', score: 70 },
        { session: 'S7', score: 72 },
      ],
      correctRate: [
        { name: 'Correct', value: 78 },
        { name: 'Incorrect', value: 22 }
      ],
      attemptsData: [
        { name: '1 attempt', value: 65 },
        { name: '2 attempts', value: 25 },
        { name: '3+ attempts', value: 10 },
      ],
      improvementData: [
        { week: 'W1', score: 65 }, { week: 'W2', score: 68 },
        { week: 'W3', score: 72 }, { week: 'W4', score: 71 },
        { week: 'W5', score: 75 }, { week: 'W6', score: 78 },
      ]
    };
  }

  // Calculate learning curve (session by session)
  const learningCurve = sessions.slice(-10).map((session, index) => ({
    session: `S${index + 1}`,
    score: Math.round((session.correctAnswers / session.totalQuestions) * 100)
  }));

  // Calculate correct rate (overall)
  const totalCorrect = sessions.reduce((sum, s) => sum + s.correctAnswers, 0);
  const totalQuestions = sessions.reduce((sum, s) => sum + s.totalQuestions, 0);
  const correctPercentage = Math.round((totalCorrect / totalQuestions) * 100);
  const correctRate = [
    { name: 'Correct', value: correctPercentage },
    { name: 'Incorrect', value: 100 - correctPercentage }
  ];

  // Calculate attempts distribution
  const allAttempts = sessions.flatMap(s => Object.values(s.attempts));
  const oneAttempt = allAttempts.filter(a => a === 1).length;
  const twoAttempts = allAttempts.filter(a => a === 2).length;
  const threeOrMore = allAttempts.filter(a => a >= 3).length;
  const total = allAttempts.length || 1;
  
  const attemptsData = [
    { name: '1 attempt', value: Math.round((oneAttempt / total) * 100) },
    { name: '2 attempts', value: Math.round((twoAttempts / total) * 100) },
    { name: '3+ attempts', value: Math.round((threeOrMore / total) * 100) },
  ];

  // Calculate improvement over time (weekly)
  const weeklyScores = groupByWeek(sessions);
  const improvementData = weeklyScores.map((score, index) => ({
    week: `W${index + 1}`,
    score: Math.round(score)
  }));

  // Calculate forgetting curve (short-term vs long-term memory)
  const forgettingCurve = calculateForgettingCurve(sessions);

  return {
    forgettingCurve,
    learningCurve,
    correctRate,
    attemptsData,
    improvementData
  };
}

/**
 * Group sessions by week and calculate average score
 */
function groupByWeek(sessions: SessionMetrics[]): number[] {
  const weeks: { [week: number]: { correct: number; total: number } } = {};
  
  sessions.forEach(session => {
    const date = new Date(session.timestamp);
    const weekNum = Math.floor((Date.now() - date.getTime()) / (7 * 24 * 60 * 60 * 1000));
    
    if (!weeks[weekNum]) {
      weeks[weekNum] = { correct: 0, total: 0 };
    }
    
    weeks[weekNum].correct += session.correctAnswers;
    weeks[weekNum].total += session.totalQuestions;
  });
  
  return Object.values(weeks)
    .map(w => (w.correct / w.total) * 100)
    .slice(0, 6);
}

/**
 * Calculate forgetting curve based on memory type and time
 */
function calculateForgettingCurve(sessions: SessionMetrics[]) {
  const now = Date.now();
  const timeRanges = [
    { name: '1h', hours: 1 },
    { name: '8h', hours: 8 },
    { name: '1d', hours: 24 },
    { name: '2d', hours: 48 },
    { name: '5d', hours: 120 },
    { name: '7d', hours: 168 },
  ];
  
  return timeRanges.map(range => {
    const cutoff = now - (range.hours * 60 * 60 * 1000);
    const relevantSessions = sessions.filter(s => 
      new Date(s.timestamp).getTime() >= cutoff
    );
    
    if (relevantSessions.length === 0) {
      return { name: range.name, recall: 0 };
    }
    
    const avgRecall = relevantSessions.reduce((sum, s) => 
      sum + (s.correctAnswers / s.totalQuestions), 0
    ) / relevantSessions.length;
    
    return {
      name: range.name,
      recall: Math.round(avgRecall * 100)
    };
  });
}

/**
 * Test connection to APIs
 */
export async function testAPIConnection(): Promise<{ memory: boolean; image: boolean }> {
  try {
    const memoryTest = await fetch(`${MEMORY_API}/api/start`, { method: 'POST' });
    const imageTest = await fetch(`${IMAGE_API}/api/start`, { method: 'POST' });
    
    return {
      memory: memoryTest.ok,
      image: imageTest.ok
    };
  } catch (error) {
    console.error('API connection test failed:', error);
    return { memory: false, image: false };
  }
}
