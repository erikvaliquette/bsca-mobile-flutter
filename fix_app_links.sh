#!/bin/bash

# Clean up Flutter build
echo "Cleaning Flutter build..."
flutter clean

# Remove app_links and reinstall with compatible version
echo "Reinstalling app_links with compatible version..."
flutter pub remove app_links
flutter pub add app_links:^3.4.3

# Clean up iOS build artifacts
echo "Cleaning iOS build artifacts..."
cd ios
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock

# Reinstall pods with proper configuration
echo "Reinstalling pods..."
pod install

echo "Fix completed. Please rebuild your app."
