#!/bin/bash

# itsyourradio Deployment Script
# Customized for itsyourradio.com

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="itsyourradio.com"
PUBLIC_HTML="/home/radio/web/itsyourradio.com/public_html"
DB_NAME="radio_itsyourradio25"
DB_USER="radio_iyruser25"
DB_PASSWORD="l6Sui@BGY{Kzg7qu"
DB_HOST="localhost"
USER="radio"

# Generate a secure random key for JWT
SECRET_KEY=$(openssl rand -hex 32)

# Error handling function
handle_error() {
    echo -e "${RED}ERROR: $1${NC}"
    echo -e "${YELLOW}The deployment script encountered an error and will exit.${NC}"
    echo -e "${YELLOW}Please fix the issue and run the script again.${NC}"
    exit 1
}

# Success function
success_step() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Warn function
warn() {
    echo -e "${YELLOW}! $1${NC}"
}

# Print header
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}         itsyourradio Deployment Script               ${NC}"
echo -e "${BLUE}=======================================================${NC}"

# Check if already root, if not try to get sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}This script requires root privileges.${NC}"
    echo -e "${YELLOW}Attempting to run with sudo...${NC}"
    
    # Check if sudo is available
    if command -v sudo &> /dev/null; then
        exec sudo "$0" "$@" || handle_error "Failed to execute with sudo. Please run this script as root or with sudo privileges."
        exit 0
    else
        handle_error "This script requires root privileges but sudo is not available. Please run as root."
    fi
fi

# Step 1: Check and install prerequisites
echo -e "\n${BLUE}Step 1: Checking and installing prerequisites...${NC}"

# Check and install required packages
check_install_package() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}Installing $2...${NC}"
        apt-get install -y $2 || handle_error "Failed to install $2"
    else
        echo -e "${GREEN}✓ $2 is already installed${NC}"
    fi
}

# Update package lists
apt-get update || handle_error "Failed to update package lists"

# Check for Python and pip
check_install_package python3 python3
check_install_package pip3 python3-pip
check_install_package supervisorctl supervisor
check_install_package openssl openssl

# Install required Python packages
echo -e "${YELLOW}Installing Python dependencies...${NC}"
pip3 install fastapi uvicorn sqlalchemy pymysql python-jose[cryptography] passlib[bcrypt] python-multipart python-dotenv || handle_error "Failed to install Python dependencies"
success_step "All prerequisites installed successfully"

# Step 2: Verify and prepare directory structure
echo -e "\n${BLUE}Step 2: Preparing directory structure...${NC}"

# Check if public_html directory exists
if [ ! -d "$PUBLIC_HTML" ]; then
    handle_error "Public HTML directory $PUBLIC_HTML does not exist"
fi

# Ask before cleaning public_html if it has content
if [ "$(ls -A "$PUBLIC_HTML" 2>/dev/null)" ]; then
    echo -e "${YELLOW}The public_html directory is not empty.${NC}"
    read -p "Do you want to clean it before deployment? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cleaning public_html directory...${NC}"
        rm -rf "$PUBLIC_HTML"/* "$PUBLIC_HTML"/.[^.]* 2>/dev/null
    else
        warn "Proceeding without cleaning. This might lead to file conflicts."
    fi
fi

# Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p "$PUBLIC_HTML/backend"
mkdir -p "$PUBLIC_HTML/uploads/"{profile_images,cover_images,album_art,podcast_covers}
mkdir -p "$PUBLIC_HTML/station/"{music,podcasts}
mkdir -p "$PUBLIC_HTML/logs"
mkdir -p "$PUBLIC_HTML/icons"

# Set proper permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
chmod -R 755 "$PUBLIC_HTML/uploads"
chmod -R 755 "$PUBLIC_HTML/station"
chown -R "$USER":"$USER" "$PUBLIC_HTML"
success_step "Directory structure prepared successfully"

# Step 3: Build and deploy the application
echo -e "\n${BLUE}Step 3: Building and deploying the application...${NC}"

# Check if we're in the app directory
if [ -f "/app/build.sh" ]; then
    echo -e "${YELLOW}Building application package...${NC}"
    cd /app || handle_error "Failed to change to app directory"
    chmod +x build.sh
    ./build.sh || handle_error "Failed to build the application"
    
    echo -e "${YELLOW}Copying files to public_html...${NC}"
    cp -r /app/deployment/* "$PUBLIC_HTML"/ || handle_error "Failed to copy files to public_html"
    # Copy hidden files but ignore errors if there are none
    cp -r /app/deployment/.* "$PUBLIC_HTML"/ 2>/dev/null || true
    
    # Verify key files exist
    if [ ! -f "$PUBLIC_HTML/index.html" ]; then
        handle_error "Frontend files were not copied correctly - index.html is missing"
    fi
    
    if [ ! -f "$PUBLIC_HTML/backend/server.py" ]; then
        handle_error "Backend files were not copied correctly - server.py is missing"
    fi
    
    success_step "Application files deployed successfully"
else
    handle_error "build.sh not found in /app directory. Are you running this script from the correct location?"
fi

# Step 4: Configure the environment
echo -e "\n${BLUE}Step 4: Configuring the environment...${NC}"

# Create .env file for backend
echo -e "${YELLOW}Creating backend environment file...${NC}"
cat > "$PUBLIC_HTML/backend/.env" << EOL
DATABASE_URL=mysql+pymysql://$DB_USER:$DB_PASSWORD@$DB_HOST/$DB_NAME
SECRET_KEY=$SECRET_KEY
WEBSITE_URL=https://$DOMAIN
EOL

# Verify .env file
if [ ! -f "$PUBLIC_HTML/backend/.env" ]; then
    handle_error "Failed to create .env file"
fi

# Create frontend environment file if needed
if [ -d "$PUBLIC_HTML/src" ]; then
    echo -e "${YELLOW}Creating frontend environment file...${NC}"
    cat > "$PUBLIC_HTML/.env" << EOL
REACT_APP_BACKEND_URL=https://$DOMAIN/api
EOL
fi

success_step "Environment configured successfully"

# Step 5: Set up database and initialize application
echo -e "\n${BLUE}Step 5: Setting up database...${NC}"

# Check if MySQL/MariaDB is installed
if ! command -v mysql &> /dev/null; then
    warn "MySQL client not found. Database initialization may fail."
    warn "Make sure MySQL/MariaDB is installed and accessible."
else
    # Test database connection
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DB_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
    else
        warn "Could not connect to the database. Please verify your credentials."
        read -p "Do you want to continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            handle_error "Database connection failed. Please check your database credentials."
        fi
    fi
fi

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
cd "$PUBLIC_HTML/backend" || handle_error "Failed to change to backend directory"
python3 -c "from utils.db_init import init_db; init_db()" || handle_error "Failed to initialize database"
success_step "Database initialized successfully"

# Step 6: Set up supervisor for the backend service
echo -e "\n${BLUE}Step 6: Setting up supervisor...${NC}"

echo -e "${YELLOW}Creating supervisor configuration...${NC}"
cat > /etc/supervisor/conf.d/itsyourradio-backend.conf << EOL
[program:itsyourradio-backend]
directory=$PUBLIC_HTML/backend
command=uvicorn server:app --host 0.0.0.0 --port 8001
autostart=true
autorestart=true
user=$USER
redirect_stderr=true
stdout_logfile=$PUBLIC_HTML/logs/supervisor.log
EOL

# Update supervisor
echo -e "${YELLOW}Updating supervisor...${NC}"
supervisorctl reread || handle_error "Failed to update supervisor configuration"
supervisorctl update || handle_error "Failed to update supervisor"
supervisorctl restart itsyourradio-backend || warn "Failed to restart backend service. It might be started later."
success_step "Supervisor configured successfully"

# Step 7: Configure proxy for HestiaCP
echo -e "\n${BLUE}Step 7: Configuring proxy for HestiaCP...${NC}"

# Create proxy template file
echo -e "${YELLOW}Creating proxy template for backend API...${NC}"
cat > /tmp/backend_api_proxy.tpl << EOL
location /api/ {
    proxy_pass http://127.0.0.1:8001/api/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_cache_bypass \$http_upgrade;
}
EOL

# Check if v-restart-web exists
if command -v v-restart-web &> /dev/null; then
    echo -e "${YELLOW}Restarting web server...${NC}"
    v-restart-web || warn "Failed to restart web server. You might need to do this manually."
else
    warn "v-restart-web command not found. You may need to restart the web server manually."
fi

# Step 8: Verify installation
echo -e "\n${BLUE}Step 8: Verifying installation...${NC}"

# Check if key files exist
echo -e "${YELLOW}Checking key files...${NC}"
missing_files=false

check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}✗ Missing file: $1${NC}"
        missing_files=true
    else
        echo -e "${GREEN}✓ File exists: $1${NC}"
    fi
}

check_file "$PUBLIC_HTML/index.html"
check_file "$PUBLIC_HTML/backend/server.py"
check_file "$PUBLIC_HTML/backend/.env"
check_file "/etc/supervisor/conf.d/itsyourradio-backend.conf"

if $missing_files; then
    warn "Some files are missing. The installation might not work correctly."
else
    success_step "All key files are present"
fi

# Check if backend is running
echo -e "${YELLOW}Checking if backend is running...${NC}"
if curl -s "http://localhost:8001/api/" > /dev/null; then
    success_step "Backend API is running"
else
    warn "Backend API is not responding. You might need to troubleshoot the service."
    warn "Check the supervisor logs at: $PUBLIC_HTML/logs/supervisor.log"
fi

# Final message
echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN}             Deployment Complete!                      ${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo -e "1. Log in to HestiaCP admin panel"
echo -e "2. Navigate to Web > $DOMAIN > Proxy Templates"
echo -e "3. Create a new template named 'Backend API' using the content from:"
echo -e "   ${YELLOW}/tmp/backend_api_proxy.tpl${NC}"
echo -e "4. Add this template to your domain"
echo -e "5. Place your logo files and PWA icons in the appropriate directories:"
echo -e "   ${YELLOW}$PUBLIC_HTML/icons/${NC}"
echo -e "6. Update your Shoutcast/Icecast stream URL in the configuration"
echo
echo -e "Default admin login:"
echo -e "Email: ${YELLOW}admin@itsyourradio.com${NC}"
echo -e "Password: ${YELLOW}IYR_admin_2025!${NC}"
echo
echo -e "${RED}IMPORTANT:${NC} Change this password immediately after your first login!"
echo
echo -e "If you encounter any issues, check the logs:"
echo -e "Backend logs: ${YELLOW}$PUBLIC_HTML/logs/supervisor.log${NC}"
echo
echo -e "${GREEN}For more details, refer to DEPLOYMENT_INSTRUCTIONS.md${NC}"
echo -e "${GREEN}in the $PUBLIC_HTML directory.${NC}"
