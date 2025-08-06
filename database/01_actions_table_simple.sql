-- Create actions table for storing strategic sustainability actions
-- Simplified version with minimal dependencies

CREATE TABLE IF NOT EXISTS actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic action information
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'personal' CHECK (category IN ('personal', 'community', 'workplace', 'education')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    
    -- SDG relationship (simplified)
    sdg_id INTEGER NOT NULL,
    
    -- Progress tracking
    progress DECIMAL NOT NULL DEFAULT 0.0 CHECK (progress >= 0.0 AND progress <= 1.0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    
    -- Sustainability tracking fields
    baseline_value DECIMAL,
    baseline_unit TEXT,
    baseline_date TIMESTAMPTZ,
    baseline_methodology TEXT,
    
    target_value DECIMAL,
    target_date TIMESTAMPTZ,
    verification_method TEXT,
    
    -- Optional references (can be NULL if tables don't exist)
    organization_id UUID, -- No foreign key constraint for now
    sdg_target_id UUID,   -- No foreign key constraint for now
    
    -- Additional metadata (JSONB for flexibility)
    metadata JSONB
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_actions_user_id ON actions(user_id);
CREATE INDEX IF NOT EXISTS idx_actions_organization_id ON actions(organization_id);
CREATE INDEX IF NOT EXISTS idx_actions_sdg_target_id ON actions(sdg_target_id);
CREATE INDEX IF NOT EXISTS idx_actions_sdg_id ON actions(sdg_id);
CREATE INDEX IF NOT EXISTS idx_actions_category ON actions(category);
CREATE INDEX IF NOT EXISTS idx_actions_priority ON actions(priority);
CREATE INDEX IF NOT EXISTS idx_actions_is_completed ON actions(is_completed);
CREATE INDEX IF NOT EXISTS idx_actions_created_at ON actions(created_at);
CREATE INDEX IF NOT EXISTS idx_actions_due_date ON actions(due_date);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_actions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_actions_updated_at
    BEFORE UPDATE ON actions
    FOR EACH ROW
    EXECUTE FUNCTION update_actions_updated_at();

-- Row Level Security (RLS) policies
ALTER TABLE actions ENABLE ROW LEVEL SECURITY;

-- Users can view their own actions
CREATE POLICY "Users can view own actions" ON actions
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own actions
CREATE POLICY "Users can insert own actions" ON actions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own actions
CREATE POLICY "Users can update own actions" ON actions
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own actions
CREATE POLICY "Users can delete own actions" ON actions
    FOR DELETE USING (auth.uid() = user_id);

-- Comments for documentation
COMMENT ON TABLE actions IS 'Strategic sustainability actions in the enhanced SDG structure';
COMMENT ON COLUMN actions.sdg_id IS 'SDG ID (1-17) this action addresses';
COMMENT ON COLUMN actions.category IS 'Action category: personal, community, workplace, education';
COMMENT ON COLUMN actions.priority IS 'Action priority: low, medium, high';
COMMENT ON COLUMN actions.progress IS 'Progress completion (0.0 to 1.0)';
COMMENT ON COLUMN actions.baseline_value IS 'Starting measurement value for sustainability tracking';
COMMENT ON COLUMN actions.target_value IS 'Goal value to achieve';
COMMENT ON COLUMN actions.verification_method IS 'Method for verifying action progress and impact';
