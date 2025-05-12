#!/bin/bash

# itsyourradio Build Script
# This script prepares the application for deployment

echo "========================================"
echo "    itsyourradio Deployment Builder     "
echo "========================================"

# Check for required dependencies
echo "Checking dependencies..."
command -v node >/dev/null 2>&1 || { echo "Node.js is required but not installed. Aborting."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed. Aborting."; exit 1; }

# Create deployment directory
echo "Creating deployment directory..."
mkdir -p ./deployment

# Build frontend
echo "Building frontend..."
cd frontend
npm install
npm run build
cd ..

# Copy backend files
echo "Copying backend files..."
cp -r backend deployment/

# Copy frontend build files
echo "Copying frontend build files..."
cp -r frontend/build/* deployment/
cp -r frontend/build/.* deployment/ 2>/dev/null || :

# Create required directories
echo "Creating required directories..."
mkdir -p deployment/uploads/{profile_images,cover_images,album_art,podcast_covers}
mkdir -p deployment/station/{music,podcasts}

# Copy deployment documentation
echo "Copying documentation..."
cp DEPLOYMENT_INSTRUCTIONS.md deployment/
cp frontend/public/README-ASSETS.md deployment/

echo "========================================"
echo "Build complete! Deployment package is ready in the 'deployment' directory."
echo "Upload all files from the deployment directory to your server's public_html folder."
echo "Follow the instructions in DEPLOYMENT_INSTRUCTIONS.md to complete the setup."
echo "========================================"
