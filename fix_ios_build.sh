#!/bin/bash

echo "Starting iOS build fix process..."

# Step 1: Clean Flutter build
echo "Step 1: Cleaning Flutter build..."
flutter clean

# Step 2: Get packages
echo "Step 2: Getting Flutter packages..."
flutter pub get

# Step 3: Clean iOS build artifacts
echo "Step 3: Cleaning iOS build artifacts..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock

# Step 4: Install pods with proper configuration
echo "Step 4: Installing pods..."
pod install

# Step 5: Return to project root
cd ..

echo "Fix completed. Please try building your app now."
