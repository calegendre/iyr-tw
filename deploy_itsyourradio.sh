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
VENV_PATH="$PUBLIC_HTML/venv"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# Check for required system packages
check_install_package python3 python3
check_install_package pip3 python3-pip
check_install_package supervisorctl supervisor
check_install_package openssl openssl
check_install_package venv python3-venv

# Install additional required packages
apt-get install -y python3-full || warn "Failed to install python3-full package. Virtual environment may not work correctly."

success_step "All system prerequisites installed successfully"

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

# Step 3: Deploy application files directly
echo -e "\n${BLUE}Step 3: Deploying application files...${NC}"

# Check if build.sh exists in the same directory as this script
if [ -f "$SCRIPT_DIR/build.sh" ]; then
    echo -e "${YELLOW}Found build.sh script in the same directory.${NC}"
    cd "$SCRIPT_DIR" || handle_error "Failed to change to script directory"
    chmod +x build.sh
    
    echo -e "${YELLOW}Running build script...${NC}"
    ./build.sh || handle_error "Failed to build the application"
    
    if [ -d "$SCRIPT_DIR/deployment" ]; then
        echo -e "${YELLOW}Copying files to public_html...${NC}"
        cp -r "$SCRIPT_DIR/deployment/"* "$PUBLIC_HTML"/ || handle_error "Failed to copy files to public_html"
        # Copy hidden files but ignore errors if there are none
        cp -r "$SCRIPT_DIR/deployment/"/.* "$PUBLIC_HTML"/ 2>/dev/null || true
    else
        # Alternative: If no deployment directory was created, we'll copy key application files directly
        echo -e "${YELLOW}Deployment directory not found. Copying application files directly...${NC}"
        
        # Copy backend files
        echo -e "${YELLOW}Copying backend files...${NC}"
        if [ -d "$SCRIPT_DIR/backend" ]; then
            cp -r "$SCRIPT_DIR/backend/"* "$PUBLIC_HTML/backend/"
        else
            handle_error "Backend directory not found"
        fi
        
        # Copy frontend files
        echo -e "${YELLOW}Copying frontend files...${NC}"
        if [ -d "$SCRIPT_DIR/frontend/build" ]; then
            cp -r "$SCRIPT_DIR/frontend/build/"* "$PUBLIC_HTML/"
            cp -r "$SCRIPT_DIR/frontend/build/"/.* "$PUBLIC_HTML/" 2>/dev/null || true
        elif [ -d "$SCRIPT_DIR/frontend" ]; then
            # If frontend/build doesn't exist but frontend does, try to copy static files
            find "$SCRIPT_DIR/frontend" -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.png" -o -name "*.jpg" -o -name "*.svg" | xargs -I{} cp {} "$PUBLIC_HTML/"
        else
            warn "Frontend files not found. Manual frontend deployment may be required."
        fi
        
        # Copy documentation files
        cp -f "$SCRIPT_DIR/"*.md "$PUBLIC_HTML/" 2>/dev/null || true
    fi
    
    # Verify key files exist
    if [ ! -f "$PUBLIC_HTML/index.html" ]; then
        warn "Frontend files may not have been copied correctly - index.html is missing"
        warn "You may need to manually copy the frontend files"
    fi
    
    if [ ! -f "$PUBLIC_HTML/backend/server.py" ]; then
        handle_error "Backend files were not copied correctly - server.py is missing"
    fi
    
    success_step "Application files deployed successfully"
else
    # If build.sh isn't found, look for key application files directly
    echo -e "${YELLOW}build.sh not found. Checking for application files directly...${NC}"
    
    if [ -d "$SCRIPT_DIR/backend" ]; then
        echo -e "${YELLOW}Found backend directory. Copying backend files...${NC}"
        cp -r "$SCRIPT_DIR/backend/"* "$PUBLIC_HTML/backend/"
    else
        handle_error "Backend directory not found. Cannot proceed with deployment."
    fi
    
    if [ -d "$SCRIPT_DIR/frontend/build" ]; then
        echo -e "${YELLOW}Found frontend build directory. Copying frontend files...${NC}"
        cp -r "$SCRIPT_DIR/frontend/build/"* "$PUBLIC_HTML/"
    elif [ -d "$SCRIPT_DIR/frontend" ]; then
        echo -e "${YELLOW}Found frontend directory but no build folder. Trying to copy essential files...${NC}"
        find "$SCRIPT_DIR/frontend" -name "*.html" -o -name "*.js" -o -name "*.css" -o -name "*.png" -o -name "*.jpg" -o -name "*.svg" | xargs -I{} cp {} "$PUBLIC_HTML/"
        warn "Frontend may not be properly built. Consider building it separately."
    else
        warn "Frontend files not found. Manual frontend deployment will be required."
    fi
    
    # Copy documentation files
    cp -f "$SCRIPT_DIR/"*.md "$PUBLIC_HTML/" 2>/dev/null || true
    
    # Verify key files
    if [ ! -f "$PUBLIC_HTML/backend/server.py" ]; then
        handle_error "Backend files were not copied correctly - server.py is missing"
    else
        success_step "Application files partially deployed - backend found"
    fi
fi

# Step 4: Set up Python virtual environment and install dependencies
echo -e "\n${BLUE}Step 4: Setting up Python virtual environment...${NC}"

# Create virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3 -m venv "$VENV_PATH" || handle_error "Failed to create virtual environment"

# Install Python dependencies in virtual environment
echo -e "${YELLOW}Installing Python dependencies in virtual environment...${NC}"
"$VENV_PATH/bin/pip" install --upgrade pip || warn "Failed to upgrade pip in virtual environment"
"$VENV_PATH/bin/pip" install fastapi uvicorn sqlalchemy pymysql python-jose[cryptography] passlib[bcrypt] python-multipart python-dotenv || handle_error "Failed to install Python dependencies in virtual environment"

success_step "Virtual environment set up successfully"

# Step 5: Configure the environment
echo -e "\n${BLUE}Step 5: Configuring the environment...${NC}"

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

# Step 6: Set up database and initialize application
echo -e "\n${BLUE}Step 6: Setting up database...${NC}"

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

# Copy the database initialization module if it doesn't exist
if [ ! -f "$PUBLIC_HTML/backend/utils/db_init.py" ]; then
    echo -e "${YELLOW}Database initialization module not found. Creating it...${NC}"
    mkdir -p "$PUBLIC_HTML/backend/utils"
    
    cat > "$PUBLIC_HTML/backend/utils/db_init.py" << 'EOL'
from ..database import engine, Base, SessionLocal
from ..models.sql_models import User
from .auth import get_password_hash
import uuid
from datetime import datetime

# Default admin account
DEFAULT_ADMIN = {
    "id": str(uuid.uuid4()),
    "email": "admin@itsyourradio.com",
    "username": "admin",
    "full_name": "Admin User",
    "role": "admin",
    "hashed_password": get_password_hash("IYR_admin_2025!"),
    "profile_image_url": None,
    "cover_image_url": None,
    "bio": "System administrator account",
    "created_at": datetime.utcnow(),
    "updated_at": datetime.utcnow(),
    "is_active": True
}

def init_db():
    """Initialize database tables and default data"""
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    # Add default admin if it doesn't exist
    db = SessionLocal()
    try:
        existing_admin = db.query(User).filter(User.email == DEFAULT_ADMIN["email"]).first()
        if not existing_admin:
            admin_user = User(
                id=DEFAULT_ADMIN["id"],
                email=DEFAULT_ADMIN["email"],
                username=DEFAULT_ADMIN["username"],
                full_name=DEFAULT_ADMIN["full_name"],
                role=DEFAULT_ADMIN["role"],
                hashed_password=DEFAULT_ADMIN["hashed_password"],
                bio=DEFAULT_ADMIN["bio"],
                is_active=DEFAULT_ADMIN["is_active"]
            )
            db.add(admin_user)
            db.commit()
            print("Default admin account created")
    except Exception as e:
        db.rollback()
        print(f"Error creating default admin: {e}")
    finally:
        db.close()
EOL
fi

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
cd "$PUBLIC_HTML/backend" || handle_error "Failed to change to backend directory"
"$VENV_PATH/bin/python" -c "from utils.db_init import init_db; init_db()" || handle_error "Failed to initialize database"
success_step "Database initialized successfully"

# Step 7: Set up supervisor for the backend service
echo -e "\n${BLUE}Step 7: Setting up supervisor...${NC}"

echo -e "${YELLOW}Creating supervisor configuration...${NC}"
cat > /etc/supervisor/conf.d/itsyourradio-backend.conf << EOL
[program:itsyourradio-backend]
directory=$PUBLIC_HTML/backend
command=$VENV_PATH/bin/uvicorn server:app --host 0.0.0.0 --port 8001
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

# Step 8: Configure proxy for HestiaCP
echo -e "\n${BLUE}Step 8: Configuring proxy for HestiaCP...${NC}"

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

# Step 9: Verify installation
echo -e "\n${BLUE}Step 9: Verifying installation...${NC}"

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

check_file "$PUBLIC_HTML/backend/server.py"
check_file "$PUBLIC_HTML/backend/.env"
check_file "/etc/supervisor/conf.d/itsyourradio-backend.conf"
check_file "$VENV_PATH/bin/python"
check_file "$VENV_PATH/bin/uvicorn"

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

# Fix ownership of all files
echo -e "${YELLOW}Setting proper ownership for all files...${NC}"
chown -R "$USER":"$USER" "$PUBLIC_HTML"

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
echo
echo -e "${BLUE}Python Virtual Environment:${NC}"
echo -e "The application is using a Python virtual environment at: ${YELLOW}$VENV_PATH${NC}"
echo -e "If you need to run Python commands manually, use: ${YELLOW}$VENV_PATH/bin/python${NC}"
