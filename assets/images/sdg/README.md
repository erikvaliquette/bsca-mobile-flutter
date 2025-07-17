# UN Sustainable Development Goals (SDG) Icons

This directory should contain the official UN SDG icons for offline use in the app.

## Icon Naming Convention

Each icon should be named according to its SDG number with the following format:
- `sdg1.png` for SDG 1 (No Poverty)
- `sdg2.png` for SDG 2 (Zero Hunger)
- And so on...

## How to Download Official UN SDG Icons

1. Visit the official UN SDG website: https://www.un.org/sustainabledevelopment/news/communications-material/
2. Download the official SDG icons package
3. Extract the icons and rename them according to the convention above
4. Place them in this directory

## Current Implementation

The app currently uses the following fallback mechanism for SDG icons:
1. Cached network images from Supabase URL
2. Local asset images from this directory (if available)
3. Material icons as a last resort fallback

By placing the official icons in this directory, you'll improve app performance and reduce network requests.
