#!/bin/bash

# Qibla AR Finder - Package Cleanup Script
# This script removes all unnecessary files after package conversion

set -e

echo "🕌 Qibla AR Finder - Package Cleanup"
echo "====================================="
echo ""
echo "This will delete app-specific files and prepare the package for distribution."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Aborted."
    exit 1
fi

echo ""
echo "🗑️  Removing unnecessary files..."

# Delete app-specific files
echo "  - Removing app main.dart..."
rm -f lib/main.dart

echo "  - Removing splash page..."
rm -f lib/presentation/pages/splash_page.dart

# Delete platform folders from root
echo "  - Removing root android/ folder..."
rm -rf android/

echo "  - Removing root ios/ folder..."
rm -rf ios/

# Delete build outputs
echo "  - Removing build outputs..."
rm -rf build/
rm -rf .dart_tool/
rm -f .flutter-plugins-dependencies

# Delete package preparation files
echo "  - Removing package preparation files..."
rm -rf package_files/
rm -f PACKAGE_EXAMPLE_MAIN.dart
rm -f package_lib_qibla_ar_finder.dart
rm -f package_pubspec.yaml

# Delete scripts
echo "  - Removing old scripts..."
rm -f create_package.sh
rm -f copy_package_files.sh
rm -f fix_package_imports.sh
rm -f install_android.sh
rm -f setup_kaaba_model.sh

# Delete unnecessary documentation
echo "  - Removing old documentation..."
rm -f PROJECT_GUIDE.md

# Delete IDE files
echo "  - Removing IDE files..."
rm -f qibla_finder.iml
rm -f .metadata

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📦 Your package is now ready for distribution."
echo ""
echo "Next steps:"
echo "1. Review PACKAGE_CONVERSION_SUMMARY.md"
echo "2. Test the package: cd example && flutter run"
echo "3. Update repository URLs in pubspec.yaml and README.md"
echo "4. Initialize git and push to GitHub"
echo "5. Delete PACKAGE_CONVERSION_SUMMARY.md and this script"
echo ""
echo "To delete the summary and this script:"
echo "  rm PACKAGE_CONVERSION_SUMMARY.md cleanup_package.sh"
echo ""
