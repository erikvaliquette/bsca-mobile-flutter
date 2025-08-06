-- Create action_activities table for storing tactical activities under strategic actions
-- This table supports the enhanced SDG structure: SDG → Target → Action → Activity

CREATE TABLE IF NOT EXISTS action_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_id UUID NOT NULL REFERENCES actions(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    start_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    due_date TIMESTAMPTZ,
    
    -- Impact tracking
    impact_value DECIMAL,
    impact_unit TEXT,
    impact_description TEXT,
    
    -- Evidence and verification
    evidence_urls TEXT[], -- Array of URLs to supporting documents/photos
    verification_method TEXT,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMPTZ,
    
    -- User and organization tracking
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    
    -- Tokenization placeholder (for future blockchain integration)
    tokens_awarded INTEGER,
    token_transaction_id TEXT,
    
    -- Additional metadata (JSONB for flexibility)
    metadata JSONB
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_action_activities_action_id ON action_activities(action_id);
CREATE INDEX IF NOT EXISTS idx_action_activities_user_id ON action_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_action_activities_organization_id ON action_activities(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_activities_status ON action_activities(status);
CREATE INDEX IF NOT EXISTS idx_action_activities_verification_status ON action_activities(verification_status);
CREATE INDEX IF NOT EXISTS idx_action_activities_created_at ON action_activities(created_at);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_action_activities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_action_activities_updated_at
    BEFORE UPDATE ON action_activities
    FOR EACH ROW
    EXECUTE FUNCTION update_action_activities_updated_at();

-- Row Level Security (RLS) policies
ALTER TABLE action_activities ENABLE ROW LEVEL SECURITY;

-- Users can view their own activities and activities from their organizations
CREATE POLICY "Users can view own activities" ON action_activities
    FOR SELECT USING (
        auth.uid() = user_id 
        OR 
        organization_id IN (
            SELECT organization_id 
            FROM organization_members 
            WHERE user_id = auth.uid() 
            AND status = 'approved'
        )
    );

-- Users can insert their own activities
CREATE POLICY "Users can insert own activities" ON action_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own activities
CREATE POLICY "Users can update own activities" ON action_activities
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own activities
CREATE POLICY "Users can delete own activities" ON action_activities
    FOR DELETE USING (auth.uid() = user_id);

-- Organization admins can verify activities within their organization
CREATE POLICY "Organization admins can verify activities" ON action_activities
    FOR UPDATE USING (
        organization_id IN (
            SELECT organization_id 
            FROM organization_members 
            WHERE user_id = auth.uid() 
            AND role = 'admin'
            AND status = 'approved'
        )
    );

-- Comments for documentation
COMMENT ON TABLE action_activities IS 'Tactical activities that execute strategic actions in the enhanced SDG structure';
COMMENT ON COLUMN action_activities.action_id IS 'Reference to the parent strategic action';
COMMENT ON COLUMN action_activities.status IS 'Current status of the activity: planned, in_progress, completed, cancelled';
COMMENT ON COLUMN action_activities.impact_value IS 'Quantified impact value (e.g., 12.5 for 12.5 metric tons CO2e)';
COMMENT ON COLUMN action_activities.impact_unit IS 'Unit of measurement for impact (e.g., metric tons CO2e, kWh saved)';
COMMENT ON COLUMN action_activities.evidence_urls IS 'Array of URLs to supporting evidence (photos, documents, receipts)';
COMMENT ON COLUMN action_activities.verification_status IS 'Verification status: pending, verified, rejected';
COMMENT ON COLUMN action_activities.tokens_awarded IS 'Placeholder for future tokenization/blockchain rewards';
COMMENT ON COLUMN action_activities.metadata IS 'Additional flexible data storage for future enhancements';
