#!/bin/bash

# Add the dummy app_links module to the header search paths
echo "Adding dummy app_links module to header search paths..."

# Create a simple modulemap file for our dummy module
cat > Runner/AppLinks/module.modulemap << EOF
module app_links {
  header "app_links.h"
  export *
}
EOF

echo "Created module.modulemap for app_links"

# Update Podfile to include our dummy module
if ! grep -q "header_search_paths" Podfile; then
  echo "Updating Podfile to include header search paths..."
  sed -i '' 's/target '\''Runner'\'' do/target '\''Runner'\'' do\n  pod '\''app_links'\'', :path => '\''Runner\/AppLinks'\''/g' Podfile
fi

# Run pod install to apply changes
echo "Running pod install to apply changes..."
pod install

echo "Fix completed. Please try building your app now."
