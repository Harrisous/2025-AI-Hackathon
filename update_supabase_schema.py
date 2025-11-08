"""
Add transcription columns to Supabase audio_chunks table
"""

from supabase import create_client

SUPABASE_URL = "https://aidxatmmfpmhxxpkmnny.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZHhhdG1tZnBtaHh4cGttbm55Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NTk3ODgsImV4cCI6MjA3ODEzNTc4OH0.MO26zZJUR4vZscB-QlE_Wr6TTXMaQb29JyLHNgvAbvQ"

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

print("="*60)
print("UPDATING SUPABASE SCHEMA")
print("="*60)

# SQL to add columns
sql_commands = [
    "ALTER TABLE audio_chunks ADD COLUMN IF NOT EXISTS transcription TEXT DEFAULT NULL;",
    "ALTER TABLE audio_chunks ADD COLUMN IF NOT EXISTS transcribed_at TIMESTAMP DEFAULT NULL;"
]

for sql in sql_commands:
    try:
        print(f"\nExecuting: {sql}")
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        print("✅ Success!")
    except Exception as e:
        # Try alternative method using postgrest
        print(f"⚠️  RPC method failed: {e}")
        print("Please run this SQL manually in Supabase SQL Editor:")
        print(sql)

print("\n" + "="*60)
print("SCHEMA UPDATE COMPLETE")
print("="*60)
print("\nPlease verify in Supabase dashboard that columns were added:")
print("1. Go to Table Editor")
print("2. Select 'audio_chunks' table")
print("3. Check for 'transcription' and 'transcribed_at' columns")
