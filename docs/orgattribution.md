# Organization Attribution for SDG Targets, Actions & Activities

## Overview

This document outlines the strategy for attributing SDG targets, actions, and activities to organizations based on user subscription tiers in the BSCA mobile Flutter app. It covers both the attribution logic and organizational management capabilities.

## Subscription Tier Requirements

### FREE Tier
- **Attribution**: None - all targets, actions, and activities remain personal
- **Organization Features**: Cannot create or manage organizational sustainability content
- **Limitations**: Individual sustainability tracking only

### PROFESSIONAL Tier (CAD$ 9.99/month)
- **Attribution**: Can attribute actions and activities to organizations they're members of
- **Organization Features**: 
  - View organization's sustainability dashboard
  - Contribute to organization's SDG targets through personal actions
  - Access organization's shared SDG targets for personal action creation
- **Limitations**: Cannot create organization-level targets or manage organization content

### ENTERPRISE Tier (CAD$ 29.99/month)
- **Attribution**: Full attribution capabilities for targets, actions, and activities
- **Organization Features**:
  - Create and manage organization-level SDG targets
  - Assign targets to team members
  - View organization-wide sustainability analytics
  - Manage team member contributions
- **Limitations**: Limited to single organization management

### IMPACT PARTNER Tier (CAD$ 149.99/month)
- **Attribution**: Full attribution across multiple organizations
- **Organization Features**:
  - Multi-organization management capabilities
  - Cross-organization sustainability reporting
  - Advanced analytics and benchmarking
  - White-label organization branding
- **Limitations**: None

## Attribution Architecture

### Lessons from Travel Emissions Attribution

The existing travel emissions system provides an excellent blueprint with these proven patterns:
- **Junction Table Architecture**: Robust attribution tracking with audit trails
- **Subscription-Based Gating**: Feature access based on tier (FREE/PROFESSIONAL/ENTERPRISE/IMPACT PARTNER)
- **Organization Selection Logic**: Smart handling of single vs multiple organization scenarios
- **Reattribution System**: Comprehensive handling of attribution changes
- **Integration with Organization Metrics**: Updates organization-wide impact tracking

### Database Schema Design

#### Junction Tables for Attribution Tracking
```sql
-- SDG Target Organization Attribution (similar to trip_organization_attribution)
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

-- Action Organization Attribution
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

-- Activity Organization Attribution
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
```

#### Organization Impact Tracking
```sql
-- Extend organization_carbon_footprint or create new organization_impact_metrics
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
```

#### Enhanced Existing Tables
```sql
-- Add attribution metadata to existing tables
ALTER TABLE sdg_targets ADD COLUMN attribution_type VARCHAR(20) DEFAULT 'personal';
ALTER TABLE actions ADD COLUMN attribution_type VARCHAR(20) DEFAULT 'personal';
ALTER TABLE action_activities ADD COLUMN attribution_type VARCHAR(20) DEFAULT 'personal';

-- Add indexes for performance
CREATE INDEX idx_sdg_target_attribution_active ON sdg_target_organization_attribution(sdg_target_id, is_active);
CREATE INDEX idx_action_attribution_active ON action_organization_attribution(action_id, is_active);
CREATE INDEX idx_activity_attribution_active ON activity_organization_attribution(activity_id, is_active);
```

### Attribution Logic Flow

#### 1. Target Attribution
```
User creates SDG Target:
├── FREE: Always personal (organization_id = NULL)
├── PROFESSIONAL: 
│   ├── Personal target (default)
│   └── Option to link to organization's existing targets
├── ENTERPRISE:
│   ├── Personal target
│   ├── Create organization target (if admin)
│   └── Link to organization target
└── IMPACT PARTNER:
    ├── All ENTERPRISE features
    └── Multi-organization target management
```

#### 2. Action Attribution
```
User creates Action:
├── Target Attribution Check:
│   ├── If target is organizational → Action inherits organization
│   └── If target is personal → User chooses attribution
├── Subscription Check:
│   ├── FREE: Force personal attribution
│   ├── PROFESSIONAL+: Allow organization attribution
│   └── Validate user membership in selected organization
└── Attribution Metadata:
    ├── Record who attributed the action
    ├── When it was attributed
    └── Attribution type (personal/organizational)
```

#### 3. Activity Attribution
```
User creates Activity:
├── Inherit from parent Action (default)
├── ENTERPRISE+: Allow attribution override
├── Validate organization membership
└── Update organization impact metrics
```

## Organization Management Features

### Organization Dashboard (PROFESSIONAL+)

#### SDG Targets Management
- **View Organization Targets**: List all organization-level SDG targets
- **Target Progress Tracking**: Visual progress indicators for each target
- **Member Contributions**: See which members are contributing to each target
- **Target Analytics**: Impact metrics and achievement rates

#### Actions & Activities Overview
- **Organization Actions**: All actions attributed to the organization
- **Team Member Actions**: Actions by organization members
- **Activity Timeline**: Chronological view of all organizational activities
- **Impact Aggregation**: Total organizational impact across all actions

### Administrative Features (ENTERPRISE+)

#### Target Management
- **Create Organization Targets**: Define organization-wide SDG targets
- **Assign Targets**: Assign specific targets to team members
- **Target Templates**: Create reusable target templates
- **Progress Monitoring**: Track progress across all assigned targets

#### Team Management
- **Member Roles**: Assign sustainability roles to team members
- **Attribution Permissions**: Control who can attribute actions to organization
- **Performance Tracking**: Individual and team sustainability performance
- **Reporting**: Generate sustainability reports for stakeholders

#### Analytics & Reporting
- **Impact Dashboard**: Real-time organizational impact metrics
- **Progress Reports**: Automated progress reports for management
- **Benchmarking**: Compare performance against industry standards
- **Export Capabilities**: Export data for external reporting

### Multi-Organization Features (IMPACT PARTNER)

#### Cross-Organization Management
- **Organization Switching**: Easy switching between managed organizations
- **Consolidated Reporting**: Combined reports across all organizations
- **Best Practice Sharing**: Share successful strategies across organizations
- **Benchmarking**: Compare performance between managed organizations

#### Advanced Analytics
- **Portfolio View**: Overview of all managed organizations
- **Trend Analysis**: Long-term sustainability trends
- **ROI Tracking**: Return on investment for sustainability initiatives
- **Predictive Analytics**: Forecast future sustainability performance

## Implementation Strategy

### Phase 1: Foundation (Current Sprint)
1. **Database Schema Updates**: Add attribution fields to existing tables
2. **Subscription Validation**: Implement tier-based feature gating
3. **Basic Attribution UI**: Add organization selection to action/activity creation
4. **Organization Dashboard**: Basic view of attributed content

### Phase 2: Management Features (Next Sprint)
1. **Organization Target Creation**: Allow ENTERPRISE+ users to create org targets
2. **Team Assignment**: Implement target assignment to team members
3. **Progress Tracking**: Real-time progress indicators
4. **Basic Analytics**: Organization-level impact metrics

### Phase 3: Advanced Features (Future Sprint)
1. **Multi-Organization Support**: IMPACT PARTNER tier features
2. **Advanced Analytics**: Comprehensive reporting and benchmarking
3. **White-Label Branding**: Custom organization branding
4. **API Integration**: External system integration capabilities

## Technical Considerations

### Data Privacy & Security
- **Attribution Audit Trail**: Track all attribution changes
- **Permission Validation**: Strict validation of organization membership
- **Data Isolation**: Ensure proper data separation between organizations
- **GDPR Compliance**: Handle personal data in organizational context

### Performance Optimization
- **Caching Strategy**: Cache organization data for better performance
- **Lazy Loading**: Load organizational data on demand
- **Indexing**: Proper database indexing for attribution queries
- **Background Sync**: Sync attribution changes in background

### User Experience
- **Clear Attribution Indicators**: Visual indicators of attribution status
- **Easy Organization Switching**: Seamless switching between personal/org modes
- **Attribution History**: Show history of attribution changes
- **Bulk Operations**: Bulk attribution changes for efficiency

## Success Metrics

### User Engagement
- **Attribution Rate**: Percentage of actions attributed to organizations
- **Organization Dashboard Usage**: Time spent on organization features
- **Team Collaboration**: Number of collaborative sustainability actions
- **Subscription Upgrades**: Conversion from FREE to paid tiers

### Organizational Impact
- **Target Achievement**: Percentage of organization targets achieved
- **Team Participation**: Percentage of team members actively contributing
- **Impact Aggregation**: Total organizational sustainability impact
- **Reporting Usage**: Frequency of report generation and export

## Future Enhancements

### Blockchain Integration
- **Immutable Attribution**: Store attribution records on blockchain
- **Verification System**: Blockchain-based verification of sustainability claims
- **Token Rewards**: Reward system for sustainability achievements
- **Cross-Platform Integration**: Integration with other sustainability platforms

### AI-Powered Features
- **Smart Recommendations**: AI-powered target and action recommendations
- **Predictive Analytics**: Predict sustainability outcomes
- **Automated Reporting**: AI-generated sustainability reports
- **Anomaly Detection**: Detect unusual patterns in sustainability data

---

*This document will be updated as requirements evolve and implementation progresses.*
