# Supabase Migration Deployment Guide

## Target-Level Cascading Attribution System

This guide covers deploying the database migrations for the target-level cascading attribution system in the BSCA Mobile Flutter app.

## Migration Overview

The target-level cascading attribution system includes the following migrations:

1. **00_migration_log_table.sql** - Sets up migration tracking
2. **01_sdg_organization_attribution_tables.sql** - Foundation attribution tables (already deployed)
3. **02_target_level_cascading_attribution.sql** - Target-level cascading system

## Pre-Deployment Checklist

- [ ] Backup your Supabase database
- [ ] Verify you have admin access to your Supabase project
- [ ] Confirm all existing attribution data is backed up
- [ ] Test migrations in a development environment first

## Deployment Steps

### Step 1: Deploy Migration Log Table (if not already deployed)

```sql
-- Run this in Supabase SQL Editor
-- File: 00_migration_log_table.sql
```

This creates the `migration_log` table to track which migrations have been applied.

### Step 2: Verify Foundation Tables

Ensure the foundation attribution tables from `01_sdg_organization_attribution_tables.sql` are already deployed. Check for these tables:

- `sdg_target_organization_attribution`
- `action_organization_attribution` 
- `activity_organization_attribution`
- `organization_impact_metrics`

### Step 3: Deploy Target-Level Cascading Attribution

```sql
-- Run this in Supabase SQL Editor
-- File: 02_target_level_cascading_attribution.sql
```

This migration includes:

- **Database Functions**: Automatic cascading attribution functions
- **Triggers**: Automatic cascading when targets, actions, or activities are created/updated
- **Views**: Convenient views for querying attribution data
- **Data Migration**: Migrates existing data to the new cascading system
- **Performance Indexes**: Optimized indexes for the new system

## What This Migration Does

### 1. Automatic Cascading Functions

- `cascade_target_attribution()`: Handles target organization changes and cascades to actions/activities
- `cascade_action_attribution()`: Automatically attributes new actions based on their parent target
- `cascade_activity_attribution()`: Automatically attributes new activities based on their parent target

### 2. Database Triggers

- **Target Updates**: When a target's organization changes, all associated actions and activities update automatically
- **New Actions**: When actions are created under attributed targets, they inherit attribution automatically
- **New Activities**: When activities are created under attributed actions, they inherit attribution automatically

### 3. Convenient Views

- `v_target_attributions`: Shows target attribution with organization details
- `v_action_attributions`: Shows action attribution (inherited from targets)
- `v_activity_attributions`: Shows activity attribution (inherited from targets)

### 4. Data Migration

The migration automatically processes existing data:
- Creates attribution records for existing targets with organization_id
- Cascades attribution to all existing actions and activities
- Recalculates organization impact metrics

## Post-Deployment Verification

### 1. Verify Tables and Functions

```sql
-- Check that functions were created
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE 'cascade_%';

-- Check that triggers were created
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers 
WHERE trigger_name LIKE 'trigger_cascade_%';

-- Check that views were created
SELECT table_name, table_type
FROM information_schema.tables 
WHERE table_name LIKE 'v_%_attributions';
```

### 2. Test Cascading Attribution

```sql
-- Test 1: Update a target's organization and verify cascading
UPDATE sdg_targets 
SET organization_id = 'your-org-id' 
WHERE id = 'test-target-id';

-- Verify actions and activities were attributed
SELECT * FROM v_action_attributions WHERE action_id IN (
  SELECT id FROM actions WHERE sdg_target_id = 'test-target-id'
);

-- Test 2: Create a new action under an attributed target
INSERT INTO actions (title, description, user_id, sdg_target_id) 
VALUES ('Test Action', 'Test Description', 'user-id', 'attributed-target-id');

-- Verify the action was automatically attributed
SELECT * FROM v_action_attributions WHERE action_title = 'Test Action';
```

### 3. Verify Organization Metrics

```sql
-- Check that organization metrics were recalculated
SELECT * FROM organization_impact_metrics 
WHERE organization_id = 'your-org-id';

-- Verify counts match actual attributions
SELECT 
  (SELECT COUNT(*) FROM sdg_target_organization_attribution 
   WHERE organization_id = 'your-org-id' AND is_active = TRUE) as targets,
  (SELECT COUNT(*) FROM action_organization_attribution 
   WHERE organization_id = 'your-org-id' AND is_active = TRUE) as actions,
  (SELECT COUNT(*) FROM activity_organization_attribution 
   WHERE organization_id = 'your-org-id' AND is_active = TRUE) as activities;
```

## Rollback Plan (if needed)

If you need to rollback the migration:

```sql
-- Drop triggers
DROP TRIGGER IF EXISTS trigger_cascade_target_attribution ON sdg_targets;
DROP TRIGGER IF EXISTS trigger_cascade_action_attribution ON actions;
DROP TRIGGER IF EXISTS trigger_cascade_activity_attribution ON action_activities;

-- Drop functions
DROP FUNCTION IF EXISTS cascade_target_attribution();
DROP FUNCTION IF EXISTS cascade_action_attribution();
DROP FUNCTION IF EXISTS cascade_activity_attribution();
DROP FUNCTION IF EXISTS recalculate_organization_metrics(UUID, INTEGER);

-- Drop views
DROP VIEW IF EXISTS v_target_attributions;
DROP VIEW IF EXISTS v_action_attributions;
DROP VIEW IF EXISTS v_activity_attributions;

-- Remove unique constraints (if needed)
ALTER TABLE sdg_target_organization_attribution DROP CONSTRAINT IF EXISTS unique_active_target_attribution;
ALTER TABLE action_organization_attribution DROP CONSTRAINT IF EXISTS unique_active_action_attribution;
ALTER TABLE activity_organization_attribution DROP CONSTRAINT IF EXISTS unique_active_activity_attribution;

-- Update migration log
UPDATE migration_log 
SET description = 'ROLLED BACK: ' || description 
WHERE migration_name = '02_target_level_cascading_attribution';
```

## Performance Considerations

- The migration includes optimized indexes for the new cascading system
- Database triggers run automatically but are lightweight
- Views provide convenient querying without performance impact
- Organization metrics are recalculated efficiently

## Support

If you encounter issues during deployment:

1. Check the Supabase logs for error messages
2. Verify your database permissions
3. Ensure all prerequisite tables exist
4. Test in a development environment first

## Migration Log

After successful deployment, verify the migration was logged:

```sql
SELECT * FROM migration_log 
WHERE migration_name = '02_target_level_cascading_attribution';
```

The migration is complete when you see the log entry with a successful timestamp.
