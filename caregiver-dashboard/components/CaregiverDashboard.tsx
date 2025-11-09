import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, BarChart, Bar } from 'recharts';
// FIX: Import Screen type to be used by the navigateTo prop.
import { Screen } from '../types';
import { calculateMetrics, DashboardMetrics } from '../api/metrics';

const COLORS = ['#A7D2D3', '#E5B8A2'];
const ATTEMPT_COLORS = ['#A7D2D3', '#E5B8A2', '#F2D3AC'];

// FIX: Define props interface to accept an optional navigateTo function, resolving the type error in App.tsx.
interface CaregiverDashboardProps {
    navigateTo?: (screen: Screen) => void;
}

// FIX: Add ArrowLeftIcon for the back button.
const ArrowLeftIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
    </svg>
);

const ChartCard: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
    <div className="bg-white p-6 rounded-2xl shadow-lg">
        <h3 className="font-serif text-2xl font-semibold mb-4 text-[#362E2B]">{title}</h3>
        <div style={{ width: '100%', height: 300 }}>
            {children}
        </div>
    </div>
);

// FIX: Update the component to accept props.
const CaregiverDashboard: React.FC<CaregiverDashboardProps> = ({ navigateTo }) => {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null);

  useEffect(() => {
    // Load metrics from stored sessions
    const loadedMetrics = calculateMetrics();
    setMetrics(loadedMetrics);

    // Refresh metrics every 30 seconds
    const interval = setInterval(() => {
      const refreshedMetrics = calculateMetrics();
      setMetrics(refreshedMetrics);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  if (!metrics) {
    return (
      <div className="min-h-screen bg-[#F8F5F2] flex items-center justify-center">
        <p className="text-xl text-gray-600">Loading metrics...</p>
      </div>
    );
  }

  const { forgettingCurve, learningCurve, correctRate, attemptsData, improvementData } = metrics;

  return (
    <div className="min-h-screen bg-[#F8F5F2] text-[#362E2B] p-4 sm:p-6 md:p-8">
      <div className="max-w-7xl mx-auto">
        {/* FIX: Add a back button and update header layout to accommodate it. */}
        <header className="mb-8 flex items-center">
          {navigateTo && (
              <button onClick={() => navigateTo(Screen.HOME)} className="p-2 rounded-full hover:bg-gray-200 mr-4">
                  <ArrowLeftIcon />
              </button>
          )}
          <div>
            <h1 className="font-serif text-3xl md:text-4xl font-bold">Caregiver Dashboard</h1>
            <p className="text-gray-500 mt-1">Patient: John Appleseed</p>
          </div>
        </header>

        <main className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <ChartCard title="Forgetting Curve">
                <ResponsiveContainer>
                    <LineChart data={forgettingCurve}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" />
                        <YAxis unit="%" />
                        <Tooltip />
                        <Legend />
                        <Line type="monotone" dataKey="recall" stroke="#E5B8A2" strokeWidth={2} activeDot={{ r: 8 }} />
                    </LineChart>
                </ResponsiveContainer>
            </ChartCard>

            <ChartCard title="Learning Curve">
                <ResponsiveContainer>
                    <LineChart data={learningCurve}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="session" />
                        <YAxis unit="%" domain={[50, 80]}/>
                        <Tooltip />
                        <Legend />
                        <Line type="monotone" dataKey="score" name="Recall Score" stroke="#A7D2D3" strokeWidth={2} />
                    </LineChart>
                </ResponsiveContainer>
            </ChartCard>

            <ChartCard title="Q&A Correct Rate">
                <ResponsiveContainer>
                    <PieChart>
                        <Pie data={correctRate} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={100} label>
                            {correctRate.map((entry, index) => <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />)}
                        </Pie>
                        <Tooltip />
                        <Legend />
                    </PieChart>
                </ResponsiveContainer>
            </ChartCard>

            <ChartCard title="Attempts to Answer">
                <ResponsiveContainer>
                    <BarChart data={attemptsData} layout="vertical" margin={{ top: 20, right: 30, left: 30, bottom: 5 }}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis type="number" />
                        <YAxis type="category" dataKey="name" width={90} />
                        <Tooltip />
                        <Bar dataKey="value" fill="#A7D2D3" barSize={25}>
                            {attemptsData.map((entry, index) => (
                                <Cell key={`cell-${index}`} fill={ATTEMPT_COLORS[index % ATTEMPT_COLORS.length]} />
                            ))}
                        </Bar>
                    </BarChart>
                </ResponsiveContainer>
            </ChartCard>

            <div className="lg:col-span-2">
                <ChartCard title="Improvement Over Time">
                    <ResponsiveContainer>
                        <LineChart data={improvementData}>
                            <CartesianGrid strokeDasharray="3 3" />
                            <XAxis dataKey="week" />
                            <YAxis unit="%" domain={[60, 90]} />
                            <Tooltip />
                            <Legend />
                            <Line type="monotone" dataKey="score" name="Overall Score" stroke="#82ca9d" strokeWidth={3} />
                        </LineChart>
                    </ResponsiveContainer>
                </ChartCard>
            </div>
        </main>
      </div>
    </div>
  );
};

export default CaregiverDashboard;