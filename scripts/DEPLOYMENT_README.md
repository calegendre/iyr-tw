# itsyourradio Deployment Guide

This guide provides instructions for deploying the itsyourradio website on a HestiaCP server with PHP 8.2 and MySQL/MariaDB.

## Prerequisites

- HestiaCP server with PHP 8.2
- MySQL/MariaDB database
- Python 3.8+ 
- Supervisor for process management

## Database Configuration

The deployment uses the following database credentials:
- Database Name: `radio_itsyourradio25`
- Username: `radio_iyruser25`
- Password: `l6Sui@BGY{Kzg7qu`

## Deployment Options

### Option 1: Using the Deployment Script

The main deployment script will set up the entire application, including the database, backend, and frontend.

```bash
sudo bash /path/to/direct_deploy_fixed.sh
```

### Option 2: Manual Database Setup + Script

If you encounter issues with the database initialization during deployment, you can:

1. Manually create the database schema using the SQL file:

```bash
mysql -u radio_iyruser25 -p radio_itsyourradio25 < /path/to/setup_database.sql
```

2. Run the deployment script without database initialization:

```bash
sudo bash /path/to/direct_deploy_fixed.sh
```

### Option 3: Python Database Initialization

If you prefer to initialize the database with Python:

```bash
# Set up virtual environment
python3 -m venv venv
source venv/bin/activate

# Install required packages
pip install pymysql bcrypt python-dotenv

# Run the initialization script
python /path/to/init_database.py
```

## Deployment Directory

The application will be deployed to the following directory:
```
/home/radio/web/itsyourradio.com/public_html
```

## Admin Credentials

After deployment, you can log in with the following admin credentials:
- Email: `admin@itsyourradio.com`
- Password: `IYR_admin_2025!`

## Folder Structure

The deployment will create the following structure:
```
/home/radio/web/itsyourradio.com/
├── public_html/             # Main web directory
│   ├── backend/             # FastAPI backend code
│   ├── api/                 # PHP proxy for API
│   ├── venv/                # Python virtual environment
│   ├── index.html           # Frontend entry point
│   ├── ...                  # Other frontend files
│   └── database.sql         # Database schema file
└── logs/                    # Log files
```

## Troubleshooting

### Database Connection Issues
If you encounter database connection issues:

1. Verify the database credentials in:
   - `/home/radio/web/itsyourradio.com/public_html/backend/.env`

2. Ensure the database exists:
```sql
CREATE DATABASE IF NOT EXISTS radio_itsyourradio25;
GRANT ALL PRIVILEGES ON radio_itsyourradio25.* TO 'radio_iyruser25'@'localhost' IDENTIFIED BY 'l6Sui@BGY{Kzg7qu';
FLUSH PRIVILEGES;
```

### Backend Not Starting
If the backend fails to start:

1. Check the logs:
```bash
cat /home/radio/web/itsyourradio.com/logs/backend.log
```

2. Verify the supervisor configuration:
```bash
cat /etc/supervisor/conf.d/itsyourradio.conf
```

3. Restart the backend:
```bash
sudo supervisorctl restart itsyourradio_backend
```

### Frontend Issues
If the frontend isn't displaying correctly:

1. Check for JavaScript console errors in your browser
2. Verify that the `.env` file contains the correct `REACT_APP_BACKEND_URL`
3. Ensure the `.htaccess` file is correctly routing requests