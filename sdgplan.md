# SDG User Journey Simplification Plan

## Current State Analysis

After reviewing the SDG-related screens and action screens in the BSCA mobile Flutter app, I've identified the following components and user flows:

### Current Components

1. **SdgGoalsScreen** (`lib/screens/sdg/sdg_goals_screen.dart`)
   - Displays a grid of all 17 SDG goals
   - Each goal is clickable and navigates to SdgTargetsScreen
   - Simple UI with SDG icons and names

2. **SdgTargetsScreen** (`lib/screens/sdg/sdg_targets_screen.dart`)
   - Shows targets for a specific SDG goal
   - Displays SDG header with icon, name, context, and impact examples
   - Lists user's targets for the selected SDG
   - Allows adding, editing, and deleting targets
   - Supports organization attribution for targets

3. **ActionsScreen** (`lib/screens/actions/actions_screen.dart`)
   - Shows user's selected SDGs in a grid
   - Lists all SDGs with descriptions
   - Allows navigation to specific SDG details
   - Contains complex UI with multiple sections
   - Uses mock data for user's selected SDGs (hardcoded [13, 17, 12])
   - Has commented-out code for Supabase integration with `user_sdgs` table

4. **AddActionScreen** (`lib/screens/actions/add_action_screen.dart`)
   - Very basic placeholder screen
   - Shows SDG ID and a test UI
   - Not fully implemented

### Current User Flow Issues

1. **Redundancy**: There's overlap between SdgGoalsScreen and ActionsScreen, both showing SDG goals
2. **Disconnected Experiences**: The SDG goals/targets flow and the actions flow are not well integrated
3. **Incomplete Implementation**: AddActionScreen is just a placeholder
4. **Unclear User Journey**: No clear path from selecting SDGs to creating targets to tracking actions
5. **Data Persistence**: User's selected SDGs are hardcoded rather than saved to Supabase

## Proposed Solution

I propose a simplified, integrated user journey that connects SDG selection, target management, and action tracking in a cohesive flow:

### 1. Consolidated Entry Point

Create a single entry point through the **SdgGoalsScreen** that serves as the hub for all SDG-related activities:
- Display all 17 SDGs with visual indicators for user-selected goals
- Allow users to select/deselect SDGs of interest (saved to `user_sdgs` table)
- Provide clear navigation to targets and actions for each SDG

### 2. Integrated User Flow

1. **Select SDGs** (SdgGoalsScreen)
   - User browses all 17 SDGs
   - User selects SDGs of interest (saved to Supabase `user_sdgs` table)
   - Visual indicators show which SDGs are selected

2. **Manage Targets** (SdgTargetsScreen)
   - User clicks on an SDG to view/manage targets
   - User can create personal or organization-specific targets
   - Targets are saved to Supabase

3. **Track Actions** (Enhanced ActionScreen)
   - From the targets screen, user can create actions linked to specific targets
   - Actions have progress tracking, measurement data, and completion status
   - Clear connection between SDGs, targets, and concrete actions

### 3. Technical Implementation Plan

1. **Enhance SdgGoalsScreen**:
   - Add selection functionality to save user's SDG preferences
   - Implement Supabase integration with `user_sdgs` table
   - Add visual indicators for selected SDGs
   - Improve navigation options (manage targets, view actions)

2. **Keep SdgTargetsScreen** largely as-is, with minor improvements:
   - Add direct navigation to create actions for specific targets
   - Enhance target progress visualization
   - Improve organization selection UI

3. **Refactor ActionsScreen**:
   - Remove redundant SDG selection functionality
   - Focus on displaying actions grouped by SDG/target
   - Improve action tracking and progress visualization
   - Ensure proper integration with targets

4. **Rebuild AddActionScreen**:
   - Create a proper form for adding actions
   - Link actions to specific SDG targets
   - Add measurement data, progress tracking, and completion status
   - Support organization attribution

5. **Database Integration**:
   - Ensure proper schema and relationships between:
     - `user_sdgs` (user's selected SDGs)
     - `sdg_targets` (targets for each SDG)
     - `actions` (concrete actions linked to targets)

## Data Model Relationships

```
User (auth.users)
 ├── user_sdgs (Table: user_sdgs - Many-to-Many: Users to SDGs)
 │    └── SDG Goals (17 predefined goals)
 │         └── sdg_targets (Table: sdg_targets - One-to-Many: SDG to Targets)
 │              ├── sdg_target_data (Table: sdg_target_data - Time-series measurement data for targets)
 │              └── actions (Table: user_actions - One-to-Many: Target to Actions)
 └── organizations (Table: organizations)
      └── organization_sdg_targets (Table: sdg_targets with organization_id - Organization-specific targets)
           ├── organization_target_data (Table: sdg_target_data with targets linked to organizations)
           └── organization_actions (Table: user_actions with organization_id - Organization-specific actions)
```

## UI/UX Improvements

1. **Consistent Design Language**:
   - Use consistent SDG color coding throughout the app
   - Maintain visual hierarchy: SDGs → Targets → Actions
   - Use clear iconography and visual indicators

2. **Progressive Disclosure**:
   - Start with high-level SDG selection
   - Drill down to specific targets
   - Further drill down to concrete actions

3. **Contextual Help**:
   - Provide information about each SDG and its significance
   - Offer examples of targets and actions for inspiration
   - Include progress visualization at each level

## Next Steps

1. Update SdgGoalsScreen to save user selections to Supabase
2. Enhance navigation between screens to create a cohesive flow
3. Rebuild AddActionScreen with proper target integration
4. Refactor ActionsScreen to focus on action tracking
5. Implement proper data synchronization between all components
6. Modify Supabase tables to better support personal and organization actions:
   - Leverage existing `user_actions` table structure which already has:
     - Proper indexing on `user_id`, `organization_id`, `sdg_id`, `sdg_target_id`, `is_completed`, and `due_date`
     - Foreign key relationships to `organizations`, `sdg_targets`, and `auth.users`
     - Progress tracking with validation (0.00-1.00 range)
     - Priority field with check constraint (low, medium, high)
     - Metadata JSON field for extensibility
   - Add RLS policies to `user_actions` table to control visibility based on user and organization membership
   - Use the existing `category` field (currently defaulting to 'personal') to distinguish action types:
     - Expand the check constraint to include additional categories like 'organization', 'team', etc.
   - Create a new `action_collaborators` junction table to support multiple users collaborating on organization actions
   - Add `visibility` enum field to `user_actions` (private, organization, public) to control who can see actions
   - Ensure `sdg_targets` table has similar organization attribution controls
   - Add triggers to automatically update organization statistics when actions are created/updated
   - Integrate the existing `sdg_target_data` table for time-series measurement tracking:
     - Add organization-specific views or RLS policies for `sdg_target_data`
     - Create UI components to visualize target progress over time using this data
     - Implement data validation to ensure baseline < target values
     - Add aggregation functions to calculate progress percentages from actual vs. target values

This plan will create a more intuitive, streamlined user experience while maintaining the flexibility of the current architecture and leveraging the existing components. The database modifications will ensure proper separation between personal and organization actions while enabling collaboration and appropriate visibility controls.
