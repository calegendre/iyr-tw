# ItsYourRadio Project Update

This package contains updates to fix the deployment issue with the "itsyourradio" project.

## Changes Made

1. **frontend/package.json**:
   - Modified the build script to use node directly to avoid permission issues:
   ```json
   "build": "node node_modules/react-scripts/bin/react-scripts.js build"
   ```
   - This fixes the "Permission denied error Command failed with exit code 127" during frontend build.

2. **frontend/src/App.js**:
   - Updated import statement from react-router to react-router-dom:
   ```javascript
   import { BrowserRouter, Routes, Route } from "react-router-dom";
   ```

3. **Added backend_test.py**:
   - Comprehensive API testing script created to verify backend functionality.

## Instructions to Push to a New GitHub Branch

1. Clone the repository:
   ```bash
   git clone https://github.com/calegendre/iyr-tw.git
   cd iyr-tw
   ```

2. Create a new branch from the fifth branch:
   ```bash
   git checkout fifth
   git checkout -b fixed-deployment-issue
   ```

3. Apply the changes from this patch:
   - Replace `frontend/package.json` with the updated version
   - Replace `frontend/src/App.js` with the updated version
   - Add `backend_test.py` to the root directory

4. Commit and push the changes:
   ```bash
   git add frontend/package.json frontend/src/App.js backend_test.py
   git commit -m "Fix: Resolve react-scripts permission issue for deployment"
   git push origin fixed-deployment-issue
   ```

5. Create a pull request on GitHub to merge these changes into the desired branch.

## Deployment

After applying these changes, the deployment script should run successfully without the permission error. The key fix is the modified build command in package.json, which ensures react-scripts executes properly during deployment.