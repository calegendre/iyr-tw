#!/bin/bash

# itsyourradio Complete Deployment Script
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
    log_message "Setting up Node.js and package manager..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_message "Node.js not found. Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
        check_error "Failed to install Node.js"
    fi
    
    # Check Node.js version
    node_version=$(node -v)
    log_message "Node.js version: $node_version"
    
    # Try to install Yarn
    if ! command -v yarn &> /dev/null; then
        log_message "Yarn not found. Installing Yarn..."
        npm install -g yarn
        
        # Double check if Yarn was installed
        if command -v yarn &> /dev/null; then
            log_message "✓ Yarn installed successfully"
            PACKAGE_MANAGER="yarn"
        else
            log_warning "Failed to install Yarn. Falling back to npm."
            PACKAGE_MANAGER="npm"
        fi
    else
        log_message "✓ Yarn is already installed"
        PACKAGE_MANAGER="yarn"
    fi
    
    # Export package manager for other functions
    export PACKAGE_MANAGER
    
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
    mkdir -p "$FRONTEND_SRC/src/components"
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
    
    # Create package.json
    cat > "$FRONTEND_SRC/package.json" << 'EOL'
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
    
    # Create .env file for frontend
    cat > "$FRONTEND_SRC/.env" << EOL
REACT_APP_BACKEND_URL=https://$DOMAIN
EOL
    
    # Create tailwind.config.js
    cat > "$FRONTEND_SRC/tailwind.config.js" << 'EOL'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL
    
    # Create postcss.config.js
    cat > "$FRONTEND_SRC/postcss.config.js" << 'EOL'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOL
    
    # Create index.css
    cat > "$FRONTEND_SRC/src/index.css" << 'EOL'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOL
    
    # Create index.js
    cat > "$FRONTEND_SRC/src/index.js" << 'EOL'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOL
    
    # Create App.css
    cat > "$FRONTEND_SRC/src/App.css" << 'EOL'
.App {
  text-align: left;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background-color: #f8f9fa;
  color: #333;
}

a {
  text-decoration: none;
  color: inherit;
}

/* Header and Navigation */
header.bg-gray-900 {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

/* Audio Player */
.range-input {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 4px;
  background: #d3d3d3;
  outline: none;
  border-radius: 4px;
}

.range-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 12px;
  height: 12px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
}

.range-input::-moz-range-thumb {
  width: 12px;
  height: 12px;
  background: white;
  border-radius: 50%;
  cursor: pointer;
  border: none;
}

/* Card Hover Effects */
.card-hover {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.card-hover:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
}

/* Button Styles */
.btn-primary {
  background-color: #6d28d9;
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-weight: 600;
  transition: background-color 0.3s ease;
}

.btn-primary:hover {
  background-color: #5b21b6;
}

.btn-outline {
  background-color: transparent;
  color: #6d28d9;
  border: 1px solid #6d28d9;
  padding: 0.5rem 1rem;
  border-radius: 0.375rem;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-outline:hover {
  background-color: #6d28d9;
  color: white;
}

/* Hero Section */
.hero-section {
  position: relative;
  overflow: hidden;
  border-radius: 0.5rem;
}

.hero-section::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(to right, rgba(109, 40, 217, 0.8), rgba(79, 70, 229, 0.8));
  z-index: -1;
}

/* Footer Styles */
footer.bg-gray-900 {
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

footer a:hover {
  color: white;
  transition: color 0.3s ease;
}
EOL
    
    # Create MediaPlayer component
    cat > "$FRONTEND_SRC/src/components/MediaPlayer.js" << 'EOL'
import React, { useState, useEffect, useRef, useContext } from "react";
import { AudioPlayerContext } from "../App";

const MediaPlayer = () => {
  const {
    isPlaying,
    currentTrack,
    volume,
    audioRef,
    pauseTrack,
    resumeTrack,
    setAudioVolume,
  } = useContext(AudioPlayerContext);

  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const progressRef = useRef(null);

  // Format time in MM:SS
  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);
    return `${minutes}:${remainingSeconds < 10 ? "0" : ""}${remainingSeconds}`;
  };

  // Set up audio element and listeners
  useEffect(() => {
    if (!audioRef.current) {
      audioRef.current = new Audio();
      audioRef.current.volume = volume / 100;
    }

    const setAudioData = () => {
      setDuration(audioRef.current.duration);
    };

    const setAudioProgress = () => {
      setCurrentTime(audioRef.current.currentTime);
      setProgress((audioRef.current.currentTime / audioRef.current.duration) * 100);
    };

    const onEnded = () => {
      setProgress(0);
      setCurrentTime(0);
      pauseTrack();
    };

    // Add event listeners
    audioRef.current.addEventListener("loadeddata", setAudioData);
    audioRef.current.addEventListener("timeupdate", setAudioProgress);
    audioRef.current.addEventListener("ended", onEnded);

    // Clean up
    return () => {
      audioRef.current.removeEventListener("loadeddata", setAudioData);
      audioRef.current.removeEventListener("timeupdate", setAudioProgress);
      audioRef.current.removeEventListener("ended", onEnded);
    };
  }, [audioRef, pauseTrack, volume]);

  // Update when track changes
  useEffect(() => {
    if (currentTrack && audioRef.current) {
      audioRef.current.src = currentTrack.audioUrl;
      audioRef.current.load();
      if (isPlaying) {
        audioRef.current.play();
      }
    }
  }, [currentTrack, isPlaying, audioRef]);

  // Handle play/pause
  useEffect(() => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.play();
      } else {
        audioRef.current.pause();
      }
    }
  }, [isPlaying, audioRef]);

  // Handle volume change
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume / 100;
    }
  }, [volume, audioRef]);

  // Handle seeking
  const handleProgressChange = (e) => {
    const newProgress = e.target.value;
    setProgress(newProgress);
    audioRef.current.currentTime = (newProgress / 100) * duration;
  };

  if (!currentTrack) return null;

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-800 text-white p-2 z-50">
      <div className="container mx-auto flex flex-col md:flex-row items-center justify-between px-4">
        <div className="flex items-center w-full md:w-auto mb-2 md:mb-0">
          {currentTrack.coverImage && (
            <img
              src={currentTrack.coverImage}
              alt={currentTrack.title}
              className="w-12 h-12 mr-4 rounded"
            />
          )}
          <div className="truncate">
            <div className="font-semibold truncate">{currentTrack.title}</div>
            <div className="text-sm text-gray-400 truncate">{currentTrack.artist}</div>
          </div>
        </div>

        <div className="flex flex-col w-full md:w-1/2">
          <div className="flex items-center justify-center mb-1">
            <button
              onClick={isPlaying ? pauseTrack : resumeTrack}
              className="p-2 mx-4 rounded-full bg-white text-gray-800 focus:outline-none hover:bg-gray-200"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              {isPlaying ? "⏸" : "▶️"}
            </button>
          </div>

          <div className="flex items-center space-x-2 w-full">
            <span className="text-xs">{formatTime(currentTime)}</span>
            <input
              ref={progressRef}
              type="range"
              className="range-input flex-grow"
              value={progress}
              onChange={handleProgressChange}
              min="0"
              max="100"
              step="0.1"
            />
            <span className="text-xs">{formatTime(duration)}</span>
          </div>
        </div>

        <div className="flex items-center mt-2 md:mt-0">
          <span className="mr-2 text-xs">
            {volume > 0 ? "🔊" : "🔇"}
          </span>
          <input
            type="range"
            className="range-input w-20"
            value={volume}
            onChange={(e) => setAudioVolume(parseInt(e.target.value))}
            min="0"
            max="100"
            aria-label="Volume"
          />
        </div>
      </div>
    </div>
  );
};

export default MediaPlayer;
EOL
    
    # Create mock data file
    cat > "$FRONTEND_SRC/src/mockData.js" << 'EOL'
export const mockArtists = [
  {
    id: "1",
    name: "TNGHT",
    genre: "Electronic",
    image: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    bio: "TNGHT is a collaborative project between producers Hudson Mohawke and Lunice."
  },
  {
    id: "2",
    name: "Portishead",
    genre: "Trip Hop",
    image: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60", 
    bio: "Portishead are an English band formed in 1991 in Bristol."
  },
  {
    id: "3",
    name: "Massive Attack",
    genre: "Trip Hop",
    image: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    bio: "Massive Attack are a British musical collective formed in 1988 in Bristol."
  },
  {
    id: "4",
    name: "Bonobo",
    genre: "Electronic",
    image: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    bio: "Bonobo is the stage name of British musician, producer and DJ Simon Green."
  }
];

export const mockTracks = [
  {
    id: "101",
    title: "Higher Ground",
    artist: "TNGHT",
    artistId: "1",
    albumId: "201",
    coverImage: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/tnght/higher-ground",
    duration: 182
  },
  {
    id: "102",
    title: "Glory Box",
    artist: "Portishead",
    artistId: "2",
    albumId: "202",
    coverImage: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/portishead/glory-box",
    duration: 300
  },
  {
    id: "103",
    title: "Teardrop",
    artist: "Massive Attack",
    artistId: "3",
    albumId: "203",
    coverImage: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/massiveattack/teardrop",
    duration: 330
  },
  {
    id: "104",
    title: "Kerala",
    artist: "Bonobo",
    artistId: "4",
    albumId: "204",
    coverImage: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    audioUrl: "https://soundcloud.com/bonobo/kerala",
    duration: 245
  }
];

export const mockAlbums = [
  {
    id: "201",
    title: "TNGHT EP",
    artist: "TNGHT",
    artistId: "1",
    coverImage: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    releaseDate: "2012-07-23",
    trackIds: ["101"]
  },
  {
    id: "202",
    title: "Dummy",
    artist: "Portishead",
    artistId: "2",
    coverImage: "https://images.unsplash.com/photo-1528489290189-1174a4c24021?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "1994-08-22",
    trackIds: ["102"]
  },
  {
    id: "203",
    title: "Mezzanine",
    artist: "Massive Attack",
    artistId: "3",
    coverImage: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8dHJpcCUyMGhvcHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "1998-04-20",
    trackIds: ["103"]
  },
  {
    id: "204",
    title: "Migration",
    artist: "Bonobo",
    artistId: "4",
    coverImage: "https://images.unsplash.com/photo-1554474252-e6956231dd4c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTZ8fGVsZWN0cm9uaWMlMjBtdXNpY3xlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    releaseDate: "2017-01-13",
    trackIds: ["104"]
  }
];

export const mockPodcasts = [
  {
    id: "301",
    title: "Radio Stories",
    host: "Sarah Johnson",
    coverImage: "https://images.unsplash.com/photo-1524254994761-171214f567f3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8cG9kY2FzdHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60",
    description: "Exploring the stories behind the music and the radio industry.",
    latestEpisode: {
      title: "The Future of Radio",
      publishedAt: "2023-04-15"
    }
  },
  {
    id: "302",
    title: "Music Theory",
    host: "David Wilson",
    coverImage: "https://images.unsplash.com/photo-1551817272-cad54b74b273?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NXx8bXVzaWMlMjB0aGVvcnl8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    description: "Exploring music theory concepts for musicians at all levels.",
    latestEpisode: {
      title: "Understanding Modal Interchange",
      publishedAt: "2023-04-10"
    }
  },
  {
    id: "303",
    title: "Artist Interviews",
    host: "Maya Rodriguez",
    coverImage: "https://images.unsplash.com/photo-1547156979-b57c6439f174?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8aW50ZXJ2aWV3fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    description: "In-depth interviews with artists about their creative process.",
    latestEpisode: {
      title: "The Creative Process with TNGHT",
      publishedAt: "2023-04-05"
    }
  }
];

export const mockBlogPosts = [
  {
    id: "401",
    title: "The Evolution of Electronic Music",
    author: "Admin",
    authorId: "admin",
    publishedAt: "2023-04-01",
    featuredImage: "https://images.unsplash.com/photo-1571330735066-03aaa9429d89?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8ZWxlY3Ryb25pYyUyMG11c2ljfGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60",
    excerpt: "Exploring how electronic music has evolved over the decades and its influence on popular culture.",
    content: "Electronic music has come a long way since the early experiments with synthesizers and tape loops..."
  },
  {
    id: "402",
    title: "The Rise of Indie Radio",
    author: "Sarah Johnson",
    authorId: "sarah",
    publishedAt: "2023-03-25",
    featuredImage: "https://images.unsplash.com/photo-1589398907430-a7b688975b6c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8cmFkaW98ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    excerpt: "How independent radio stations are making a comeback in the age of streaming.",
    content: "In an era dominated by streaming platforms, independent radio stations are experiencing a renaissance..."
  },
  {
    id: "403",
    title: "Behind the Scenes: Podcast Production",
    author: "David Wilson",
    authorId: "david",
    publishedAt: "2023-03-20",
    featuredImage: "https://images.unsplash.com/photo-1590602847861-f357a9332bbc?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fHBvZGNhc3R8ZW58MHx8MHx8fDA%3D&auto=format&fit=crop&w=500&q=60",
    excerpt: "A look at what goes into producing a professional podcast.",
    content: "Creating a successful podcast involves much more than just recording a conversation..."
  }
];
EOL
    
    # Create App.js
    cat > "$FRONTEND_SRC/src/App.js" << 'EOL'
import { useEffect, useState, createContext, useRef, useContext } from "react";
import "./App.css";
import { BrowserRouter, Routes, Route, Link, Navigate } from "react-router-dom";
import axios from "axios";
import MediaPlayer from "./components/MediaPlayer";
import {
  mockArtists,
  mockTracks,
  mockAlbums,
  mockPodcasts,
  mockBlogPosts
} from "./mockData";

// Context for authentication
export const AuthContext = createContext();

// Backend URL from environment variables
const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

// Audio player context
export const AudioPlayerContext = createContext();

// Layout component with persistent audio player
const Layout = ({ children }) => {
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTrack, setCurrentTrack] = useState(null);
  const [volume, setVolume] = useState(80);
  const audioRef = useRef(null);

  const playTrack = (track) => {
    setCurrentTrack(track);
    setIsPlaying(true);
  };

  const pauseTrack = () => {
    setIsPlaying(false);
  };

  const resumeTrack = () => {
    setIsPlaying(true);
  };

  const setAudioVolume = (newVolume) => {
    setVolume(newVolume);
    if (audioRef.current) {
      audioRef.current.volume = newVolume / 100;
    }
  };

  return (
    <AudioPlayerContext.Provider
      value={{
        isPlaying,
        currentTrack,
        volume,
        audioRef,
        playTrack,
        pauseTrack,
        resumeTrack,
        setAudioVolume,
      }}
    >
      <div className="flex flex-col min-h-screen">
        <header className="bg-gray-900 text-white">
          <div className="container mx-auto flex justify-between items-center p-4">
            <div className="flex items-center">
              <Link to="/" className="text-2xl font-bold">
                itsyourradio
              </Link>
            </div>
            <nav>
              <ul className="flex space-x-4">
                <li>
                  <Link to="/" className="hover:text-gray-300">
                    Home
                  </Link>
                </li>
                <li>
                  <Link to="/artists" className="hover:text-gray-300">
                    Artists
                  </Link>
                </li>
                <li>
                  <Link to="/podcasts" className="hover:text-gray-300">
                    Podcasts
                  </Link>
                </li>
                <li>
                  <Link to="/blog" className="hover:text-gray-300">
                    Blog
                  </Link>
                </li>
              </ul>
            </nav>
          </div>
        </header>

        <main className="flex-grow">
          {children}
        </main>

        {/* Persistent Audio Player */}
        <MediaPlayer />

        <footer className="bg-gray-900 text-white py-8">
          <div className="container mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div>
                <h3 className="text-lg font-semibold mb-4">About Us</h3>
                <p className="text-gray-400">
                  itsyourradio is a platform for artists and podcasters to share their content with the world.
                </p>
              </div>
              <div>
                <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
                <ul className="space-y-2 text-gray-400">
                  <li>
                    <Link to="/about" className="hover:text-white">
                      About
                    </Link>
                  </li>
                  <li>
                    <Link to="/contact" className="hover:text-white">
                      Contact
                    </Link>
                  </li>
                  <li>
                    <Link to="/privacy" className="hover:text-white">
                      Privacy Policy
                    </Link>
                  </li>
                  <li>
                    <Link to="/terms" className="hover:text-white">
                      Terms of Service
                    </Link>
                  </li>
                </ul>
              </div>
              <div>
                <h3 className="text-lg font-semibold mb-4">Connect With Us</h3>
                <div className="flex space-x-4">
                  <a href="#" className="text-gray-400 hover:text-white">
                    Facebook
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white">
                    Twitter
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white">
                    Instagram
                  </a>
                </div>
              </div>
            </div>
            <div className="mt-8 pt-8 border-t border-gray-800 text-center text-gray-400">
              <p>&copy; {new Date().getFullYear()} itsyourradio. All rights reserved.</p>
            </div>
          </div>
        </footer>
      </div>
    </AudioPlayerContext.Provider>
  );
};

// Home page component
const Home = () => {
  const [message, setMessage] = useState("");
  const { playTrack } = useContext(AudioPlayerContext);
  const [featuredArtists, setFeaturedArtists] = useState([]);
  const [latestPodcasts, setLatestPodcasts] = useState([]);
  const [recentPosts, setRecentPosts] = useState([]);

  const fetchData = async () => {
    try {
      const response = await axios.get(`${API}/`);
      setMessage(response.data.message);
      
      // In a real application, we would fetch this data from the API
      // For now, we'll use the mock data
      setFeaturedArtists(mockArtists.slice(0, 4));
      setLatestPodcasts(mockPodcasts.slice(0, 3));
      setRecentPosts(mockBlogPosts.slice(0, 3));
    } catch (e) {
      console.error(e, `Error fetching data from API`);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handlePlayTrack = (artistId) => {
    const track = mockTracks.find(track => track.artistId === artistId);
    if (track) {
      playTrack(track);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <section className="mb-12">
        <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg p-8 shadow-xl">
          <h1 className="text-4xl font-bold mb-4">Welcome to itsyourradio</h1>
          <p className="text-xl mb-6">Your place for the best music and podcasts.</p>
          <p className="mb-6">API Message: {message}</p>
          <div className="flex space-x-4">
            <Link
              to="/artists"
              className="bg-white text-purple-600 px-6 py-2 rounded-full font-semibold hover:bg-gray-100 transition-colors"
            >
              Explore Artists
            </Link>
            <Link
              to="/podcasts"
              className="bg-transparent border border-white text-white px-6 py-2 rounded-full font-semibold hover:bg-white hover:text-purple-600 transition-colors"
            >
              Discover Podcasts
            </Link>
          </div>
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-3xl font-bold mb-6">Featured Artists</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {featuredArtists.map(artist => (
            <div key={artist.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center cursor-pointer" 
                style={{ backgroundImage: `url(${artist.image})` }}
                onClick={() => handlePlayTrack(artist.id)}
              >
                <div className="flex justify-center items-center h-full bg-black bg-opacity-50 opacity-0 hover:opacity-100 transition-opacity rounded-md">
                  <div className="text-white text-xl">▶️ Play</div>
                </div>
              </div>
              <h3 className="text-xl font-semibold">{artist.name}</h3>
              <p className="text-gray-600">{artist.genre}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="mb-12">
        <h2 className="text-3xl font-bold mb-6">Latest Podcasts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {latestPodcasts.map(podcast => (
            <div key={podcast.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
                style={{ backgroundImage: `url(${podcast.coverImage})` }}
              ></div>
              <h3 className="text-xl font-semibold">{podcast.title}</h3>
              <p className="text-gray-600">{podcast.host}</p>
              <p className="text-gray-500 text-sm mt-2">Latest Episode: {podcast.latestEpisode.title}</p>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="text-3xl font-bold mb-6">Recent Blog Posts</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {recentPosts.map(post => (
            <div key={post.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
              <div 
                className="h-48 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
                style={{ backgroundImage: `url(${post.featuredImage})` }}
              ></div>
              <h3 className="text-xl font-semibold">{post.title}</h3>
              <p className="text-gray-600">{post.author}</p>
              <p className="text-gray-500 text-sm mt-2">Published: {post.publishedAt}</p>
              <p className="mt-2">{post.excerpt}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
};

// Artists page (with data)
const Artists = () => {
  const { playTrack } = useContext(AudioPlayerContext);
  const [artists, setArtists] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setArtists(mockArtists);
  }, []);

  const handlePlayTrack = (artistId) => {
    const track = mockTracks.find(track => track.artistId === artistId);
    if (track) {
      playTrack(track);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Artists</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {artists.map(artist => (
          <div key={artist.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center cursor-pointer" 
              style={{ backgroundImage: `url(${artist.image})` }}
              onClick={() => handlePlayTrack(artist.id)}
            >
              <div className="flex justify-center items-center h-full bg-black bg-opacity-50 opacity-0 hover:opacity-100 transition-opacity rounded-md">
                <div className="text-white text-xl">▶️ Play</div>
              </div>
            </div>
            <h3 className="text-xl font-semibold">{artist.name}</h3>
            <p className="text-gray-600">{artist.genre}</p>
            <p className="mt-2 text-gray-700">{artist.bio}</p>
            <div className="mt-4">
              <Link 
                to={`/artists/${artist.id}`} 
                className="text-purple-600 hover:text-purple-800 font-medium"
              >
                View Profile
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Podcasts page (with data)
const Podcasts = () => {
  const [podcasts, setPodcasts] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setPodcasts(mockPodcasts);
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Podcasts</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {podcasts.map(podcast => (
          <div key={podcast.id} className="bg-white p-4 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
              style={{ backgroundImage: `url(${podcast.coverImage})` }}
            ></div>
            <h3 className="text-xl font-semibold">{podcast.title}</h3>
            <p className="text-gray-600">Host: {podcast.host}</p>
            <p className="mt-2 text-gray-700">{podcast.description}</p>
            <div className="mt-4 p-3 bg-gray-100 rounded-md">
              <p className="font-medium">Latest Episode:</p>
              <p className="text-gray-700">{podcast.latestEpisode.title}</p>
              <p className="text-gray-500 text-sm">Released: {podcast.latestEpisode.publishedAt}</p>
            </div>
            <div className="mt-4">
              <Link 
                to={`/podcasts/${podcast.id}`} 
                className="text-purple-600 hover:text-purple-800 font-medium"
              >
                Listen Now
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Blog page (with data)
const Blog = () => {
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    // In a real application, we would fetch this data from the API
    // For now, we'll use the mock data
    setPosts(mockBlogPosts);
  }, []);

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Blog</h1>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {posts.map(post => (
          <div key={post.id} className="bg-white p-6 rounded-lg shadow-md hover:shadow-lg transition-shadow">
            <div 
              className="h-64 bg-gray-200 rounded-md mb-4 bg-cover bg-center" 
              style={{ backgroundImage: `url(${post.featuredImage})` }}
            ></div>
            <h2 className="text-2xl font-bold mb-2">{post.title}</h2>
            <div className="flex items-center text-gray-600 mb-4">
              <span>{post.author}</span>
              <span className="mx-2">•</span>
              <span>{post.publishedAt}</span>
            </div>
            <p className="text-gray-700 mb-4">{post.excerpt}</p>
            <Link 
              to={`/blog/${post.id}`} 
              className="inline-block bg-purple-600 text-white px-4 py-2 rounded-md hover:bg-purple-700 transition-colors"
            >
              Read More
            </Link>
          </div>
        ))}
      </div>
    </div>
  );
};

// Main App component
function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Check if user is authenticated on app load
  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) {
      // Verify token validity with backend
      const verifyToken = async () => {
        try {
          const response = await axios.get(`${API}/auth/me`, {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          });
          setUser(response.data);
          setIsAuthenticated(true);
        } catch (error) {
          console.error("Token verification failed:", error);
          localStorage.removeItem("token");
        } finally {
          setLoading(false);
        }
      };
      verifyToken();
    } else {
      setLoading(false);
    }
  }, []);

  // Login function
  const login = async (email, password) => {
    try {
      const response = await axios.post(`${API}/auth/token`, {
        username: email,
        password: password,
      });
      const { access_token } = response.data;
      localStorage.setItem("token", access_token);
      
      // Get user data
      const userResponse = await axios.get(`${API}/auth/me`, {
        headers: {
          Authorization: `Bearer ${access_token}`,
        },
      });
      setUser(userResponse.data);
      setIsAuthenticated(true);
      return true;
    } catch (error) {
      console.error("Login failed:", error);
      return false;
    }
  };

  // Logout function
  const logout = () => {
    localStorage.removeItem("token");
    setUser(null);
    setIsAuthenticated(false);
  };

  if (loading) {
    return <div className="flex items-center justify-center h-screen">Loading...</div>;
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated, user, login, logout }}>
      <div className="App">
        <BrowserRouter>
          <Layout>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/artists" element={<Artists />} />
              <Route path="/podcasts" element={<Podcasts />} />
              <Route path="/blog" element={<Blog />} />
              {/* Add more routes as needed */}
            </Routes>
          </Layout>
        </BrowserRouter>
      </div>
    </AuthContext.Provider>
  );
}

export default App;
EOL
    
    # Create index.html
    cat > "$FRONTEND_SRC/public/index.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="itsyourradio - Your place for the best music and podcasts"
    />
    <link rel="apple-touch-icon" href="%PUBLIC_URL%/logo192.png" />
    <link rel="manifest" href="%PUBLIC_URL%/manifest.json" />
    <title>itsyourradio</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOL
    
    # Create manifest.json
    cat > "$FRONTEND_SRC/public/manifest.json" << 'EOL'
{
  "short_name": "itsyourradio",
  "name": "itsyourradio - Your place for the best music and podcasts",
  "icons": [
    {
      "src": "favicon.ico",
      "sizes": "64x64 32x32 24x24 16x16",
      "type": "image/x-icon"
    },
    {
      "src": "logo192.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "logo512.png",
      "type": "image/png",
      "sizes": "512x512"
    }
  ],
  "start_url": ".",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#ffffff"
}
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

# Build the frontend
build_frontend() {
    log_message "Step 8: Building frontend..."
    
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

    # Redirect to index.html
    RewriteRule . /index.html [L]
</IfModule>
EOL
    
    # Go to the frontend directory
    cd "$FRONTEND_SRC"
    
    log_message "Installing Node.js dependencies..."
    
    if [ "$PACKAGE_MANAGER" = "yarn" ]; then
        # Use Yarn
        yarn install
        check_error "Failed to install Node.js dependencies with Yarn"
        
        # Build the frontend
        yarn build
        check_error "Failed to build frontend with Yarn"
    else
        # Use npm
        npm install
        check_error "Failed to install Node.js dependencies with npm"
        
        # Build the frontend
        npm run build
        check_error "Failed to build frontend with npm"
    fi
    
    # Copy the build files to the public_html directory
    cp -r build/* "$PUBLIC_HTML/"
    check_error "Failed to copy frontend build files"
    
    # Set proper permissions
    chmod -R 755 "$PUBLIC_HTML"
    find "$PUBLIC_HTML" -type f -exec chmod 644 {} \;
    
    log_message "✓ Frontend built successfully"
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
    
    # Create frontend files
    create_frontend_files
    
    # Build frontend
    build_frontend
    
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