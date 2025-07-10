#!/bin/sh

# Create symbolic links to Flutter framework
mkdir -p "${BUILT_PRODUCTS_DIR}/Flutter.framework"
mkdir -p "${BUILT_PRODUCTS_DIR}/XCFrameworkIntermediates/Flutter"

# Find the Flutter framework
FLUTTER_FRAMEWORK=$(find "${PODS_ROOT}/../../flutter/bin/cache/artifacts/engine/ios" -name "Flutter.framework" | head -n 1)

if [ -z "$FLUTTER_FRAMEWORK" ]; then
  echo "Error: Flutter.framework not found"
  exit 1
fi

echo "Found Flutter.framework at $FLUTTER_FRAMEWORK"

# Create symbolic links
ln -sf "$FLUTTER_FRAMEWORK" "${BUILT_PRODUCTS_DIR}/XCFrameworkIntermediates/Flutter/"
ln -sf "$FLUTTER_FRAMEWORK/Flutter" "${BUILT_PRODUCTS_DIR}/Flutter.framework/Flutter"
ln -sf "$FLUTTER_FRAMEWORK/Headers" "${BUILT_PRODUCTS_DIR}/Flutter.framework/Headers"

echo "Created symbolic links to Flutter.framework"
