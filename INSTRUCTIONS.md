# ItsYourRadio Update Package

This archive contains all the files needed to update the ItsYourRadio project and fix the deployment issue with the "Permission denied error Command failed with exit code 127" during frontend build.

## Contents

1. `README.md` - Full instructions and explanation of changes
2. `package.json` - Updated frontend package.json with fixed build script
3. `App.js` - Updated App.js with correct import for react-router-dom
4. `backend_test.py` - Test script to verify backend functionality
5. `test_deployment.sh` - Script to verify the deployment fix works correctly
6. `0001-fix-react-scripts-permission.patch` - Git patch file for easy application

## Quick Start

### Method 1: Apply using Git Patch (Recommended)

1. Clone the repository (if you haven't already):
   ```bash
   git clone https://github.com/calegendre/iyr-tw.git
   cd iyr-tw
   ```

2. Check out the fifth branch:
   ```bash
   git checkout fifth
   ```

3. Create a new branch for your changes:
   ```bash
   git checkout -b fixed-deployment-issue
   ```

4. Apply the patch:
   ```bash
   git apply 0001-fix-react-scripts-permission.patch
   ```

5. Commit and push:
   ```bash
   git add frontend/package.json frontend/src/App.js
   git commit -m "Fix: Resolve react-scripts permission issue for deployment"
   git push origin fixed-deployment-issue
   ```

### Method 2: Manual File Replacement

1. Extract the archive:
   ```bash
   tar -xzf itsyourradio-update.tar.gz
   ```

2. Replace the files in your local repository:
   ```bash
   cp patch_files/package.json /path/to/repo/frontend/
   cp patch_files/App.js /path/to/repo/frontend/src/
   cp patch_files/backend_test.py /path/to/repo/
   ```

3. Test the changes:
   ```bash
   cd /path/to/repo
   bash patch_files/test_deployment.sh
   ```

## Detailed Changes

1. **frontend/package.json**:
   Changed the build script from `"build": "react-scripts build"` to `"build": "node node_modules/react-scripts/bin/react-scripts.js build"` to avoid permission issues.

2. **frontend/src/App.js**:
   Updated import from `import { BrowserRouter, Routes, Route } from "react-router";` to `import { BrowserRouter, Routes, Route } from "react-router-dom";`

## Verification

After applying changes, run the test_deployment.sh script to verify that the build process works correctly.

## Questions?

If you have any questions or issues applying these changes, please contact the development team.