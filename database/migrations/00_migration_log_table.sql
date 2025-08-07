-- Migration Log Table Setup
-- This table tracks which migrations have been applied to the database

CREATE TABLE IF NOT EXISTS migration_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  migration_name VARCHAR(255) UNIQUE NOT NULL,
  applied_at TIMESTAMP DEFAULT NOW(),
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS for migration log
ALTER TABLE migration_log ENABLE ROW LEVEL SECURITY;

-- Allow admins to view migration log
CREATE POLICY "Admins can view migration log" ON migration_log
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM organization_members 
      WHERE role = 'admin' AND status = 'approved'
    )
  );

-- Log the creation of this table
INSERT INTO migration_log (migration_name, applied_at, description) 
VALUES (
  '00_migration_log_table', 
  NOW(), 
  'Initial migration log table setup for tracking database schema changes'
) ON CONFLICT (migration_name) DO NOTHING;
