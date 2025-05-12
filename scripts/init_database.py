#!/usr/bin/env python3
"""
Database Initialization Script for itsyourradio

This script initializes the database and creates an admin user.
It can be run independently of the deployment script.
"""

import os
import sys
import uuid
import pymysql
import bcrypt
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database credentials
DB_USER = os.environ.get("DB_USER", "radio_iyruser25")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "l6Sui@BGY{Kzg7qu")
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "radio_itsyourradio25")

# Admin credentials
ADMIN_EMAIL = "admin@itsyourradio.com"
ADMIN_PASSWORD = "IYR_admin_2025!"

def hash_password(password):
    """Hash a password using bcrypt"""
    # Generate a salt
    salt = bcrypt.gensalt(12)
    # Hash the password
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)
    # Return the hashed password as a string
    return hashed_password.decode('utf-8')

def create_tables(connection):
    """Create database tables"""
    cursor = connection.cursor()
    
    # Create users table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        username VARCHAR(255) NOT NULL UNIQUE,
        hashed_password VARCHAR(255) NOT NULL,
        full_name VARCHAR(255),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT TRUE,
        role VARCHAR(50) DEFAULT 'member'
    )
    """)
    
    # Create artist_profiles table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS artist_profiles (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        stage_name VARCHAR(255) NOT NULL,
        bio TEXT,
        profile_image VARCHAR(255),
        website VARCHAR(255),
        social_links TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    """)
    
    # Create albums table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS albums (
        id VARCHAR(36) PRIMARY KEY,
        artist_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        release_date DATETIME,
        cover_image VARCHAR(255),
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (artist_id) REFERENCES artist_profiles(id) ON DELETE CASCADE
    )
    """)
    
    # Create tracks table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS tracks (
        id VARCHAR(36) PRIMARY KEY,
        artist_id VARCHAR(36) NOT NULL,
        album_id VARCHAR(36),
        title VARCHAR(255) NOT NULL,
        duration INT,
        file_path VARCHAR(255),
        track_number INT,
        genre VARCHAR(100),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (artist_id) REFERENCES artist_profiles(id) ON DELETE CASCADE,
        FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE SET NULL
    )
    """)
    
    # Create podcaster_profiles table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS podcaster_profiles (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        podcast_name VARCHAR(255) NOT NULL,
        description TEXT,
        profile_image VARCHAR(255),
        website VARCHAR(255),
        social_links TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    """)
    
    # Create podcast_episodes table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS podcast_episodes (
        id VARCHAR(36) PRIMARY KEY,
        podcaster_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        audio_file VARCHAR(255),
        episode_number INT,
        duration INT,
        published_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (podcaster_id) REFERENCES podcaster_profiles(id) ON DELETE CASCADE
    )
    """)
    
    # Create blog_posts table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS blog_posts (
        id VARCHAR(36) PRIMARY KEY,
        author_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        featured_image VARCHAR(255),
        slug VARCHAR(255) UNIQUE,
        published BOOLEAN DEFAULT FALSE,
        published_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE
    )
    """)
    
    # Create artist_blog_posts table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS artist_blog_posts (
        id VARCHAR(36) PRIMARY KEY,
        artist_id VARCHAR(36) NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL,
        featured_image VARCHAR(255),
        slug VARCHAR(255) UNIQUE,
        published BOOLEAN DEFAULT FALSE,
        published_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (artist_id) REFERENCES artist_profiles(id) ON DELETE CASCADE
    )
    """)
    
    connection.commit()
    cursor.close()
    
    print("Database tables created successfully")

def create_admin_user(connection):
    """Create admin user if it doesn't exist"""
    cursor = connection.cursor()
    
    # Check if admin user exists
    cursor.execute("SELECT id FROM users WHERE email = %s", (ADMIN_EMAIL,))
    admin = cursor.fetchone()
    
    if not admin:
        # Create admin user
        hashed_password = hash_password(ADMIN_PASSWORD)
        admin_id = str(uuid.uuid4())
        
        cursor.execute("""
        INSERT INTO users (id, email, username, hashed_password, full_name, role, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (admin_id, ADMIN_EMAIL, "admin", hashed_password, "IYR Admin", "admin", True))
        
        connection.commit()
        print(f"Admin user created successfully with email: {ADMIN_EMAIL}")
    else:
        print(f"Admin user already exists with email: {ADMIN_EMAIL}")
    
    cursor.close()

def main():
    """Main function"""
    try:
        # Connect to the database
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        print(f"Successfully connected to database: {DB_NAME}")
        
        # Create tables
        create_tables(connection)
        
        # Create admin user
        create_admin_user(connection)
        
        # Close connection
        connection.close()
        
        print("Database initialization completed successfully")
        
    except pymysql.MySQLError as e:
        print(f"Error connecting to MySQL database: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()