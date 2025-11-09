
export enum Screen {
  HOME,
  GALLERY,
  RECALL,
  DASHBOARD
}

export interface GalleryItem {
  id: string;
  imageUrl: string;
  label: string;
}

export interface RecallMessage {
    id: number;
    text: string;
    sender: 'user' | 'agent';
}
