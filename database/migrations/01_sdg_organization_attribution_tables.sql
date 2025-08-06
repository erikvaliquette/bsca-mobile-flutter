-- SDG Organization Attribution Database Schema
-- Phase 1: Foundation tables for attributing SDG targets, actions, and activities to organizations

-- Junction table for SDG Target organization attribution
CREATE TABLE sdg_target_organization_attribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sdg_target_id UUID REFERENCES sdg_targets(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  attributed_by UUID REFERENCES auth.users(id),
  attribution_date TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Junction table for Action organization attribution
CREATE TABLE action_organization_attribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_id UUID REFERENCES actions(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  impact_value DECIMAL(10,2),
  impact_unit VARCHAR(50),
  attributed_by UUID REFERENCES auth.users(id),
  attribution_date TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Junction table for Activity organization attribution
CREATE TABLE activity_organization_attribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID REFERENCES action_activities(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  impact_value DECIMAL(10,2),
  impact_unit VARCHAR(50),
  attributed_by UUID REFERENCES auth.users(id),
  attribution_date TIMESTAMP DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Organization impact metrics tracking
CREATE TABLE organization_impact_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id),
  year INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
  sdg_targets_count INTEGER DEFAULT 0,
  actions_count INTEGER DEFAULT 0,
  activities_count INTEGER DEFAULT 0,
  completed_actions_count INTEGER DEFAULT 0,
  total_impact_value DECIMAL(15,2) DEFAULT 0,
  impact_unit VARCHAR(50) DEFAULT 'mixed',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(organization_id, year)
);

-- Add attribution metadata to existing tables
ALTER TABLE sdg_targets ADD COLUMN IF NOT EXISTS attribution_type VARCHAR(20) DEFAULT 'personal';
ALTER TABLE actions ADD COLUMN IF NOT EXISTS attribution_type VARCHAR(20) DEFAULT 'personal';
ALTER TABLE action_activities ADD COLUMN IF NOT EXISTS attribution_type VARCHAR(20) DEFAULT 'personal';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sdg_target_attribution_active ON sdg_target_organization_attribution(sdg_target_id, is_active);
CREATE INDEX IF NOT EXISTS idx_action_attribution_active ON action_organization_attribution(action_id, is_active);
CREATE INDEX IF NOT EXISTS idx_activity_attribution_active ON activity_organization_attribution(activity_id, is_active);
CREATE INDEX IF NOT EXISTS idx_organization_impact_metrics_org_year ON organization_impact_metrics(organization_id, year);

-- RLS Policies for SDG Target Attribution
ALTER TABLE sdg_target_organization_attribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view attributions for their targets or organizations" ON sdg_target_organization_attribution
  FOR SELECT USING (
    attributed_by = auth.uid() OR
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can create attributions for their targets" ON sdg_target_organization_attribution
  FOR INSERT WITH CHECK (
    attributed_by = auth.uid() AND
    sdg_target_id IN (
      SELECT id FROM sdg_targets WHERE user_id = auth.uid()
    ) AND
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can update their own attributions" ON sdg_target_organization_attribution
  FOR UPDATE USING (attributed_by = auth.uid());

-- RLS Policies for Action Attribution
ALTER TABLE action_organization_attribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view attributions for their actions or organizations" ON action_organization_attribution
  FOR SELECT USING (
    attributed_by = auth.uid() OR
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can create attributions for their actions" ON action_organization_attribution
  FOR INSERT WITH CHECK (
    attributed_by = auth.uid() AND
    action_id IN (
      SELECT id FROM actions WHERE user_id = auth.uid()
    ) AND
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can update their own attributions" ON action_organization_attribution
  FOR UPDATE USING (attributed_by = auth.uid());

-- RLS Policies for Activity Attribution
ALTER TABLE activity_organization_attribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view attributions for their activities or organizations" ON activity_organization_attribution
  FOR SELECT USING (
    attributed_by = auth.uid() OR
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can create attributions for their activities" ON activity_organization_attribution
  FOR INSERT WITH CHECK (
    attributed_by = auth.uid() AND
    activity_id IN (
      SELECT id FROM action_activities WHERE action_id IN (
        SELECT id FROM actions WHERE user_id = auth.uid()
      )
    ) AND
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Users can update their own attributions" ON activity_organization_attribution
  FOR UPDATE USING (attributed_by = auth.uid());

-- RLS Policies for Organization Impact Metrics
ALTER TABLE organization_impact_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organization members can view impact metrics" ON organization_impact_metrics
  FOR SELECT USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved'
    )
  );

CREATE POLICY "Organization admins can manage impact metrics" ON organization_impact_metrics
  FOR ALL USING (
    organization_id IN (
      SELECT organization_id FROM organization_members 
      WHERE user_id = auth.uid() AND status = 'approved' AND role = 'admin'
    )
  );

-- Triggers for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sdg_target_attribution_updated_at BEFORE UPDATE ON sdg_target_organization_attribution FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_action_attribution_updated_at BEFORE UPDATE ON action_organization_attribution FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_activity_attribution_updated_at BEFORE UPDATE ON activity_organization_attribution FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_organization_impact_metrics_updated_at BEFORE UPDATE ON organization_impact_metrics FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
