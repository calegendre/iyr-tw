#!/bin/bash

# itsyourradio Deployment Script
# For use with HestiaCP, MySQL, and PHP 8.2

# Configuration
DOMAIN="itsyourradio.com"
PUBLIC_HTML_DIR="/home/radio/web/$DOMAIN/public_html"
DEPLOY_DIR="/home/radio/web/$DOMAIN/deploy"
DB_NAME="radio_itsyourradio25"
DB_USER="radio_iyruser25"
DB_PASSWORD="l6Sui@BGY{Kzg7qu"
ADMIN_EMAIL="admin@itsyourradio.com"
ADMIN_PASSWORD="IYR_admin_2025!"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log function
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if user is root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

# Create deployment directory if it doesn't exist
log_message "Step 1: Creating deployment directory..."
mkdir -p $DEPLOY_DIR
mkdir -p $DEPLOY_DIR/frontend
mkdir -p $DEPLOY_DIR/backend

# Create Python virtual environment
log_message "Step 2: Setting up Python virtual environment..."
cd $DEPLOY_DIR
python3 -m venv venv
source venv/bin/activate

# Install backend dependencies
log_message "Step 3: Installing backend dependencies..."
pip install fastapi uvicorn sqlalchemy pymysql python-dotenv python-jose[cryptography] passlib[bcrypt] python-multipart

# Create the backend directory structure
log_message "Step 4: Creating backend directory structure..."
mkdir -p $DEPLOY_DIR/backend/models
mkdir -p $DEPLOY_DIR/backend/schemas
mkdir -p $DEPLOY_DIR/backend/routers
mkdir -p $DEPLOY_DIR/backend/utils

# Create backend .env file
log_message "Step 5: Creating backend .env file..."
cat > $DEPLOY_DIR/backend/.env << EOL
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"
DB_HOST="localhost"
DB_NAME="$DB_NAME"
EOL

# Build the frontend
log_message "Step 6: Setting up frontend..."
cd $DEPLOY_DIR/frontend

# Create package.json
cat > $DEPLOY_DIR/frontend/package.json << EOL
{
  "name": "itsyourradio",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.16.5",
    "@testing-library/react": "^13.4.0",
    "@testing-library/user-event": "^13.5.0",
    "axios": "^1.4.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.11.1",
    "react-scripts": "5.0.1",
    "web-vitals": "^2.1.4"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "devDependencies": {
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.23",
    "tailwindcss": "^3.3.2"
  }
}
EOL

# Create frontend .env file
cat > $DEPLOY_DIR/frontend/.env << EOL
REACT_APP_BACKEND_URL=https://$DOMAIN
EOL

# Install dependencies with yarn
log_message "Step 7: Installing frontend dependencies..."
yarn install

# Setting up supervisor
log_message "Step 8: Setting up supervisor configuration..."
cat > /etc/supervisor/conf.d/itsyourradio.conf << EOL
[program:itsyourradio_backend]
command=$DEPLOY_DIR/venv/bin/uvicorn backend.server:app --host 0.0.0.0 --port 8001
directory=$DEPLOY_DIR
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/itsyourradio_backend.err.log
stdout_logfile=/var/log/supervisor/itsyourradio_backend.out.log
user=radio
environment=PATH="$DEPLOY_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin"
EOL

# Setting up database
log_message "Step 9: Setting up database..."
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" 
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 
mysql -e "FLUSH PRIVILEGES;"

# Copy all backend files to deployment directory
log_message "Step 10: Copying backend files..."
cp -r /app/backend/* $DEPLOY_DIR/backend/

# Copy all frontend files to deployment directory
log_message "Step 11: Copying frontend files..."
cp -r /app/frontend/src $DEPLOY_DIR/frontend/
cp -r /app/frontend/public $DEPLOY_DIR/frontend/

# Build frontend
log_message "Step 12: Building frontend..."
cd $DEPLOY_DIR/frontend
yarn build

# Copy frontend build to public_html
log_message "Step 13: Copying frontend build to public_html..."
rm -rf $PUBLIC_HTML_DIR/*
cp -r $DEPLOY_DIR/frontend/build/* $PUBLIC_HTML_DIR/

# Create PHP proxy for backend API
log_message "Step 14: Creating PHP proxy for backend API..."
mkdir -p $PUBLIC_HTML_DIR/api

cat > $PUBLIC_HTML_DIR/api/index.php << EOL
<?php
/**
 * PHP Proxy for itsyourradio FastAPI Backend
 */

// Backend API URL
\$backendUrl = 'http://localhost:8001';

// Get the current URI
\$requestUri = isset(\$_SERVER['REQUEST_URI']) ? \$_SERVER['REQUEST_URI'] : '';

// Extract the path after /api/
\$path = preg_replace('/^\/api/', '', \$requestUri);

// Full URL to the backend
\$apiUrl = \$backendUrl . '/api' . \$path;

// Get HTTP method, headers and body
\$method = \$_SERVER['REQUEST_METHOD'];
\$requestHeaders = getallheaders();
\$inputJSON = file_get_contents('php://input');

// Set up cURL request
\$ch = curl_init();
curl_setopt(\$ch, CURLOPT_URL, \$apiUrl);
curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt(\$ch, CURLOPT_CUSTOMREQUEST, \$method);

// Set body for POST, PUT, etc.
if (\$method === 'POST' || \$method === 'PUT' || \$method === 'PATCH') {
    curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$inputJSON);
}

// Set headers
\$curlHeaders = [];
foreach (\$requestHeaders as \$key => \$value) {
    if (\$key != 'Host' && \$key != 'Content-Length') {
        \$curlHeaders[] = "\$key: \$value";
    }
}
curl_setopt(\$ch, CURLOPT_HTTPHEADER, \$curlHeaders);

// Execute request
\$response = curl_exec(\$ch);
\$httpCode = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
\$contentType = curl_getinfo(\$ch, CURLINFO_CONTENT_TYPE);
curl_close(\$ch);

// Set response headers
http_response_code(\$httpCode);
if (\$contentType) {
    header("Content-Type: \$contentType");
}

// Output response
echo \$response;
EOL

# Create .htaccess for frontend routing
log_message "Step 15: Creating .htaccess for frontend routing..."
cat > $PUBLIC_HTML_DIR/.htaccess << EOL
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  
  # If not api path or existing file/directory, redirect to index.html
  RewriteCond %{REQUEST_URI} !^/api/
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
EOL

# Restart supervisor
log_message "Step 16: Restarting supervisor..."
supervisorctl reread
supervisorctl update
supervisorctl restart itsyourradio_backend

# Final message
log_message "Deployment complete! The itsyourradio website is now deployed."
log_message "Backend API is accessible at: https://$DOMAIN/api/"
log_message "Frontend is accessible at: https://$DOMAIN/"
log_message "Admin credentials: $ADMIN_EMAIL / $ADMIN_PASSWORD"