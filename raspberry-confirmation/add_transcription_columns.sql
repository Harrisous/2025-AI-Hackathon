-- Add transcription columns to existing audio_chunks table

ALTER TABLE audio_chunks 
ADD COLUMN IF NOT EXISTS transcription TEXT DEFAULT NULL;

ALTER TABLE audio_chunks 
ADD COLUMN IF NOT EXISTS transcribed_at TIMESTAMP DEFAULT NULL;
