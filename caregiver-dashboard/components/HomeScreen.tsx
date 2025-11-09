
import React from 'react';
import { Screen } from '../types';

interface HomeScreenProps {
  navigateTo: (screen: Screen) => void;
}

const StartIcon = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
        <path d="M8 5V19L19 12L8 5Z" />
    </svg>
);

const TestIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
        <polyline points="14 2 14 8 20 8"></polyline>
        <line x1="16" y1="13" x2="8" y2="13"></line>
        <line x1="16" y1="17" x2="8" y2="17"></line>
        <polyline points="10 9 9 9 8 9"></polyline>
    </svg>
);

const GalleryIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
        <circle cx="8.5" cy="8.5" r="1.5"></circle>
        <polyline points="21 15 16 10 5 21"></polyline>
    </svg>
);

const DashboardIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M3 3v18h18"/>
        <path d="M18.7 8a6 6 0 0 0-6-6"/>
        <path d="M13 13a4 4 0 0 1-4-4"/>
        <path d="M13 13a4 4 0 0 0 4 4"/>
    </svg>
)

const HomeScreen: React.FC<HomeScreenProps> = ({ navigateTo }) => {
  const currentDate = new Date().toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <div className="flex flex-col h-full bg-[#F8F5F2] text-[#362E2B] p-8 text-center items-center">
      <header className="w-full">
          <p className="text-sm text-gray-500">12:04 AM &middot; Sun Nov 9</p>
      </header>
      
      <main className="flex-grow flex flex-col items-center justify-center w-full">
        <h1 className="font-serif text-6xl font-bold mt-4">Hi, John!</h1>
        <p className="text-xl text-gray-500 mt-2">{currentDate}</p>

        <div className="my-8 w-full max-w-sm">
          <img src="https://i.imgur.com/8Fk5g3g.png" alt="Globe with flowers" className="w-full h-auto object-contain" />
        </div>
        
        <button 
          onClick={() => navigateTo(Screen.RECALL)}
          className="bg-[#E5B8A2] text-white font-bold py-3 px-8 rounded-full text-lg shadow-md hover:bg-opacity-90 transition-all flex items-center gap-2"
        >
          <StartIcon />
          Start Recall
        </button>
      </main>

      <footer className="w-full grid grid-cols-2 gap-4 mt-auto">
        <button 
          onClick={() => navigateTo(Screen.RECALL)}
          className="bg-[#A7D2D3] text-white font-semibold py-4 px-4 rounded-xl shadow-sm hover:bg-opacity-90 transition-all flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
              <TestIcon />
              <span>Memory Test</span>
          </div>
          <span>&gt;</span>
        </button>
        <button 
          onClick={() => navigateTo(Screen.GALLERY)}
          className="bg-[#A7D2D3] text-white font-semibold py-4 px-4 rounded-xl shadow-sm hover:bg-opacity-90 transition-all flex items-center justify-between"
        >
          <div className="flex items-center gap-3">
            <GalleryIcon />
            <span>Memory Gallery</span>
          </div>
          <span>&gt;</span>
        </button>
        <button 
          onClick={() => navigateTo(Screen.DASHBOARD)}
          className="col-span-2 bg-gray-200 text-gray-700 font-semibold py-3 px-4 rounded-xl shadow-sm hover:bg-gray-300 transition-all flex items-center justify-center gap-3 text-sm"
        >
          <DashboardIcon />
          <span>Caregiver Dashboard</span>
        </button>
      </footer>
    </div>
  );
};

export default HomeScreen;
