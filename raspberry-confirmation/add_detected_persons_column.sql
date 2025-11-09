-- Add detected_persons column to existing images table

ALTER TABLE images 
ADD COLUMN IF NOT EXISTS detected_persons TEXT[] DEFAULT NULL;
