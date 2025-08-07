-- Target-Level Cascading Attribution Migration
-- Phase 2: Optimize database schema for target-level cascading attribution system
-- This migration updates the schema to support the new target-level attribution model
-- where SDG Targets control attribution and cascade to Actions and Activities

-- ============================================================================
-- PART 1: Add Unique Constraints for Attribution Tables (Required First)
-- ============================================================================

-- Add unique constraints to prevent duplicate active attributions
-- These must be created before the functions that use ON CONFLICT

-- Add unique constraint for target attribution
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'unique_active_target_attribution' 
    AND table_name = 'sdg_target_organization_attribution'
  ) THEN
    ALTER TABLE sdg_target_organization_attribution 
    ADD CONSTRAINT unique_active_target_attribution 
    UNIQUE (sdg_target_id, organization_id);
  END IF;
END $$;

-- Add unique constraint for action attribution
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'unique_active_action_attribution' 
    AND table_name = 'action_organization_attribution'
  ) THEN
    ALTER TABLE action_organization_attribution 
    ADD CONSTRAINT unique_active_action_attribution 
    UNIQUE (action_id, organization_id);
  END IF;
END $$;

-- Add unique constraint for activity attribution
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'unique_active_activity_attribution' 
    AND table_name = 'activity_organization_attribution'
  ) THEN
    ALTER TABLE activity_organization_attribution 
    ADD CONSTRAINT unique_active_activity_attribution 
    UNIQUE (activity_id, organization_id);
  END IF;
END $$;

-- ============================================================================
-- PART 2: Database Functions for Cascading Attribution
-- ============================================================================

-- Function to cascade target attribution to actions and activities
CREATE OR REPLACE FUNCTION cascade_target_attribution()
RETURNS TRIGGER AS $$
BEGIN
  -- Handle target attribution changes
  IF TG_OP = 'UPDATE' AND OLD.organization_id IS DISTINCT FROM NEW.organization_id THEN
    
    -- Update action attributions when target attribution changes
    IF OLD.organization_id IS NOT NULL THEN
      -- Deactivate old action attributions
      UPDATE action_organization_attribution 
      SET is_active = FALSE, updated_at = NOW()
      WHERE action_id IN (
        SELECT id FROM actions WHERE sdg_target_id = NEW.id
      ) AND organization_id = OLD.organization_id AND is_active = TRUE;
      
      -- Deactivate old activity attributions
      UPDATE activity_organization_attribution 
      SET is_active = FALSE, updated_at = NOW()
      WHERE activity_id IN (
        SELECT aa.id FROM action_activities aa
        JOIN actions a ON aa.action_id = a.id
        WHERE a.sdg_target_id = NEW.id
      ) AND organization_id = OLD.organization_id AND is_active = TRUE;
    END IF;
    
    -- Create new attributions if target is now attributed to an organization
    IF NEW.organization_id IS NOT NULL THEN
      -- Create target attribution record
      INSERT INTO sdg_target_organization_attribution (
        sdg_target_id, organization_id, attributed_by, attribution_date, is_active
      ) VALUES (
        NEW.id, NEW.organization_id, NEW.user_id, NOW(), TRUE
      ) ON CONFLICT (sdg_target_id, organization_id) 
      DO UPDATE SET is_active = TRUE, updated_at = NOW();
      
      -- Create action attributions for all actions under this target
      INSERT INTO action_organization_attribution (
        action_id, organization_id, attributed_by, attribution_date, is_active
      )
      SELECT a.id, NEW.organization_id, NEW.user_id, NOW(), TRUE
      FROM actions a
      WHERE a.sdg_target_id = NEW.id
      ON CONFLICT (action_id, organization_id) 
      DO UPDATE SET is_active = TRUE, updated_at = NOW();
      
      -- Create activity attributions for all activities under this target's actions
      INSERT INTO activity_organization_attribution (
        activity_id, organization_id, attributed_by, attribution_date, is_active
      )
      SELECT aa.id, NEW.organization_id, NEW.user_id, NOW(), TRUE
      FROM action_activities aa
      JOIN actions a ON aa.action_id = a.id
      WHERE a.sdg_target_id = NEW.id
      ON CONFLICT (activity_id, organization_id) 
      DO UPDATE SET is_active = TRUE, updated_at = NOW();
    ELSE
      -- Remove target attribution if target is now personal
      UPDATE sdg_target_organization_attribution 
      SET is_active = FALSE, updated_at = NOW()
      WHERE sdg_target_id = NEW.id AND is_active = TRUE;
    END IF;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new actions under attributed targets
CREATE OR REPLACE FUNCTION cascade_action_attribution()
RETURNS TRIGGER AS $$
DECLARE
  target_org_id UUID;
BEGIN
  -- When a new action is created, check if its target is attributed to an organization
  IF TG_OP = 'INSERT' AND NEW.sdg_target_id IS NOT NULL THEN
    SELECT organization_id INTO target_org_id
    FROM sdg_targets
    WHERE id = NEW.sdg_target_id;
    
    -- If target is attributed to an organization, create action attribution
    IF target_org_id IS NOT NULL THEN
      INSERT INTO action_organization_attribution (
        action_id, organization_id, attributed_by, attribution_date, is_active
      ) VALUES (
        NEW.id, target_org_id, NEW.user_id, NOW(), TRUE
      ) ON CONFLICT (action_id, organization_id) 
      DO UPDATE SET is_active = TRUE, updated_at = NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new activities under attributed actions
CREATE OR REPLACE FUNCTION cascade_activity_attribution()
RETURNS TRIGGER AS $$
DECLARE
  target_org_id UUID;
BEGIN
  -- When a new activity is created, check if its action's target is attributed to an organization
  IF TG_OP = 'INSERT' AND NEW.action_id IS NOT NULL THEN
    SELECT st.organization_id INTO target_org_id
    FROM sdg_targets st
    JOIN actions a ON a.sdg_target_id = st.id
    WHERE a.id = NEW.action_id;
    
    -- If target is attributed to an organization, create activity attribution
    IF target_org_id IS NOT NULL THEN
      INSERT INTO activity_organization_attribution (
        activity_id, organization_id, attributed_by, attribution_date, is_active
      ) VALUES (
        NEW.id, target_org_id, NEW.user_id, NOW(), TRUE
      ) ON CONFLICT (activity_id, organization_id) 
      DO UPDATE SET is_active = TRUE, updated_at = NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 2: Create Triggers for Automatic Cascading
-- ============================================================================

-- Trigger for target attribution changes
DROP TRIGGER IF EXISTS trigger_cascade_target_attribution ON sdg_targets;
CREATE TRIGGER trigger_cascade_target_attribution
  AFTER UPDATE ON sdg_targets
  FOR EACH ROW
  EXECUTE FUNCTION cascade_target_attribution();

-- Trigger for new actions under attributed targets
DROP TRIGGER IF EXISTS trigger_cascade_action_attribution ON actions;
CREATE TRIGGER trigger_cascade_action_attribution
  AFTER INSERT ON actions
  FOR EACH ROW
  EXECUTE FUNCTION cascade_action_attribution();

-- Trigger for new activities under attributed actions
DROP TRIGGER IF EXISTS trigger_cascade_activity_attribution ON action_activities;
CREATE TRIGGER trigger_cascade_activity_attribution
  AFTER INSERT ON action_activities
  FOR EACH ROW
  EXECUTE FUNCTION cascade_activity_attribution();

-- ============================================================================
-- PART 3: Update Organization Impact Metrics Function
-- ============================================================================

-- Function to recalculate organization impact metrics
CREATE OR REPLACE FUNCTION recalculate_organization_metrics(org_id UUID, target_year INTEGER DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  calc_year INTEGER;
BEGIN
  calc_year := COALESCE(target_year, EXTRACT(YEAR FROM NOW()));
  
  -- Insert or update organization metrics
  INSERT INTO organization_impact_metrics (
    organization_id, 
    year, 
    sdg_targets_count,
    actions_count,
    activities_count,
    completed_actions_count
  )
  SELECT 
    org_id,
    calc_year,
    (SELECT COUNT(*) FROM sdg_target_organization_attribution sta 
     WHERE sta.organization_id = org_id AND sta.is_active = TRUE),
    (SELECT COUNT(*) FROM action_organization_attribution aoa 
     WHERE aoa.organization_id = org_id AND aoa.is_active = TRUE),
    (SELECT COUNT(*) FROM activity_organization_attribution aca 
     WHERE aca.organization_id = org_id AND aca.is_active = TRUE),
    (SELECT COUNT(*) FROM action_organization_attribution aoa 
     JOIN actions a ON aoa.action_id = a.id
     WHERE aoa.organization_id = org_id AND aoa.is_active = TRUE AND a.is_completed = TRUE)
  ON CONFLICT (organization_id, year)
  DO UPDATE SET
    sdg_targets_count = EXCLUDED.sdg_targets_count,
    actions_count = EXCLUDED.actions_count,
    activities_count = EXCLUDED.activities_count,
    completed_actions_count = EXCLUDED.completed_actions_count,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 4: Create Views for Easy Attribution Queries
-- ============================================================================

-- View for current active target attributions with organization details
CREATE OR REPLACE VIEW v_target_attributions AS
SELECT 
  st.id as target_id,
  st.description as target_description,
  st.user_id,
  st.organization_id,
  o.name as organization_name,
  o.description as organization_description,
  sta.attributed_by,
  sta.attribution_date,
  sta.is_active
FROM sdg_targets st
LEFT JOIN organizations o ON st.organization_id = o.id
LEFT JOIN sdg_target_organization_attribution sta ON st.id = sta.sdg_target_id AND sta.is_active = TRUE;

-- View for current active action attributions (inherited from targets)
CREATE OR REPLACE VIEW v_action_attributions AS
SELECT 
  a.id as action_id,
  a.title as action_title,
  a.user_id,
  st.organization_id,
  o.name as organization_name,
  aoa.attributed_by,
  aoa.attribution_date,
  aoa.is_active,
  'inherited' as attribution_source
FROM actions a
JOIN sdg_targets st ON a.sdg_target_id = st.id
LEFT JOIN organizations o ON st.organization_id = o.id
LEFT JOIN action_organization_attribution aoa ON a.id = aoa.action_id AND aoa.is_active = TRUE;

-- View for current active activity attributions (inherited from targets)
CREATE OR REPLACE VIEW v_activity_attributions AS
SELECT 
  aa.id as activity_id,
  aa.title as activity_title,
  aa.user_id,
  st.organization_id,
  o.name as organization_name,
  aca.attributed_by,
  aca.attribution_date,
  aca.is_active,
  'inherited' as attribution_source
FROM action_activities aa
JOIN actions a ON aa.action_id = a.id
JOIN sdg_targets st ON a.sdg_target_id = st.id
LEFT JOIN organizations o ON st.organization_id = o.id
LEFT JOIN activity_organization_attribution aca ON aa.id = aca.activity_id AND aca.is_active = TRUE;

-- ============================================================================
-- PART 5: Data Migration for Existing Records
-- ============================================================================

-- Migrate existing target attributions to create cascading attributions
DO $$
DECLARE
  target_record RECORD;
BEGIN
  -- For each target that has an organization_id, create the cascading attributions
  FOR target_record IN 
    SELECT id, organization_id, user_id 
    FROM sdg_targets 
    WHERE organization_id IS NOT NULL
  LOOP
    -- Create target attribution record if it doesn't exist
    INSERT INTO sdg_target_organization_attribution (
      sdg_target_id, organization_id, attributed_by, attribution_date, is_active
    ) VALUES (
      target_record.id, target_record.organization_id, target_record.user_id, NOW(), TRUE
    ) ON CONFLICT (sdg_target_id, organization_id) 
    DO UPDATE SET is_active = TRUE, updated_at = NOW();
    
    -- Create action attributions for all actions under this target
    INSERT INTO action_organization_attribution (
      action_id, organization_id, attributed_by, attribution_date, is_active
    )
    SELECT a.id, target_record.organization_id, target_record.user_id, NOW(), TRUE
    FROM actions a
    WHERE a.sdg_target_id = target_record.id
    ON CONFLICT (action_id, organization_id) 
    DO UPDATE SET is_active = TRUE, updated_at = NOW();
    
    -- Create activity attributions for all activities under this target's actions
    INSERT INTO activity_organization_attribution (
      activity_id, organization_id, attributed_by, attribution_date, is_active
    )
    SELECT aa.id, target_record.organization_id, target_record.user_id, NOW(), TRUE
    FROM action_activities aa
    JOIN actions a ON aa.action_id = a.id
    WHERE a.sdg_target_id = target_record.id
    ON CONFLICT (activity_id, organization_id) 
    DO UPDATE SET is_active = TRUE, updated_at = NOW();
    
    -- Recalculate metrics for this organization
    PERFORM recalculate_organization_metrics(target_record.organization_id);
  END LOOP;
END $$;

-- ============================================================================
-- PART 6: Additional Indexes for Performance
-- ============================================================================

-- Additional indexes for the cascading attribution system
CREATE INDEX IF NOT EXISTS idx_sdg_targets_organization_id ON sdg_targets(organization_id) WHERE organization_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_actions_sdg_target_id ON actions(sdg_target_id) WHERE sdg_target_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_action_activities_action_id ON action_activities(action_id);

-- Indexes for attribution views
CREATE INDEX IF NOT EXISTS idx_target_attribution_active_org ON sdg_target_organization_attribution(organization_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_action_attribution_active_org ON action_organization_attribution(organization_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_activity_attribution_active_org ON activity_organization_attribution(organization_id, is_active) WHERE is_active = TRUE;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log migration completion
INSERT INTO migration_log (migration_name, applied_at, description) 
VALUES (
  '02_target_level_cascading_attribution', 
  NOW(), 
  'Target-level cascading attribution system with automatic triggers and views'
) ON CONFLICT (migration_name) DO UPDATE SET 
  applied_at = NOW(), 
  description = EXCLUDED.description;
