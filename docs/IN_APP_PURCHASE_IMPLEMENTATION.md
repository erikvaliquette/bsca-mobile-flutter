# In-App Purchase Implementation for BSCA Mobile

This document outlines the implementation of in-app purchases and subscription management in the BSCA Mobile Flutter application.

## Overview

The subscription system allows users to subscribe to different tiers (FREE, PROFESSIONAL, ENTERPRISE, IMPACT PARTNER) with varying feature sets. The implementation supports both Apple App Store and Google Play Store subscriptions, with a unified backend integration to Supabase.

## Implementation Components

### 1. Core Services

- **SubscriptionService**: Interfaces with Supabase to manage subscription data
- **InAppPurchaseService**: Handles the purchase flow with Apple/Google stores
- **ReceiptValidationService**: Validates purchase receipts from the stores
- **SubscriptionSyncService**: Synchronizes purchases with Supabase backend

### 2. Data Models

- **SubscriptionModel**: Represents subscription data from Supabase, including status and expiration

### 3. State Management

- **SubscriptionProvider**: Manages subscription state throughout the app using the Provider pattern

### 4. User Interface

- **SubscriptionManagementScreen**: Allows users to view and manage their subscriptions
- **PricingScreen**: Displays available subscription tiers with pricing and feature comparison
- **Access Control Widgets**: Gate features based on subscription level
  - `AccessControlWidget`
  - `LimitedListWidget`
  - `SubscriptionGatedButton`
  - `SubscriptionStatusWidget`
- **UpgradePromptWidget**: Encourages users to upgrade with feature comparisons

## Subscription Tiers

| Tier | Name | Price | Description |
|------|------|-------|-------------|
| FREE | Free | Free | Basic tier for individual users |
| PROFESSIONAL | Professional | CAD$ 9.99/month | For business professionals and consultants |
| ENTERPRISE | Enterprise | CAD$ 29.99/month | For organizations and teams |
| IMPACT PARTNER | Impact Partner | CAD$ 149.99/month | Premium tier for sustainability leaders and partners |



## Feature Matrix

| Feature | FREE | PROFESSIONAL | ENTERPRISE | IMPACT PARTNER |
|---------|------|-------------|------------|----------------|
| Connections | 10 | Unlimited | Unlimited | Unlimited |
| Business Trip Attribution | ❌ | ✅ | ✅ | ✅ |
| Advanced Analytics | ❌ | ❌ | ✅ | ✅ |
| Team Management | ❌ | ❌ | ✅ | ✅ |
| Organization Admin | ❌ | ❌ | ❌ | ✅ |
| Custom Branding | ❌ | ❌ | ❌ | ✅ |
| API Access | ❌ | ❌ | ❌ | ✅ |
| Priority Support | ❌ | ❌ | ✅ | ✅ |

## Implementation Status

### Completed
- ✅ Core subscription data model and service
- ✅ Subscription provider for state management
- ✅ In-app purchase service integration
- ✅ Receipt validation service
- ✅ Subscription synchronization with Supabase
- ✅ Subscription management UI
- ✅ Pricing screen
- ✅ Access control widgets

### Pending
- ❌ App Store Connect product configuration
- ❌ Google Play Console product configuration
- ❌ Testing on iOS and Android devices
- ❌ Server-side receipt validation (currently client-side only)
- ❌ Integration with existing features throughout the app

## Setup Instructions for App Store and Google Play

### Apple App Store Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to "My Apps" > [Your App] > "In-App Purchases"
3. Create new subscription products with the following IDs:
   - `com.bsca.mobile.subscription.professional`
   - `com.bsca.mobile.subscription.enterprise`
   - `com.bsca.mobile.subscription.impactpartner`
4. For each product, configure:
   - Subscription Group
   - Pricing and Duration
   - Localized Information (name, description)
   - Review Information
5. Add the App-Specific Shared Secret to the `ReceiptValidationService`

### Google Play Console Setup

1. Log in to [Google Play Console](https://play.google.com/console)
2. Navigate to "All applications" > [Your App] > "Monetize" > "Products" > "Subscriptions"
3. Create new subscription products with the following IDs:
   - `com.bsca.mobile.subscription.professional`
   - `com.bsca.mobile.subscription.enterprise`
   - `com.bsca.mobile.subscription.impactpartner`
4. For each product, configure:
   - Base Plan (pricing and billing period)
   - Offers (if applicable)
   - Localized Information (title, description)
5. Set up Google Play Developer API access for server-side validation

## Testing

### Sandbox Testing (iOS)

1. Create a sandbox tester account in App Store Connect
2. Log out of the App Store on your test device
3. Run the app and attempt to make a purchase
4. The sandbox environment will be used automatically

### Testing Track (Android)

1. Create a testing track in Google Play Console
2. Add test users to the track
3. Publish the app to the testing track
4. Install the app from the testing track URL
5. Make test purchases (you won't be charged)

## Next Steps

1. Configure products in App Store Connect and Google Play Console
2. Implement server-side receipt validation for enhanced security
3. Test the subscription flow on both iOS and Android devices
4. Integrate subscription checks throughout the app for feature gating
5. Add analytics to track subscription conversions and churn

## Resources

- [Flutter In-App Purchase Documentation](https://pub.dev/packages/in_app_purchase)
- [Apple In-App Purchase Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
