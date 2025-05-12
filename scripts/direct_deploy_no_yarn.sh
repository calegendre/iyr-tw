#!/bin/bash

# itsyourradio Direct Deployment Script (Fixed Version)
# For use with HestiaCP, MySQL, and PHP 8.2

# Configuration
DOMAIN="itsyourradio.com"
WEB_ROOT="/home/radio/web/$DOMAIN"
PUBLIC_HTML="$WEB_ROOT/public_html"
BACKEND_DIR="$PUBLIC_HTML/backend"
FRONTEND_SRC="$PUBLIC_HTML/frontend_src" # Source files
FRONTEND_BUILD="$PUBLIC_HTML"            # Built files go directly to public_html
LOGS_DIR="$WEB_ROOT/logs"
VENV_DIR="$PUBLIC_HTML/venv"

# Database credentials
DB_NAME="radio_itsyourradio25"
DB_USER="radio_iyruser25"
DB_PASSWORD="l6Sui@BGY{Kzg7qu"
DB_HOST="localhost"

# Admin credentials
ADMIN_EMAIL="admin@itsyourradio.com"
ADMIN_PASSWORD="IYR_admin_2025!"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Function to check for errors and exit if any are found
check_error() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        log_error "The deployment script encountered an error and will exit. Please fix the issue and run the script again."
        exit 1
    fi
}

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root"
    exit 1
fi

# Function to test database connection
test_db_connection() {
    log_message "Testing database connection..."
    if mysql -u "$DB_USER" -p"$DB_PASSWORD" -h "$DB_HOST" -e "USE $DB_NAME;" &> /dev/null; then
        log_message "✓ Database connection successful"
        return 0
    else
        log_error "Database connection failed. Please check your credentials."
        return 1
    fi
}

# Function to check and install Node.js and package manager
install_node_dependencies() {
    log_message "Checking for Node.js and package manager..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_message "Node.js not found. Installing Node.js..."
        curl -sL https://deb.nodesource.com/setup_18.x | bash -
        apt-get update
        apt-get install -y nodejs
        check_error "Failed to install Node.js"
    fi
    
    # Check Node.js version
    node_version=$(node -v)
    log_message "Node.js version: $node_version"
    
    # Check if yarn is installed
    if command -v yarn &> /dev/null; then
        log_message "Yarn is installed. Using yarn for package management."
        PACKAGE_MANAGER="yarn"
    else
        log_message "Yarn not found. Checking for npm..."
        
        if command -v npm &> /dev/null; then
            log_message "Using npm for package management."
            PACKAGE_MANAGER="npm"
        else
            log_error "Neither yarn nor npm is available. Cannot proceed."
            exit 1
        fi
    fi
    
    log_message "✓ Node.js and package manager setup complete"
}

# Setup the directory structure
setup_directories() {
    log_message "Step 1: Setting up directories..."
    
    # Create necessary directories
    mkdir -p "$LOGS_DIR"
    mkdir -p "$BACKEND_DIR"
    mkdir -p "$BACKEND_DIR/models"
    mkdir -p "$BACKEND_DIR/schemas"
    mkdir -p "$BACKEND_DIR/routers"
    mkdir -p "$BACKEND_DIR/utils"
    mkdir -p "$FRONTEND_SRC/src"
    mkdir -p "$FRONTEND_SRC/public"
    
    # Set correct permissions
    chown -R radio:radio "$WEB_ROOT"
    
    log_message "✓ Directory structure created"
}

# Create database.sql file
create_database_file() {
    log_message "Step 2: Creating database SQL file..."
    
    cat > "$PUBLIC_HTML/database.sql" << EOL
-- itsyourradio database schema

-- Create tables
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
);

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
);

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
);

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
);

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
);

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
);

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
);

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
);

-- Add admin user
INSERT INTO users (id, email, username, hashed_password, full_name, role, is_active)
VALUES (
    UUID(),
    'admin@itsyourradio.com',
    'admin',
    -- This is a bcrypt hash of 'IYR_admin_2025!'
    '$2b$12$MN9ZPoK4rEdHDolxQ8qXJee5HA6DZ7qw6eTPbQ9a90vrpZnL1.r8e',
    'IYR Admin',
    'admin',
    TRUE
)
ON DUPLICATE KEY UPDATE id=id;
EOL
    
    log_message "✓ Database SQL file created"
}

# Create backend files with proper imports
create_backend_files() {
    log_message "Step 3: Creating backend files..."
    
    # Create backend/.env file
    cat > "$BACKEND_DIR/.env" << EOL
DB_USER="$DB_USER"
DB_PASSWORD="$DB_PASSWORD"
DB_HOST="$DB_HOST"
DB_NAME="$DB_NAME"
SECRET_KEY="a9d7e4bf63715384a9c8f9d56789e3ac7d1e6f2b8c5a2d4e7f3b5a8c1d6e9f2"
ENVIRONMENT="production"
EOL
    
    # Create backend/database.py
    cat > "$BACKEND_DIR/database.py" << 'EOL'
import os
import urllib.parse
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database credentials
DB_USER = os.environ.get("DB_USER", "radio_iyruser25")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "l6Sui@BGY{Kzg7qu")
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "radio_itsyourradio25")

# URL encode the password to handle special characters
encoded_password = urllib.parse.quote_plus(DB_PASSWORD)

# Database URL
SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{DB_USER}:{encoded_password}@{DB_HOST}/{DB_NAME}"

# Create engine
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True,
    connect_args={"charset": "utf8mb4"}
)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()

# Dependency for getting DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOL
    
    # Create backend/models/models.py
    cat > "$BACKEND_DIR/models/models.py" << 'EOL'
import sys
import os
import uuid
from datetime import datetime
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text, DateTime
from sqlalchemy.orm import relationship

# Import Base from parent directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    role = Column(String(50), default="member")  # admin, staff, artist, podcaster, member

    # Relationships
    artist_profile = relationship("ArtistProfile", back_populates="user", uselist=False)
    podcaster_profile = relationship("PodcasterProfile", back_populates="user", uselist=False)
    blog_posts = relationship("BlogPost", back_populates="author")


class ArtistProfile(Base):
    __tablename__ = "artist_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    stage_name = Column(String(255), nullable=False)
    bio = Column(Text)
    profile_image = Column(String(255))
    website = Column(String(255))
    social_links = Column(Text)  # JSON formatted
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="artist_profile")
    albums = relationship("Album", back_populates="artist")
    tracks = relationship("Track", back_populates="artist")
    blog_posts = relationship("ArtistBlogPost", back_populates="artist")


class Album(Base):
    __tablename__ = "albums"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    artist_id = Column(String(36), ForeignKey("artist_profiles.id"), nullable=False)
    title = Column(String(255), nullable=False)
    release_date = Column(DateTime)
    cover_image = Column(String(255))
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    artist = relationship("ArtistProfile", back_populates="albums")
    tracks = relationship("Track", back_populates="album")


class Track(Base):
    __tablename__ = "tracks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    artist_id = Column(String(36), ForeignKey("artist_profiles.id"), nullable=False)
    album_id = Column(String(36), ForeignKey("albums.id"), nullable=True)
    title = Column(String(255), nullable=False)
    duration = Column(Integer)  # Duration in seconds
    file_path = Column(String(255))
    track_number = Column(Integer)
    genre = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    artist = relationship("ArtistProfile", back_populates="tracks")
    album = relationship("Album", back_populates="tracks")


class PodcasterProfile(Base):
    __tablename__ = "podcaster_profiles"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    podcast_name = Column(String(255), nullable=False)
    description = Column(Text)
    profile_image = Column(String(255))
    website = Column(String(255))
    social_links = Column(Text)  # JSON formatted
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="podcaster_profile")
    podcast_episodes = relationship("PodcastEpisode", back_populates="podcaster")


class PodcastEpisode(Base):
    __tablename__ = "podcast_episodes"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    podcaster_id = Column(String(36), ForeignKey("podcaster_profiles.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    audio_file = Column(String(255))
    episode_number = Column(Integer)
    duration = Column(Integer)  # Duration in seconds
    published_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    podcaster = relationship("PodcasterProfile", back_populates="podcast_episodes")


class BlogPost(Base):
    __tablename__ = "blog_posts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    author_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    featured_image = Column(String(255))
    slug = Column(String(255), unique=True)
    published = Column(Boolean, default=False)
    published_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    author = relationship("User", back_populates="blog_posts")


class ArtistBlogPost(Base):
    __tablename__ = "artist_blog_posts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    artist_id = Column(String(36), ForeignKey("artist_profiles.id"), nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    featured_image = Column(String(255))
    slug = Column(String(255), unique=True)
    published = Column(Boolean, default=False)
    published_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    artist = relationship("ArtistProfile", back_populates="blog_posts")
EOL
    
    # Create backend/models/__init__.py 
    cat > "$BACKEND_DIR/models/__init__.py" << 'EOL'
# Import models directly to make them available at the module level
from models.models import User, ArtistProfile, Album, Track, PodcasterProfile, PodcastEpisode, BlogPost, ArtistBlogPost
EOL
    
    # Create backend/utils/auth.py
    cat > "$BACKEND_DIR/utils/auth.py" << 'EOL'
import sys
import os
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from dotenv import load_dotenv

# Import models and database from parent directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import get_db
from models.models import User

# Load environment variables
load_dotenv()

# Secret key for JWT
SECRET_KEY = os.environ.get("SECRET_KEY", "a9d7e4bf63715384a9c8f9d56789e3ac7d1e6f2b8c5a2d4e7f3b5a8c1d6e9f2")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60  # 1 hour

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 setup for token URL
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

# Verify password
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# Hash password
def get_password_hash(password):
    return pwd_context.hash(password)

# Authenticate user
def authenticate_user(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

# Create access token
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# Get current user from token
async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

# Get current active user
async def get_current_active_user(current_user: User = Depends(get_current_user)):
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user

# Check if user is admin
def is_admin(current_user: User = Depends(get_current_active_user)):
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

# Check if user is staff or admin
def is_staff_or_admin(current_user: User = Depends(get_current_active_user)):
    if current_user.role not in ["admin", "staff"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user
EOL
    
    # Create backend/utils/db_init.py
    cat > "$BACKEND_DIR/utils/db_init.py" << 'EOL'
import sys
import os
import uuid
from passlib.context import CryptContext

# Import from parent directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import engine, Base, SessionLocal
from models.models import User

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def init_db():
    """Initialize database tables and add admin user if not exists"""
    try:
        # Create all tables
        Base.metadata.create_all(bind=engine)
        
        # Create a session
        db = SessionLocal()
        
        # Check if admin user exists
        admin = db.query(User).filter(User.email == "admin@itsyourradio.com").first()
        
        # If admin user doesn't exist, create it
        if not admin:
            admin_user = User(
                id=str(uuid.uuid4()),
                email="admin@itsyourradio.com",
                username="admin",
                hashed_password=get_password_hash("IYR_admin_2025!"),
                full_name="IYR Admin",
                role="admin"
            )
            db.add(admin_user)
            db.commit()
            print("Admin user created successfully!")
        else:
            print("Admin user already exists.")
        
        db.close()
        return True
    except Exception as e:
        print(f"Error initializing database: {e}")
        return False

if __name__ == "__main__":
    # This allows running the script directly
    success = init_db()
    if success:
        print("Database initialized successfully!")
    else:
        print("Failed to initialize database.")
EOL
    
    # Create backend/utils/__init__.py
    cat > "$BACKEND_DIR/utils/__init__.py" << 'EOL'
# Import directly using absolute imports
from utils.auth import (
    verify_password,
    get_password_hash,
    authenticate_user,
    create_access_token,
    get_current_user,
    get_current_active_user,
    is_admin,
    is_staff_or_admin
)

from utils.db_init import init_db
EOL
    
    # Create backend/routers/auth.py
    cat > "$BACKEND_DIR/routers/auth.py" << 'EOL'
import sys
import os
from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

# Import from parent directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import get_db
from models.models import User
from schemas.schemas import UserCreate, UserResponse, Token
from utils.auth import (
    authenticate_user,
    create_access_token,
    get_password_hash,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

router = APIRouter()

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login and get access token"""
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=UserResponse)
async def register_user(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if email already exists
    existing_email = db.query(User).filter(User.email == user.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Check if username already exists
    existing_username = db.query(User).filter(User.username == user.username).first()
    if existing_username:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    # Create new user
    hashed_password = get_password_hash(user.password)
    db_user = User(
        id=os.urandom(16).hex(),
        email=user.email,
        username=user.username,
        hashed_password=hashed_password,
        full_name=user.full_name,
        role="member"  # Default role for new users
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user
EOL
    
    # Create backend/routers/users.py
    cat > "$BACKEND_DIR/routers/users.py" << 'EOL'
import sys
import os
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

# Import from parent directory
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database import get_db
from models.models import User
from schemas.schemas import UserResponse, UserUpdate
from utils.auth import get_current_active_user, is_admin

router = APIRouter()

@router.get("/me", response_model=UserResponse)
async def read_users_me(current_user: User = Depends(get_current_active_user)):
    """Get current user info"""
    return current_user

@router.get("/{user_id}", response_model=UserResponse)
async def read_user(user_id: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    """Get user by ID"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str, 
    user: UserUpdate, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_active_user)
):
    """Update user"""
    # Only admins can update other users
    if current_user.id != user_id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    
    db_user = db.query(User).filter(User.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update user attributes
    user_data = user.dict(exclude_unset=True)
    
    # If password is being updated, hash it
    if "password" in user_data and user_data["password"]:
        from utils.auth import get_password_hash
        user_data["hashed_password"] = get_password_hash(user_data.pop("password"))
    
    for key, value in user_data.items():
        setattr(db_user, key, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str, db: Session = Depends(get_db), current_user: User = Depends(is_admin)):
    """Delete user (admin only)"""
    db_user = db.query(User).filter(User.id == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(db_user)
    db.commit()
    
    return {"message": "User deleted successfully"}
EOL
    
    # Create backend/routers/__init__.py
    cat > "$BACKEND_DIR/routers/__init__.py" << 'EOL'
# Import routers
EOL
    
    # Create backend/schemas/schemas.py
    cat > "$BACKEND_DIR/schemas/schemas.py" << 'EOL'
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None
    role: Optional[str] = None

class UserResponse(UserBase):
    id: str
    is_active: bool
    role: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
    id: Optional[str] = None
    role: Optional[str] = None

class ArtistProfileBase(BaseModel):
    stage_name: str
    bio: Optional[str] = None
    profile_image: Optional[str] = None
    website: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None

class ArtistProfileCreate(ArtistProfileBase):
    pass

class ArtistProfileUpdate(BaseModel):
    stage_name: Optional[str] = None
    bio: Optional[str] = None
    profile_image: Optional[str] = None
    website: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None

class ArtistProfileResponse(ArtistProfileBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class AlbumBase(BaseModel):
    title: str
    release_date: Optional[datetime] = None
    cover_image: Optional[str] = None
    description: Optional[str] = None

class AlbumCreate(AlbumBase):
    pass

class AlbumUpdate(BaseModel):
    title: Optional[str] = None
    release_date: Optional[datetime] = None
    cover_image: Optional[str] = None
    description: Optional[str] = None

class AlbumResponse(AlbumBase):
    id: str
    artist_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TrackBase(BaseModel):
    title: str
    duration: Optional[int] = None
    file_path: Optional[str] = None
    track_number: Optional[int] = None
    genre: Optional[str] = None

class TrackCreate(TrackBase):
    album_id: Optional[str] = None

class TrackUpdate(BaseModel):
    title: Optional[str] = None
    duration: Optional[int] = None
    file_path: Optional[str] = None
    track_number: Optional[int] = None
    genre: Optional[str] = None
    album_id: Optional[str] = None

class TrackResponse(TrackBase):
    id: str
    artist_id: str
    album_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PodcasterProfileBase(BaseModel):
    podcast_name: str
    description: Optional[str] = None
    profile_image: Optional[str] = None
    website: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None

class PodcasterProfileCreate(PodcasterProfileBase):
    pass

class PodcasterProfileUpdate(BaseModel):
    podcast_name: Optional[str] = None
    description: Optional[str] = None
    profile_image: Optional[str] = None
    website: Optional[str] = None
    social_links: Optional[Dict[str, str]] = None

class PodcasterProfileResponse(PodcasterProfileBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PodcastEpisodeBase(BaseModel):
    title: str
    description: Optional[str] = None
    audio_file: Optional[str] = None
    episode_number: Optional[int] = None
    duration: Optional[int] = None

class PodcastEpisodeCreate(PodcastEpisodeBase):
    pass

class PodcastEpisodeUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    audio_file: Optional[str] = None
    episode_number: Optional[int] = None
    duration: Optional[int] = None

class PodcastEpisodeResponse(PodcastEpisodeBase):
    id: str
    podcaster_id: str
    published_at: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class BlogPostBase(BaseModel):
    title: str
    content: str
    featured_image: Optional[str] = None
    slug: Optional[str] = None
    published: Optional[bool] = False

class BlogPostCreate(BlogPostBase):
    pass

class BlogPostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    featured_image: Optional[str] = None
    slug: Optional[str] = None
    published: Optional[bool] = None

class BlogPostResponse(BlogPostBase):
    id: str
    author_id: str
    published_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ArtistBlogPostBase(BaseModel):
    title: str
    content: str
    featured_image: Optional[str] = None
    slug: Optional[str] = None
    published: Optional[bool] = False

class ArtistBlogPostCreate(ArtistBlogPostBase):
    pass

class ArtistBlogPostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    featured_image: Optional[str] = None
    slug: Optional[str] = None
    published: Optional[bool] = None

class ArtistBlogPostResponse(ArtistBlogPostBase):
    id: str
    artist_id: str
    published_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
EOL
    
    # Create backend/schemas/__init__.py
    cat > "$BACKEND_DIR/schemas/__init__.py" << 'EOL'
# Import schemas
from schemas.schemas import (
    UserBase, UserCreate, UserUpdate, UserResponse, Token, TokenData,
    ArtistProfileBase, ArtistProfileCreate, ArtistProfileUpdate, ArtistProfileResponse,
    AlbumBase, AlbumCreate, AlbumUpdate, AlbumResponse,
    TrackBase, TrackCreate, TrackUpdate, TrackResponse,
    PodcasterProfileBase, PodcasterProfileCreate, PodcasterProfileUpdate, PodcasterProfileResponse,
    PodcastEpisodeBase, PodcastEpisodeCreate, PodcastEpisodeUpdate, PodcastEpisodeResponse,
    BlogPostBase, BlogPostCreate, BlogPostUpdate, BlogPostResponse,
    ArtistBlogPostBase, ArtistBlogPostCreate, ArtistBlogPostUpdate, ArtistBlogPostResponse
)
EOL
    
    # Create main server.py file
    cat > "$BACKEND_DIR/server.py" << 'EOL'
import sys
import os
from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import modules
from database import engine, Base
from utils.db_init import init_db
from routers import auth, users

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(title="itsyourradio API")

# Set up CORS middleware
origins = [
    "*",  # Allow all origins for development
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create API router
api_router = APIRouter(prefix="/api")

# Include routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])

# Add API router to app
app.include_router(api_router)

# Root API endpoint
@app.get("/api/")
async def root():
    """Root API endpoint"""
    return {"message": "Welcome to itsyourradio API"}

# Startup event: Create tables and initialize database
@app.on_event("startup")
async def startup_event():
    """Run on startup"""
    try:
        # Create tables
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully!")
        
        # Initialize database with admin user
        init_db()
    except Exception as e:
        print(f"Error on startup: {e}")

# For direct execution
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8001, reload=True)
EOL
    
    # Create requirements.txt
    cat > "$BACKEND_DIR/requirements.txt" << 'EOL'
fastapi>=0.101.1
uvicorn>=0.23.2
Jinja2>=3.1.2
pydantic>=2.3.0
aiohttp>=3.8.5
python-dotenv>=1.0.0
bcrypt>=4.0.1
PyJWT>=2.8.0
websockets>=11.0.3
python-socketio>=5.8.0
aiofiles>=23.1.0
pytest>=7.4.0
pytest-asyncio>=0.21.1
argon2-cffi>=21.3.0
cryptography>=41.0.3
PyYAML>=6.0.1
asyncio>=3.4.3
pendulum>=2.1.2
python-slugify>=8.0.1
numpy>=1.26.0
python-multipart>=0.0.9
typer>=0.9.0
sqlalchemy>=2.0.0
pymysql>=1.1.0
alembic>=1.12.0
passlib>=1.7.4
python-jose[cryptography]>=3.3.0
email_validator>=2.0.0
requests>=2.31.0
EOL
    
    log_message "✓ Backend files created successfully"
}

# Create frontend files
create_frontend_files() {
    log_message "Step 4: Creating frontend files..."
    
    # Copy the pre-built frontend files directly to the public_html directory
    log_message "Creating a simple frontend that will redirect to the API..."
    
    # Create a simple index.html file
    cat > "$PUBLIC_HTML/index.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>itsyourradio</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
            background-color: #f5f5f5;
            margin: 0;
            padding: 0;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }
        header {
            background-color: #333;
            color: white;
            padding: 1rem;
            text-align: center;
        }
        main {
            flex: 1;
            padding: 2rem;
            max-width: 1200px;
            margin: 0 auto;
            width: 100%;
        }
        .card {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            padding: 2rem;
            margin-bottom: 2rem;
        }
        h1 {
            color: #333;
        }
        footer {
            background-color: #333;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: auto;
        }
        a {
            color: #0066cc;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .button {
            display: inline-block;
            background-color: #0066cc;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            text-decoration: none;
            margin-top: 1rem;
        }
        .button:hover {
            background-color: #0052a3;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <header>
        <h1>itsyourradio</h1>
    </header>
    <main>
        <div class="card">
            <h2>Welcome to itsyourradio</h2>
            <p>The backend API has been successfully deployed. Use the links below to access different parts of the application:</p>
            
            <h3>API Access</h3>
            <ul>
                <li><a href="/api" target="_blank">API Root</a> - Check if the API is running</li>
                <li><a href="/api/docs" target="_blank">API Documentation</a> - Swagger UI for API documentation</li>
            </ul>
            
            <h3>Default Admin Credentials</h3>
            <p>Email: admin@itsyourradio.com<br>
            Password: IYR_admin_2025!</p>
            
            <div>
                <a href="/api/docs" class="button">Go to API Documentation</a>
            </div>
        </div>
    </main>
    <footer>
        &copy; 2025 itsyourradio. All rights reserved.
    </footer>
</body>
</html>
EOL
    
    log_message "✓ Frontend files created successfully"
}

# Setup the database
setup_database() {
    log_message "Step 5: Setting up database..."
    
    # Test database connection
    if ! test_db_connection; then
        log_error "Could not connect to the database. Please check your credentials."
        exit 1
    fi
    
    # Import SQL schema if it exists
    log_message "Importing database schema..."
    mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$PUBLIC_HTML/database.sql"
    check_error "Failed to import database schema"
    
    log_message "✓ Database setup completed successfully"
}

# Setup the Python virtual environment
setup_python_environment() {
    log_message "Step 6: Setting up Python environment..."
    
    # Create virtual environment
    python3 -m venv "$VENV_DIR"
    check_error "Failed to create Python virtual environment"
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip
    check_error "Failed to upgrade pip"
    
    # Install requirements
    pip install -r "$BACKEND_DIR/requirements.txt"
    check_error "Failed to install Python requirements"
    
    log_message "✓ Python environment setup completed successfully"
}

# Create PHP proxy for API
create_php_proxy() {
    log_message "Step 7: Creating PHP proxy for API..."
    
    mkdir -p "$PUBLIC_HTML/api"
    
    # Create PHP proxy
    cat > "$PUBLIC_HTML/api/index.php" << 'EOL'
<?php
/**
 * PHP Proxy for itsyourradio FastAPI Backend
 */

// Backend API URL
$backendUrl = 'http://localhost:8001';

// Get the current URI
$requestUri = isset($_SERVER['REQUEST_URI']) ? $_SERVER['REQUEST_URI'] : '';

// Extract the path after /api/
$path = preg_replace('/^\/api/', '', $requestUri);

// Full URL to the backend
$apiUrl = $backendUrl . '/api' . $path;

// Get HTTP method, headers and body
$method = $_SERVER['REQUEST_METHOD'];
$requestHeaders = getallheaders();
$inputJSON = file_get_contents('php://input');

// Set up cURL request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);

// Set body for POST, PUT, etc.
if ($method === 'POST' || $method === 'PUT' || $method === 'PATCH') {
    curl_setopt($ch, CURLOPT_POSTFIELDS, $inputJSON);
}

// Set headers
$curlHeaders = [];
foreach ($requestHeaders as $key => $value) {
    if ($key != 'Host' && $key != 'Content-Length') {
        $curlHeaders[] = "$key: $value";
    }
}
curl_setopt($ch, CURLOPT_HTTPHEADER, $curlHeaders);

// Execute request
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$contentType = curl_getinfo($ch, CURLINFO_CONTENT_TYPE);
curl_close($ch);

// Set response headers
http_response_code($httpCode);
if ($contentType) {
    header("Content-Type: $contentType");
}

// Output response
echo $response;
EOL
    
    log_message "✓ PHP proxy created successfully"
}

# Create simple index.php fallback
create_php_fallback() {
    log_message "Step 8: Creating PHP fallback..."
    
    # Create a simple index.php as fallback
    cat > "$PUBLIC_HTML/index.php" << 'EOL'
<?php
// Fallback PHP script that serves the static HTML
include 'index.html';
EOL
    
    # Create .htaccess file
    cat > "$PUBLIC_HTML/.htaccess" << 'EOL'
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /

    # If the request is not for a file or directory that exists
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d

    # If the request is not for the API
    RewriteCond %{REQUEST_URI} !^/api/

    # Redirect to index.php
    RewriteRule . /index.php [L]
</IfModule>
EOL
    
    # Set proper permissions
    chmod -R 755 "$PUBLIC_HTML"
    find "$PUBLIC_HTML" -type f -exec chmod 644 {} \;
    
    log_message "✓ PHP fallback created successfully"
}

# Create supervisor configuration
setup_supervisor() {
    log_message "Step 9: Setting up supervisor..."
    
    # Create supervisor configuration
    cat > /etc/supervisor/conf.d/itsyourradio.conf << EOL
[program:itsyourradio_backend]
command=$VENV_DIR/bin/uvicorn server:app --host 0.0.0.0 --port 8001
directory=$BACKEND_DIR
user=radio
group=radio
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=$LOGS_DIR/backend.log
environment=PATH="$VENV_DIR/bin:/usr/local/bin:/usr/bin:/bin",PYTHONPATH="$BACKEND_DIR"
EOL
    
    # Update supervisor
    supervisorctl reread
    supervisorctl update
    supervisorctl restart itsyourradio_backend
    
    log_message "✓ Supervisor configured successfully"
}

# Main deployment function
main() {
    log_message "Starting deployment of itsyourradio..."
    
    # Install Node.js dependencies if needed
    install_node_dependencies
    
    # Setup directories
    setup_directories
    
    # Create database file
    create_database_file
    
    # Create backend files
    create_backend_files
    
    # Setup database
    setup_database
    
    # Setup Python environment
    setup_python_environment
    
    # Create PHP proxy
    create_php_proxy
    
    # Create PHP fallback (instead of building frontend)
    create_php_fallback
    
    # Set up frontend files
    create_frontend_files
    
    # Setup supervisor
    setup_supervisor
    
    # Set proper ownership
    chown -R radio:radio "$WEB_ROOT"
    
    log_message "✓ Deployment completed successfully!"
    log_message "Visit https://$DOMAIN to access your website."
    log_message "Admin credentials: $ADMIN_EMAIL / $ADMIN_PASSWORD"
    log_message "SQL file is available at: $PUBLIC_HTML/database.sql"
}

# Run the deployment
main