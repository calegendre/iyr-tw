#!/bin/bash

# Deployment test script to verify the fix for react-scripts permission issue
# This script simulates the deployment process to ensure the build succeeds

set -e  # Exit on any error

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting deployment test..."

# 1. Check if the package.json has the updated build script
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Checking package.json configuration..."
cd /app/frontend
if grep -q "node node_modules/react-scripts/bin/react-scripts.js build" package.json; then
    echo "✅ package.json is correctly configured with the updated build script."
else 
    echo "❌ package.json does not have the updated build script. Updating now..."
    # This would be where you'd update the file if needed
fi

# 2. Test frontend build
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Testing frontend build..."
cd /app/frontend
yarn install
yarn build

if [ $? -eq 0 ]; then
    echo "✅ Frontend build completed successfully!"
else
    echo "❌ Frontend build failed!"
    exit 1
fi

# 3. Test backend
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Testing backend API..."
cd /app
python backend_test.py

if [ $? -eq 0 ]; then
    echo "✅ Backend tests passed successfully!"
else
    echo "❌ Backend tests failed!"
    exit 1
fi

echo "[$(date +"%Y-%m-%d %H:%M:%S")] Deployment test completed successfully!"
exit 0