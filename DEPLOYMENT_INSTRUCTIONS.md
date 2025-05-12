# itsyourradio - Deployment Instructions for HestiaCP

This document provides detailed step-by-step instructions for deploying itsyourradio on a server running HestiaCP.

## Prerequisites

- A server running HestiaCP with PHP 8.2 and MySQL/MariaDB
- Domain name configured in HestiaCP
- Node.js 16+ and npm/yarn installed on the server
- Python 3.9+ installed on the server
- SSH access to your server

## Step 1: Create Web Domain in HestiaCP

1. Log in to your HestiaCP admin panel
2. Navigate to Web > Add Web Domain
3. Enter your domain (e.g., `itsyourradio.com` or `radio.yourdomain.com`)
4. Select appropriate PHP version (PHP 8.2 recommended)
5. Check "Create Database" and set a secure password
6. Click "Add" to create the domain

## Step 2: Prepare the Environment

1. Connect to your server via SSH:
   ```bash
   ssh username@your-server-ip
   ```

2. Navigate to your domain's public_html directory:
   ```bash
   cd /home/username/web/yourdomain.com/public_html
   ```

3. Clean the directory (if not empty):
   ```bash
   rm -rf * .[^.]*
   ```

4. Install required Python packages:
   ```bash
   pip3 install fastapi uvicorn motor pymongo python-jose[cryptography] passlib[bcrypt] python-multipart python-dotenv
   ```

## Step 3: Upload Application Files

### Option 1: Upload via SCP/SFTP
1. Use SCP or an SFTP client like FileZilla to upload all files from the project to your server

### Option 2: Clone from Git (if available)
1. Clone the repository:
   ```bash
   git clone https://your-repository-url.git .
   ```

### Option 3: Manual Transfer
1. Upload the following directories to public_html:
   - backend/
   - frontend/build/ (contents should go directly into public_html)

## Step 4: Set Up the Backend

1. Create a .env file in the backend directory:
   ```bash
   cd /home/username/web/yourdomain.com/public_html/backend
   nano .env
   ```

2. Add the following content to the .env file:
   ```
   MONGO_URL=mongodb://localhost:27017/itsyourradio
   DB_NAME=itsyourradio
   SECRET_KEY=your-very-secure-secret-key-here
   WEBSITE_URL=https://yourdomain.com
   ```
   Replace `your-very-secure-secret-key-here` with a randomly generated secure key.

3. Create directories for media storage:
   ```bash
   mkdir -p /home/username/web/yourdomain.com/public_html/uploads/{profile_images,cover_images,album_art,podcast_covers}
   mkdir -p /home/username/web/yourdomain.com/public_html/station/{music,podcasts}
   chmod -R 755 /home/username/web/yourdomain.com/public_html/uploads
   chmod -R 755 /home/username/web/yourdomain.com/public_html/station
   ```

## Step 5: Set Up Supervisor for Backend Service

1. Install supervisor if not already installed:
   ```bash
   apt-get update
   apt-get install supervisor
   ```

2. Create a supervisor configuration file:
   ```bash
   nano /etc/supervisor/conf.d/itsyourradio-backend.conf
   ```

3. Add the following content:
   ```ini
   [program:itsyourradio-backend]
   directory=/home/username/web/yourdomain.com/public_html/backend
   command=uvicorn server:app --host 0.0.0.0 --port 8001
   autostart=true
   autorestart=true
   user=username
   redirect_stderr=true
   stdout_logfile=/home/username/web/yourdomain.com/logs/supervisor.log
   ```
   Replace `username` with your actual username.

4. Create the logs directory:
   ```bash
   mkdir -p /home/username/web/yourdomain.com/logs
   ```

5. Update supervisor to load the new configuration:
   ```bash
   supervisorctl reread
   supervisorctl update
   ```

## Step 6: Configure the Frontend

1. Update the frontend environment variables for API connection:
   ```bash
   cd /home/username/web/yourdomain.com/public_html
   nano .env
   ```

2. Add the following content:
   ```
   REACT_APP_BACKEND_URL=https://yourdomain.com/api
   ```

3. Update the streamConfig.js with your Shoutcast/Icecast stream URL:
   - Find the streamConfig.js file in the static/js directory (exact path will vary with each build)
   - Update the "stationStreamUrl" value to your actual stream URL

## Step 7: Set Up Proxy Rules in HestiaCP

1. Log in to HestiaCP admin panel
2. Navigate to Web > yourdomain.com > Proxy Templates
3. Create a new Proxy Template:
   - Name: Backend API
   - Template:
     ```
     location /api/ {
         proxy_pass http://127.0.0.1:8001/api/;
         proxy_http_version 1.1;
         proxy_set_header Upgrade $http_upgrade;
         proxy_set_header Connection 'upgrade';
         proxy_set_header Host $host;
         proxy_cache_bypass $http_upgrade;
     }
     ```
4. Add the template to your domain

## Step 8: Add Asset Files

1. Follow the instructions in the README-ASSETS.md file to place:
   - PWA icons in the icons/ directory
   - Logo files in the root directory
   - Other required assets

2. Customize your station details:
   - Update streamConfig.js with your station name, slogan, etc.
   - Customize colors and branding as needed

## Step 9: Final Configuration

1. Restart the web server:
   ```bash
   v-restart-web
   ```

2. Restart the backend service:
   ```bash
   supervisorctl restart itsyourradio-backend
   ```

3. Check that everything is running:
   ```bash
   supervisorctl status itsyourradio-backend
   ```

## Step 10: First Login

1. Visit your domain in a web browser
2. Log in with the default admin credentials:
   - Email: admin@itsyourradio.com
   - Password: IYR_admin_2025!
3. Go to the Admin Dashboard and IMMEDIATELY change the admin password for security

## Troubleshooting

### Backend Service Not Starting
Check the supervisor logs:
```bash
cat /home/username/web/yourdomain.com/logs/supervisor.log
```

### API Connection Issues
Make sure the proxy rule is correctly configured in HestiaCP and that the backend service is running.

### File Upload Issues
Check permissions on the upload directories:
```bash
chmod -R 755 /home/username/web/yourdomain.com/public_html/uploads
chmod -R 755 /home/username/web/yourdomain.com/public_html/station
```

## Security Notes

1. Always change the default admin password immediately after first login
2. Generate a strong SECRET_KEY for the backend .env file
3. Consider setting up HTTPS for your domain if not already enabled
4. Regularly backup your database and uploaded content

## Updates and Maintenance

To update the application in the future:
1. Backup your current installation and data
2. Replace the application files with the new version
3. Run any required database migrations
4. Restart the backend service:
   ```bash
   supervisorctl restart itsyourradio-backend
   ```

For questions or support, please contact support@itsyourradio.com
