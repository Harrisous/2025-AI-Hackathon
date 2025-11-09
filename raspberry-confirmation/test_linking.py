"""
Test if images are linked to audio chunks
"""

from supabase import create_client

SUPABASE_URL = "https://aidxatmmfpmhxxpkmnny.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZHhhdG1tZnBtaHh4cGttbm55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NTk3ODgsImV4cCI6MjA3ODEzNTc4OH0.MO26zZJUR4vZscB-QlE_Wr6TTXMaQb29JyLHNgvAbvQ"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print("="*80)
print("CHECKING IMAGE-AUDIO LINKING")
print("="*80)

# Get the test image
image_result = supabase.table('images').select('*').eq('filename', 'pic_2025-11-08+02-52.jpg').execute()

if image_result.data:
    image = image_result.data[0]
    print(f"\n✅ Image found: {image['filename']}")
    print(f"   Captured at: {image['captured_at']}")
    print(f"   Audio chunk ID: {image['audio_chunk_id']}")
    
    if image['audio_chunk_id']:
        # Get the linked audio chunk
        audio_result = supabase.table('audio_chunks').select('*').eq('id', image['audio_chunk_id']).execute()
        
        if audio_result.data:
            audio = audio_result.data[0]
            print(f"\n✅ Linked to audio chunk:")
            print(f"   Filename: {audio['filename']}")
            print(f"   Start time: {audio['start_time']}")
            print(f"   End time: {audio['end_time']}")
            print(f"   Transcription: {audio['transcription'][:100]}...")
            print(f"\n🎉 SUCCESS! Image is correctly linked to audio chunk!")
        else:
            print("\n❌ Audio chunk not found")
    else:
        print("\n⚠️  Image has no audio_chunk_id (not linked)")
else:
    print("\n❌ Image not found in database")

print("\n" + "="*80)
