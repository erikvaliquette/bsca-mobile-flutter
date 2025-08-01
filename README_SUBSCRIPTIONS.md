# BSCA Mobile Subscription Implementation

This README provides an overview of the in-app purchase and subscription implementation for the BSCA Mobile Flutter application.

## Overview

The subscription system allows users to subscribe to different tiers (FREE, PROFESSIONAL, ENTERPRISE, IMPACT PARTNER) with varying feature sets. The implementation supports both Apple App Store and Google Play Store subscriptions, with unified backend integration to Supabase.

## Implementation Components

### Core Services

- **InAppPurchaseService**: Handles the purchase flow with Apple/Google stores
- **ReceiptValidationService**: Validates purchase receipts from the stores
- **SubscriptionSyncService**: Synchronizes purchases with Supabase backend
- **SubscriptionService**: Interfaces with Supabase to manage subscription data
- **SubscriptionInitializer**: Initializes all subscription services at app startup

### UI Components

- **SubscriptionManagementScreen**: Allows users to view and manage their subscriptions
- **PricingScreen**: Displays available subscription tiers with pricing and feature comparison
- **AccountScreen**: User profile screen with subscription status
- **SubscriptionStatusWidget**: Displays current subscription status with upgrade options
- **SubscriptionUpgradePrompt**: Prompts users to upgrade when accessing premium features
- **LimitedListWidget**: Limits list items based on subscription tier
- **SubscriptionGatedWidget**: Gates content based on subscription tier

## Subscription Tiers

| Tier | Name | Product ID | Price |
|------|------|------------|-------|
| FREE | Free | N/A | Free |
| PROFESSIONAL | Professional | com.bsca.mobile.subscription.professional | CAD$ 9.99/month |
| ENTERPRISE | Enterprise | com.bsca.mobile.subscription.enterprise | CAD$ 29.99/month |
| IMPACT PARTNER | Impact Partner | com.bsca.mobile.subscription.impactpartner | CAD$ 149.99/month |

## Integration Points

1. **App Initialization**: Subscription services are initialized in `main.dart`
2. **Dashboard**: Subscription status widget is shown on the dashboard
3. **Account Screen**: Subscription management is accessible from the account screen
4. **Feature Gating**: Premium features are gated using subscription tier checks

## Setup Requirements

### Apple App Store Setup

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to "My Apps" > [Your App] > "In-App Purchases"
3. Create new subscription products with the following IDs:
   - `com.bsca.mobile.subscription.professional`
   - `com.bsca.mobile.subscription.enterprise`
   - `com.bsca.mobile.subscription.impactpartner`
4. Configure subscription group, pricing, and localized information
5. Add the App-Specific Shared Secret to the `ReceiptValidationService`

### Google Play Console Setup

1. Log in to [Google Play Console](https://play.google.com/console)
2. Navigate to "All applications" > [Your App] > "Monetize" > "Products" > "Subscriptions"
3. Create new subscription products with the following IDs:
   - `com.bsca.mobile.subscription.professional`
   - `com.bsca.mobile.subscription.enterprise`
   - `com.bsca.mobile.subscription.impactpartner`
4. Configure base plan, pricing, and localized information
5. Set up Google Play Developer API access for server-side validation

## Usage Examples

### Checking Subscription Status

```dart
final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
final currentTier = subscriptionProvider.currentServiceLevel;
final isActive = subscriptionProvider.hasActiveSubscription;

if (isActive && currentTier == ServiceLevel.enterprise) {
  // Show enterprise features
}
```

### Gating Features

```dart
SubscriptionGatedWidget(
  requiredTier: ServiceLevel.professional,
  featureDescription: 'Advanced Analytics',
  child: AdvancedAnalyticsWidget(),
  alternativeWidget: BasicAnalyticsWidget(),
)
```

### Limiting List Items

```dart
LimitedListWidget<Connection>(
  items: connections,
  featureDescription: 'network connections',
  tierLimits: {
    ServiceLevel.free: 10,
    ServiceLevel.professional: 50,
    ServiceLevel.enterprise: 100,
    ServiceLevel.impactPartner: 500,
  },
  itemBuilder: (context, connection) => ConnectionListItem(connection: connection),
)
```

### Showing Upgrade Prompt

```dart
SubscriptionUpgradeDialog.show(
  context: context,
  featureDescription: 'Advanced Analytics',
  requiredTier: ServiceLevel.professional,
);
```

## Next Steps

1. Configure products in App Store Connect and Google Play Console
2. Implement server-side receipt validation for enhanced security
3. Test the subscription flow on both iOS and Android devices
4. Integrate subscription checks throughout the app for feature gating
5. Add analytics to track subscription conversions and churn

## Additional Resources

- [Flutter In-App Purchase Documentation](https://pub.dev/packages/in_app_purchase)
- [Apple In-App Purchase Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Detailed Implementation Guide](docs/IN_APP_PURCHASE_IMPLEMENTATION.md)
