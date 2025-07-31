#!/bin/bash

echo "Starting iOS build fix process..."

# Step 1: Clean up iOS build artifacts
echo "Step 1: Cleaning iOS build artifacts..."
rm -rf Pods
rm -rf .symlinks
rm -f Podfile.lock

# Step 2: Update Podfile to fix architecture issues
echo "Step 2: Updating Podfile to fix architecture issues..."
cat > Podfile << 'PODFILE'
# Uncomment this line to define a global platform for your project
platform :ios, '17.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Explicitly add Reachability pod with correct name
  pod 'ReachabilitySwift', '~> 5.0', :modular_headers => true

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix for geolocator_apple 'Flutter/Flutter.h' file not found error
    target.build_configurations.each do |config|
      # Enforce iOS 17.0 deployment target for all pods
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      
      # Fix architecture mismatch for simulator builds
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      
      # Always exclude arm64 for simulator builds to fix architecture mismatch
      if config.build_settings['SDKROOT'] == 'iphonesimulator'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        # Force x86_64 for simulator builds
        config.build_settings['ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      end
      
      # Fix for app_links module not found error
      config.build_settings['HEADER_SEARCH_PATHS'] ||= []
      config.build_settings['HEADER_SEARCH_PATHS'] << "${PODS_ROOT}/Headers/Public"
      config.build_settings['HEADER_SEARCH_PATHS'] << "${PODS_ROOT}/Headers/Public/app_links"
      
      # Fix module import issues
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['DEFINES_MODULE'] = 'YES'
    end
  end
end
PODFILE

# Step 3: Install pods with proper configuration
echo "Step 3: Installing pods..."
pod install

echo "Fix completed. Please try building your app now."
