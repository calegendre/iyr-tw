#!/bin/bash

# itsyourradio Deployment Script
# Customized for itsyourradio.com

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}         itsyourradio Deployment Script               ${NC}"
echo -e "${GREEN}=======================================================${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or with sudo${NC}"
  exit 1
fi

# Step 1: Install prerequisites
echo -e "${YELLOW}Installing prerequisites...${NC}"
apt-get update
apt-get install -y python3 python3-pip supervisor

# Step 2: Install Python dependencies
echo -e "${YELLOW}Installing Python packages...${NC}"
pip3 install fastapi uvicorn sqlalchemy pymysql python-jose[cryptography] passlib[bcrypt] python-multipart python-dotenv

# Step 3: Clean public_html directory
echo -e "${YELLOW}Cleaning public_html directory...${NC}"
rm -rf $PUBLIC_HTML/* $PUBLIC_HTML/.[^.]*

# Step 4: Create necessary directories
echo -e "${YELLOW}Creating necessary directories...${NC}"
mkdir -p $PUBLIC_HTML/backend
mkdir -p $PUBLIC_HTML/uploads/{profile_images,cover_images,album_art,podcast_covers}
mkdir -p $PUBLIC_HTML/station/{music,podcasts}
mkdir -p $PUBLIC_HTML/logs
mkdir -p $PUBLIC_HTML/icons

# Step 5: Set proper permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
chmod -R 755 $PUBLIC_HTML/uploads
chmod -R 755 $PUBLIC_HTML/station
chown -R $USER:$USER $PUBLIC_HTML

# Step 6: Create deployment structure
echo -e "${YELLOW}Creating deployment package...${NC}"
cd /app
./build.sh

# Step 7: Copy files to public_html
echo -e "${YELLOW}Copying files to public_html...${NC}"
cp -r /app/deployment/* $PUBLIC_HTML/
cp -r /app/deployment/.* $PUBLIC_HTML/ 2>/dev/null || :

# Step 8: Create .env file for backend
echo -e "${YELLOW}Creating backend environment file...${NC}"
cat > $PUBLIC_HTML/backend/.env << EOL
DATABASE_URL=mysql+pymysql://$DB_USER:$DB_PASSWORD@$DB_HOST/$DB_NAME
SECRET_KEY=$SECRET_KEY
WEBSITE_URL=https://$DOMAIN
EOL

# Step 9: Create supervisor configuration
echo -e "${YELLOW}Setting up supervisor configuration...${NC}"
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

# Step 10: Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
cd $PUBLIC_HTML/backend
python3 -c "from utils.db_init import init_db; init_db()"

# Step 11: Set up HestiaCP proxy templates
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

# NOTE: Now you need to manually add this template in the HestiaCP admin panel
# as we can't do this through the script directly

# Step 12: Update supervisor and restart services
echo -e "${YELLOW}Updating supervisor and restarting services...${NC}"
supervisorctl reread
supervisorctl update
supervisorctl restart itsyourradio-backend
v-restart-web

echo -e "${GREEN}=======================================================${NC}"
echo -e "${GREEN}             Deployment Complete!                      ${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo
echo -e "${YELLOW}IMPORTANT NEXT STEPS:${NC}"
echo -e "1. Log in to HestiaCP admin panel"
echo -e "2. Navigate to Web > $DOMAIN > Proxy Templates"
echo -e "3. Create a new template named 'Backend API' using the content from:"
echo -e "   ${YELLOW}/tmp/backend_api_proxy.tpl${NC}"
echo -e "4. Add this template to your domain"
echo -e "5. Place your logo files and PWA icons in the appropriate directories"
echo -e "6. Update your Shoutcast/Icecast stream URL in the configuration"
echo
echo -e "Default admin login:"
echo -e "Email: ${YELLOW}admin@itsyourradio.com${NC}"
echo -e "Password: ${YELLOW}IYR_admin_2025!${NC}"
echo
echo -e "${RED}IMPORTANT:${NC} Change this password immediately after your first login!"
echo
echo -e "${GREEN}If you need further assistance, refer to DEPLOYMENT_INSTRUCTIONS.md${NC}"
echo -e "${GREEN}or contact support.${NC}"
