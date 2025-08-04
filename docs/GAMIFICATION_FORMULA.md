# BSCA WebApp Gamification Formula

## Overview
The gamification system calculates a user's Impact Score based on four main components, each with its own scoring mechanism. The total score is a weighted sum of these components.

## Score Components and Weights

| Component               | Weight | Max Score | Description |
|-------------------------|--------|-----------|-------------|
| SDG Contribution        | 30%    | 100       | Measures contributions to Sustainable Development Goals |
| Network Engagement      | 25%    | 100       | Tracks professional network growth and engagement |
| Skills & Expertise     | 25%    | 100       | Evaluates certifications and skill endorsements |
| Community Contribution | 20%    | 100       | Measures community involvement and volunteering |

## Component-Specific Formulas

### 1. SDG Contribution (Max 100 points)
- **Base Progress**: Direct mapping of SDG progress (0-100%)
- **Verified Outcomes**: +5 points per verified outcome
- **Consistency Bonus**: +10 points for consistent contribution
- **SDG Champion**: Bonus for high achievement in multiple SDGs

### 2. Network Engagement (Max 100 points)
- **Connections**: `20 * log10(1 + connectionCount/10)` (Max 40 points)
- **Collaborations**: `min(30, collaborationCount * 5)`
- **Network Diversity**: Up to 10 points
- **Engagement Streak**: Up to 20 points

### 3. Skills & Expertise (Max 100 points)
- **Certifications** (Max 40 points):
  - Advanced: 15 points each
  - Intermediate: 10 points each
  - Beginner: 5 points each
- **Endorsements** (Max 40 points):
  - Weighted by endorser expertise (1-3x)
- **Knowledge Sharing**: +20 points for sharing expertise

### 4. Community Contribution (Max 100 points)
- **Volunteer Hours**: `20 * log10(1 + volunteerHours/5)` (Max 35 points)
- **Resources Shared**: `min(25, resourcesShared * 5)`
- **Content Impact**: Based on reach and engagement
- **Consistency Bonus**: Up to 15 points

## Achievement System

### Tiers and Levels
- **SDG Achievement Tiers**: Bronze, Silver, Gold, Platinum
- **Mastery Levels**: Novice, Practitioner, Expert, Authority
- **Community Roles**: Contributor, Educator, Mentor, Advocate

### Milestones
- **Connection Milestones**: 50, 100, 250, 500, 1000
- **Volunteer Hour Milestones**: 10, 25, 50, 100, 250
- **Engagement Streaks**: 7, 14, 30, 60, 90, 180 days
- **Impact Score Milestones**: 50, 100, 250, 500, 1000

## Implementation Notes

1. **Score Capping**: Each component is capped at 100 points
2. **Diminishing Returns**: Used in network and volunteer scoring to prevent gaming
3. **Balanced Contributor**: Bonus for scoring ≥60 in all components
4. **Achievement Unlocks**: Special titles and badges for reaching milestones

## React Native Implementation Tips

1. **State Management**: Use Context API or Redux for global state
2. **Offline Support**: Implement local storage for offline progress tracking
3. **Push Notifications**: For achievement unlocks and milestone celebrations
4. **Performance**: Optimize calculations with memoization
5. **Animations**: Use Reanimated for smooth score animations

## Constants Reference
Key constants used in calculations can be found in the `gamificationConstants.js` file, including:
- `ACHIEVEMENT_TIERS`
- `MASTERY_LEVELS` 
- `COMMUNITY_ROLES`
- `CONNECTION_MILESTONES`
- `VOLUNTEER_HOUR_MILESTONES`
- `STREAK_MILESTONES`
- `IMPACT_SCORE_MILESTONES`
