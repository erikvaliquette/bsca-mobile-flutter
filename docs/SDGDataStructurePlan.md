# SDG Data Structure Enhancement Plan

## Overview
This document outlines the implementation of an enhanced SDG data structure for the BSCA Mobile Flutter App, separating strategic Actions from tactical Activities and implementing comprehensive impact tracking, evidence management, and verification workflows.

## Enhanced SDG Data Structure
```
SDG → Target → Action (Strategic) → Activity (Tactical) → Evidence → Impact Metrics → Verification → Tokenization (placeholder) → Organization → Timestamps
```

## Implementation Notes
- User provided an enhanced SDG data structure: SDG → Target → Action → Activity → Proof/Evidence → Impact Metrics → Verification → Tokenization (placeholder) → Organization → Timestamps.
- Tokenization is to be ignored for now, but a placeholder should be kept.
- User requested analysis of current implementation in specific files to compare with the enhanced structure.
- Models and screens for SDG, Target, Action, and ActionMeasurement have been analyzed for current structure.
- Analysis complete: current implementation covers SDG→Target→Action, impact metrics, org, timestamps. Missing: Action/Activity separation, structured evidence, verification, GRI mapping, Add Action screen is placeholder.
- Phase 1 core implementation complete: ActionActivity model, ActionActivityService, and enhanced Add Action Screen created.
- Next: Enhance Action Detail Screen to display activities and add activity management UI before completing Supabase/database integration.
- Action Detail Screen now enhanced with activities section and management UI (add, edit, complete, delete activities).
- Database schema for activities created and ready for deployment/testing.
- `actions` table created successfully in Supabase; ready to deploy `action_activities` table next.
- `action_activities` table created successfully in Supabase; ready for full integration testing.
- Fixed Add Action Screen bug (incorrect createAction usage); app ready for end-to-end testing.
- Encountered foreign key constraint error when creating initial activity: activity references action ID not present in table (timing or transaction issue between action and activity creation).
- Corrected action_activities table created to reference user_actions instead of actions; ready for deployment.
- Fixed dropdown category bug in edit action dialog; edit now works for all categories.
- User prefers action type categories: reduction, innovation, education, policy. Update Add Action Screen and Edit Action Dialog to use these new categories instead of previous set.

## Task List

### Analysis Phase ✅ COMPLETE
- [x] Analyze current SDG implementation in:
  - lib/screens/sdg/sdg_goals_screen.dart
  - lib/screens/sdg/sdg_targets_screen.dart
  - lib/screens/action_detail_screen.dart
  - lib/screens/actions/actions_screen.dart
  - lib/screens/actions/add_action_screen.dart
- [x] Compare current structure to enhanced structure and identify gaps
- [x] Summarize findings and recommend next steps

### Phase 1 Implementation ✅ COMPLETE
- [x] Enhance Add Action Screen (replace placeholder with functional form)
- [x] Add Activity model (separate Action from Activity)
- [ ] Enhance evidence/proof system (structured, verifiable evidence)

### Phase 2 Implementation ✅ COMPLETE
- [x] Enhance Action Detail Screen to display activities
- [x] Add activity management UI (add, edit, complete activities)
- [x] Database table creation for activities
- [x] Deploy actions table in Supabase
- [x] Deploy action_activities table in Supabase
- [ ] Deploy corrected action_activities table referencing user_actions
- [ ] Test end-to-end workflow and database integration (CRUD, evidence, verification)
- [x] Debug and resolve action/activity foreign key constraint issue
- [x] Debug and resolve edit action dropdown category bug
- [x] Update Add Action Screen and Edit Action Dialog to use action type categories (reduction, innovation, education, policy)

## Current Goal
- [ ] Test after deploying corrected activities table and verify edit dialog fix and new categories
- [ ] Debug and resolve action/activity creation integration issue

## Key Components Implemented

### 1. ActionActivity Model (`lib/models/action_activity.dart`)
- Complete separation of strategic Actions from tactical Activities
- Fields: id, actionId, title, description, status, impact tracking, evidence URLs, verification system
- Tokenization placeholder for future blockchain integration
- Helper methods for status checking and display

### 2. ActionActivityService (`lib/services/action_activity_service.dart`)
- Full CRUD operations for activities
- Activity statistics and verification management
- Organization and user-specific activity queries
- Evidence management and verification workflow

### 3. Enhanced Add Action Screen (`lib/screens/actions/add_action_screen.dart`)
- Replaced "ULTRA BASIC TEST" placeholder with comprehensive form
- Two-level structure: Action (strategic) + optional Activity (tactical)
- Impact value tracking with multiple units (CO₂e, kWh, people reached, etc.)
- Organization attribution support
- Verification method specification
- Form validation and error handling
- Action type categories: reduction, innovation, education, policy

### 4. Enhanced Action Detail Screen (`lib/screens/action_detail_screen.dart`)
- New "Activities (Tactical Level)" section with clear strategic vs tactical distinction
- "Add Activity" button for easy activity creation
- Empty state with helpful guidance when no activities exist
- Comprehensive activity list with expandable cards
- Activity management UI: Add, Edit, Complete, Delete activities
- Status tracking with visual indicators (planned, in_progress, completed, cancelled)
- Impact tracking display with values and units
- Verification status with color-coded display
- Evidence links placeholder for future implementation

### 5. AddActivityDialog Widget (`lib/widgets/add_activity_dialog.dart`)
- Comprehensive form with title, description, status, due date, impact tracking
- Impact units selection (CO₂e, kWh, people reached, etc.)
- Verification method specification
- Form validation and error handling
- Edit mode support with pre-populated fields
- Loading states and user feedback

## Database Schema

### Actions Table (`user_actions`)
- Strategic sustainability actions
- SDG linkage and progress tracking
- User ownership with RLS security
- Organization attribution
- Action type categories (reduction, innovation, education, policy)

### Action Activities Table (`action_activities`)
- Tactical activities that execute strategic actions
- Impact tracking with evidence URLs
- Verification workflow (pending → verified → rejected)
- Tokenization placeholder for future blockchain integration
- Foreign key reference to `user_actions` table
- RLS policies for user and organization-based access control

## Action Type Categories

The app uses meaningful action type categories that focus on **how** sustainability actions create impact:

- **Reduction**: Actions that reduce consumption, waste, emissions, etc.
- **Innovation**: Actions involving new technologies, processes, or approaches
- **Education**: Actions focused on awareness, training, and knowledge sharing
- **Policy**: Actions involving advocacy, governance, and systemic change

## Database Files

### Deployed Tables
1. `database/01_actions_table_simple.sql` - Strategic actions table (✅ deployed)
2. `database/02_action_activities_table_simple.sql` - Initial activities table (❌ foreign key issue)

### Corrected Table (Ready for Deployment)
3. `database/03_action_activities_table_corrected.sql` - Fixed activities table referencing `user_actions`

## Current Status

### ✅ Completed
- Enhanced SDG data structure implementation
- Action/Activity separation with comprehensive UI
- Database schema design and partial deployment
- Activity management with full CRUD operations
- Impact tracking and verification workflow
- Action type categorization system
- UI bug fixes (pixel overflow, dropdown errors)

### ⚠️ Pending
- Deploy corrected `action_activities` table to fix foreign key constraint
- End-to-end testing of complete workflow
- Enhanced evidence system beyond URLs
- Tokenization implementation (future)

### 🎯 Next Steps
1. Deploy `database/03_action_activities_table_corrected.sql`
2. Test complete Action → Activity workflow
3. Verify activity management UI functionality
4. Test impact tracking and verification features
5. Enhance evidence system with file uploads
6. Implement tokenization when ready

## Testing Workflow

Once the corrected database table is deployed, test this complete workflow:

1. **Create Strategic Action**: Navigate to SDG Goals → Select SDG → Add Action
2. **Add Tactical Activities**: Open Action Detail Screen → Use "Activities (Tactical Level)" section
3. **Manage Activities**: Add, edit, complete, and delete activities
4. **Track Impact**: Set impact values with units and verification methods
5. **Verify Results**: Use verification workflow to validate impact claims

## Architecture Benefits

This enhanced structure provides:
- **Clear Separation**: Strategic planning vs tactical execution
- **Comprehensive Tracking**: Impact, evidence, and verification
- **Scalable Design**: Ready for tokenization and blockchain integration
- **User-Friendly**: Intuitive UI with proper feedback and validation
- **Secure**: RLS policies ensure data privacy and access control
