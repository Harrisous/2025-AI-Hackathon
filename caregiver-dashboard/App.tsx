
import React, { useState, useCallback } from 'react';
import { Screen } from './types';
import HomeScreen from './components/HomeScreen';
import MemoryGalleryScreen from './components/MemoryGalleryScreen';
import MemoryRecallScreen from './components/MemoryRecallScreen';
import CaregiverDashboard from './components/CaregiverDashboard';

const App: React.FC = () => {
  const [screen, setScreen] = useState<Screen>(Screen.HOME);

  const navigateTo = useCallback((newScreen: Screen) => {
    setScreen(newScreen);
  }, []);

  const renderScreen = () => {
    switch (screen) {
      case Screen.HOME:
        return <HomeScreen navigateTo={navigateTo} />;
      case Screen.GALLERY:
        return <MemoryGalleryScreen navigateTo={navigateTo} />;
      case Screen.RECALL:
        return <MemoryRecallScreen navigateTo={navigateTo} />;
      case Screen.DASHBOARD:
        return <CaregiverDashboard navigateTo={navigateTo} />;
      default:
        return <HomeScreen navigateTo={navigateTo} />;
    }
  };

  return (
    <div className="w-full min-h-screen bg-[#F8F5F2] flex items-center justify-center p-4">
      <div className="w-full max-w-md md:max-w-lg lg:max-w-2xl h-[95vh] max-h-[800px] bg-white rounded-3xl shadow-lg overflow-hidden">
        {renderScreen()}
      </div>
    </div>
  );
};

export default App;
