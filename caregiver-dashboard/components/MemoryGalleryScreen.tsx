
import React from 'react';
import { Screen, GalleryItem } from '../types';

interface MemoryGalleryScreenProps {
  navigateTo: (screen: Screen) => void;
}

const mockGallery: GalleryItem[] = [
  { id: '1', imageUrl: 'https://i.imgur.com/L12wEAY.jpeg', label: 'My sister' },
  { id: '2', imageUrl: 'https://i.imgur.com/e2a1j2D.jpeg', label: 'My brother' },
  { id: '3', imageUrl: 'https://picsum.photos/seed/granddaughter/400/400', label: 'Granddaughter' },
  { id: '4', imageUrl: 'https://picsum.photos/seed/wedding/400/400', label: 'Wedding Day' },
];

const MenuIcon = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <line x1="3" y1="12" x2="21" y2="12"></line>
        <line x1="3" y1="6" x2="21" y2="6"></line>
        <line x1="3" y1="18" x2="21" y2="18"></line>
    </svg>
)

const UploadIcon = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
        <path d="M11 15H13V11H17V9H13V5H11V9H7V11H11V15ZM12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2ZM12 20C7.59 20 4 16.41 4 12C4 7.59 7.59 4 12 4C16.41 4 20 7.59 20 12C20 16.41 16.41 20 12 20Z"/>
    </svg>
)

const MemoryGalleryScreen: React.FC<MemoryGalleryScreenProps> = ({ navigateTo }) => {
  return (
    <div className="flex flex-col h-full bg-[#F8F5F2] text-[#362E2B] p-6">
      <header className="flex items-center justify-between mb-8">
        <button onClick={() => navigateTo(Screen.HOME)} className="p-2">
          <MenuIcon />
        </button>
        <h1 className="font-serif text-4xl font-bold">Memory Gallery</h1>
        <div className="w-10"></div>
      </header>

      <div className="text-center mb-8">
        <button className="bg-[#E5B8A2] text-white font-bold py-3 px-6 rounded-lg shadow-md hover:bg-opacity-90 transition-all flex items-center gap-2 mx-auto">
          <UploadIcon />
          Upload Image
        </button>
      </div>

      <div className="flex-grow overflow-y-auto pr-2">
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-6">
          {mockGallery.map(item => (
            <div key={item.id} className="bg-white rounded-2xl p-3 shadow-md">
              <img src={item.imageUrl} alt={item.label} className="w-full h-40 object-cover rounded-lg mb-3" />
              <p className="text-center font-semibold text-gray-700">{item.label}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default MemoryGalleryScreen;
