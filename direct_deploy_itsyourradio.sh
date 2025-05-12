#!/bin/bash

# itsyourradio Direct Deployment Script
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
echo -e "${BLUE}      itsyourradio Direct Deployment Script            ${NC}"
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
mkdir -p "$PUBLIC_HTML/backend/models"
mkdir -p "$PUBLIC_HTML/backend/utils"
mkdir -p "$PUBLIC_HTML/uploads/"{profile_images,cover_images,album_art,podcast_covers}
mkdir -p "$PUBLIC_HTML/station/"{music,podcasts}
mkdir -p "$PUBLIC_HTML/logs"
mkdir -p "$PUBLIC_HTML/icons"

# Step 3: Create essential files directly
echo -e "\n${BLUE}Step 3: Creating essential files...${NC}"

# Create database.py
echo -e "${YELLOW}Creating database.py...${NC}"
cat > "$PUBLIC_HTML/backend/database.py" << 'EOL'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Get database URL from environment or use a default value
DATABASE_URL = os.environ.get("DATABASE_URL", "mysql+pymysql://user:password@localhost/itsyourradio")

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URL)

# Create session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for SQLAlchemy models
Base = declarative_base()

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOL

# Create SQL models
echo -e "${YELLOW}Creating SQL models...${NC}"
cat > "$PUBLIC_HTML/backend/models/sql_models.py" << 'EOL'
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text, DateTime, Float
from sqlalchemy.orm import relationship
from ..database import Base
import datetime
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    role = Column(String(20), default="member", nullable=False)
    profile_image_url = Column(String(255))
    cover_image_url = Column(String(255))
    bio = Column(Text)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    is_active = Column(Boolean, default=True)

    # Relationships
    albums = relationship("Album", back_populates="artist")
    songs = relationship("Song", back_populates="artist")
    podcast_shows = relationship("PodcastShow", back_populates="host")
    blog_posts = relationship("BlogPost", back_populates="author")
    artist_posts = relationship("ArtistPost", back_populates="artist")


class Album(Base):
    __tablename__ = "albums"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    artist_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    cover_art_url = Column(String(255))
    release_date = Column(DateTime)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    artist = relationship("User", back_populates="albums")
    songs = relationship("Song", back_populates="album")


class Song(Base):
    __tablename__ = "songs"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    artist_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    album_id = Column(String(36), ForeignKey("albums.id"))
    file_path = Column(String(255), nullable=False)
    duration = Column(Float)
    track_number = Column(Integer)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    artist = relationship("User", back_populates="songs")
    album = relationship("Album", back_populates="songs")


class PodcastShow(Base):
    __tablename__ = "podcast_shows"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    host_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    description = Column(Text, nullable=False)
    cover_art_url = Column(String(255))
    category = Column(String(100))
    is_original = Column(Boolean, default=False)
    is_classic = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    host = relationship("User", back_populates="podcast_shows")
    episodes = relationship("PodcastEpisode", back_populates="show")


class PodcastEpisode(Base):
    __tablename__ = "podcast_episodes"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    show_id = Column(String(36), ForeignKey("podcast_shows.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    file_path = Column(String(255), nullable=False)
    duration = Column(Float)
    published_at = Column(DateTime, default=datetime.datetime.utcnow)
    episode_number = Column(Integer)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    show = relationship("PodcastShow", back_populates="episodes")


class BlogPost(Base):
    __tablename__ = "blog_posts"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    author_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    featured_image_url = Column(String(255))
    is_published = Column(Boolean, default=True)
    published_at = Column(DateTime, default=datetime.datetime.utcnow)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    author = relationship("User", back_populates="blog_posts")


class ArtistPost(Base):
    __tablename__ = "artist_posts"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    artist_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    featured_image_url = Column(String(255))
    is_published = Column(Boolean, default=True)
    published_at = Column(DateTime, default=datetime.datetime.utcnow)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    # Relationships
    artist = relationship("User", back_populates="artist_posts")


class MenuItem(Base):
    __tablename__ = "menu_items"

    id = Column(String(36), primary_key=True, index=True, default=generate_uuid)
    label = Column(String(50), nullable=False)
    url = Column(String(255), nullable=False)
    order = Column(Integer, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
EOL

# Create Pydantic models
echo -e "${YELLOW}Creating Pydantic models...${NC}"
cat > "$PUBLIC_HTML/backend/models/pydantic_models.py" << 'EOL'
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from enum import Enum
import uuid
from datetime import datetime

# Define the different user roles
class UserRole(str, Enum):
    ADMIN = "admin"
    STAFF = "staff"
    ARTIST = "artist"
    PODCASTER = "podcaster"
    MEMBER = "member"

# Base user model
class User(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    role: UserRole = UserRole.MEMBER
    profile_image_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    bio: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_active: bool = True
    
    class Config:
        json_schema_extra = {
            "example": {
                "email": "user@example.com",
                "username": "username",
                "full_name": "Full Name",
                "role": "member",
                "profile_image_url": "https://example.com/profile.jpg",
                "cover_image_url": "https://example.com/cover.jpg",
                "bio": "A short biography about the user.",
            }
        }

# User creation model (without ID, created_at, etc.)
class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str
    full_name: Optional[str] = None
    role: UserRole = UserRole.MEMBER

# User update model
class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    profile_image_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    bio: Optional[str] = None
    
# User authentication model
class UserAuth(BaseModel):
    email: EmailStr
    password: str

# User response model (excludes password)
class UserResponse(BaseModel):
    id: str
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    role: UserRole
    profile_image_url: Optional[str] = None
    bio: Optional[str] = None
    created_at: datetime
    
# Token model
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    
# Token data model
class TokenData(BaseModel):
    user_id: Optional[str] = None
    role: Optional[UserRole] = None
EOL

# Create models/__init__.py
echo -e "${YELLOW}Creating models/__init__.py...${NC}"
cat > "$PUBLIC_HTML/backend/models/__init__.py" << 'EOL'
# Import all models for easy access
from .pydantic_models import User, UserCreate, UserUpdate, UserAuth, UserResponse, Token, TokenData, UserRole
EOL

# Create auth.py
echo -e "${YELLOW}Creating auth.py...${NC}"
cat > "$PUBLIC_HTML/backend/utils/auth.py" << 'EOL'
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
import os
from dotenv import load_dotenv
from pathlib import Path
import sys

# Add the current directory to the Python path to allow imports
sys.path.append('/home/radio/web/itsyourradio.com/public_html/backend')

# Now import from models
from models.pydantic_models import TokenData, UserRole

# Load environment variables
env_file = Path('/home/radio/web/itsyourradio.com/public_html/backend/.env')
load_dotenv(env_file)

# Authentication configuration
SECRET_KEY = os.environ.get("SECRET_KEY", "supersecretkeyyoushouldnotcommittogithub")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 token URL (this is the endpoint where the client will request a token)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

def verify_password(plain_password, hashed_password):
    """Verify a password against a hash."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    """Generate a password hash."""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create a new JWT access token."""
    to_encode = data.copy()
    
    # Set expiration time
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
    to_encode.update({"exp": expire})
    
    # Create the JWT token
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme), db=None):
    """Get the current user from the token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Decode the JWT token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        role: str = payload.get("role")
        
        if user_id is None:
            raise credentials_exception
            
        token_data = TokenData(user_id=user_id, role=role)
        
    except JWTError:
        raise credentials_exception
        
    # Get the user from the database
    if db:
        user = await db.users.find_one({"id": token_data.user_id})
        if user is None:
            raise credentials_exception
        return user
        
    return token_data

def get_user_role(current_user=Depends(get_current_user)):
    """Get the role of the current user."""
    return current_user.get("role", UserRole.MEMBER)

# Role-based access control
def has_role(allowed_roles: list):
    """Check if the current user has one of the allowed roles."""
    async def role_checker(current_user=Depends(get_current_user)):
        user_role = current_user.get("role")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return current_user
    return role_checker
EOL

# Create utils/__init__.py
echo -e "${YELLOW}Creating utils/__init__.py...${NC}"
cat > "$PUBLIC_HTML/backend/utils/__init__.py" << 'EOL'
# Import all utilities for easy access
import sys
sys.path.append('/home/radio/web/itsyourradio.com/public_html/backend')
from utils.auth import verify_password, get_password_hash, create_access_token, get_current_user, get_user_role, has_role
EOL

# Create db_init.py with absolute imports
echo -e "${YELLOW}Creating db_init.py...${NC}"
cat > "$PUBLIC_HTML/backend/utils/db_init.py" << 'EOL'
import sys
sys.path.append('/home/radio/web/itsyourradio.com/public_html/backend')

from database import engine, Base, SessionLocal
from models.sql_models import User
from utils.auth import get_password_hash
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
    print("Creating database tables...")
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    print("Adding default admin if it doesn't exist...")
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
        else:
            print("Default admin account already exists")
    except Exception as e:
        db.rollback()
        print(f"Error creating default admin: {e}")
    finally:
        db.close()
EOL

# Create server.py
echo -e "${YELLOW}Creating server.py...${NC}"
cat > "$PUBLIC_HTML/backend/server.py" << 'EOL'
# Import all necessary libraries
import sys
sys.path.append('/home/radio/web/itsyourradio.com/public_html/backend')

from pathlib import Path
from fastapi import FastAPI, APIRouter, Depends, HTTPException, status, File, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
import logging
from typing import List, Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
import uuid

# Load environment variables
ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Import database and models
from database import get_db, engine, Base
from models.sql_models import User, Album, Song, PodcastShow, PodcastEpisode, BlogPost, ArtistPost, MenuItem
from models.pydantic_models import User as PyUser, UserCreate, UserUpdate, UserAuth, UserResponse, Token, TokenData, UserRole
from utils.auth import verify_password, get_password_hash, create_access_token, get_current_user, get_user_role, has_role
from utils.db_init import init_db

# MongoDB connection - replaced by SQLAlchemy
# mongo_url = os.environ['MONGO_URL']
# client = AsyncIOMotorClient(mongo_url)
# db = client[os.environ.get('DB_NAME', 'itsyourradio_db')]

# Create the main app without a prefix
app = FastAPI(title="itsyourradio API")

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Base route
@api_router.get("/")
async def root():
    return {"message": "Welcome to itsyourradio API"}

# --------------------------------
# Health & Status Routes
# --------------------------------
@api_router.get("/health")
async def health_check():
    """Check if the API is healthy."""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

@api_router.get("/stream/info")
async def stream_info():
    """Get information about the radio stream."""
    return {
        "station_name": "itsyourradio",
        "stream_url": "https://example.com:8000/stream",
        "bitrate": "128kbps",
        "format": "audio/mpeg",
        "description": "Your Music, Your Way",
        "status": "online",
        "listeners": 42
    }

@api_router.get("/stream/now-playing")
async def now_playing():
    """Get information about what's currently playing on the radio."""
    return {
        "title": "Summer Vibes",
        "artist": "DJ Cool",
        "album": "Beach Party Mix",
        "cover_art": "https://example.com/covers/summer-vibes.jpg",
        "started_at": (datetime.utcnow() - timedelta(minutes=2)).isoformat(),
        "duration": 240,  # in seconds
        "progress": 120  # in seconds
    }

# --------------------------------
# User Authentication Routes
# --------------------------------
@api_router.post("/auth/register", response_model=UserResponse)
async def register_user(user: UserCreate, db=Depends(get_db)):
    """Register a new user."""
    # Check if user with that email already exists
    existing_user = db.query(User).filter(User.email == user.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
        
    # Check if username is already taken
    existing_username = db.query(User).filter(User.username == user.username).first()
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Create the new user
    hashed_password = get_password_hash(user.password)
    new_user = User(
        id=str(uuid.uuid4()),
        email=user.email,
        username=user.username,
        role=user.role,
        full_name=user.full_name,
        hashed_password=hashed_password
    )
    
    # Add to database
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Return the user response
    return UserResponse(
        id=new_user.id,
        email=new_user.email,
        username=new_user.username,
        full_name=new_user.full_name,
        role=new_user.role,
        profile_image_url=new_user.profile_image_url,
        bio=new_user.bio,
        created_at=new_user.created_at
    )

@api_router.post("/auth/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db=Depends(get_db)):
    """Generate an access token for a user."""
    # Find the user
    user = db.query(User).filter(User.email == form_data.username).first()
    
    # Check if user exists and password is correct
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=30)  # 30 minutes
    access_token = create_access_token(
        data={"sub": user.id, "role": user.role},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@api_router.post("/auth/login", response_model=Token)
async def login(user_auth: UserAuth, db=Depends(get_db)):
    """Login with email and password."""
    # Find the user
    user = db.query(User).filter(User.email == user_auth.email).first()
    
    # Check if user exists and password is correct
    if not user or not verify_password(user_auth.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=30)  # 30 minutes
    access_token = create_access_token(
        data={"sub": user.id, "role": user.role},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

# --------------------------------
# User Profile Routes
# --------------------------------
@api_router.get("/users/me", response_model=UserResponse)
async def get_current_user_profile(current_user = Depends(get_current_user)):
    """Get the current user's profile."""
    # For now, return some sample user data
    return {
        "id": current_user.get("user_id", "12345"),
        "email": "user@example.com",
        "username": "testuser",
        "full_name": "Test User",
        "role": current_user.get("role", "member"),
        "profile_image_url": None,
        "bio": "This is a test user profile.",
        "created_at": datetime.utcnow()
    }

# Include the router in the main app
app.include_router(api_router)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize the application on startup."""
    # Initialize the database tables if they don't exist
    init_db()

# Shutdown event
@app.on_event("shutdown")
async def shutdown_db_client():
    pass  # No need to close SQLAlchemy connections here
EOL

# Create minimal frontend index.html
echo -e "${YELLOW}Creating frontend files...${NC}"
cat > "$PUBLIC_HTML/index.html" << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>itsyourradio</title>
    <style>
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(to bottom, #6D28D9, #111827);
            color: #fff;
            min-height: 100vh;
        }
        header {
            background-color: rgba(0, 0, 0, 0.8);
            padding: 1rem;
            position: fixed;
            width: 100%;
            top: 0;
            z-index: 100;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 1rem;
        }
        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .logo {
            font-size: 1.5rem;
            font-weight: bold;
        }
        main {
            padding-top: 4rem;
            padding-bottom: 6rem;
        }
        .hero {
            text-align: center;
            padding: 4rem 1rem;
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
        }
        .subtitle {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            opacity: 0.8;
        }
        .cta-button {
            background-color: #6D28D9;
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 9999px;
            font-weight: bold;
            cursor: pointer;
            font-size: 1rem;
            transition: background-color 0.2s;
        }
        .cta-button:hover {
            background-color: #5B21B6;
        }
        .player {
            position: fixed;
            bottom: 0;
            width: 100%;
            background-color: #1F2937;
            padding: 1rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .player-controls {
            display: flex;
            align-items: center;
        }
        .play-button {
            width: 40px;
            height: 40px;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #6D28D9;
            border-radius: 50%;
            margin-right: 1rem;
            cursor: pointer;
        }
        .track-info {
            flex: 1;
        }
        .track-title {
            font-weight: bold;
            margin-bottom: 0.25rem;
        }
        .track-artist {
            font-size: 0.875rem;
            opacity: 0.7;
        }
        .player-volume {
            width: 100px;
        }
        @media (max-width: 768px) {
            .player {
                flex-direction: column;
                align-items: flex-start;
            }
            .player-controls {
                margin-bottom: 0.5rem;
            }
        }
    </style>
</head>
<body>
    <header>
        <div class="container">
            <div class="header-content">
                <div class="logo">itsyourradio</div>
                <nav>
                    <!-- Navigation menu will go here -->
                </nav>
            </div>
        </div>
    </header>

    <main>
        <div class="container">
            <section class="hero">
                <h1>itsyourradio</h1>
                <p class="subtitle">Your Music, Your Way</p>
                <button class="cta-button">Listen Live</button>
            </section>
        </div>
    </main>

    <div class="player">
        <div class="player-controls">
            <div class="play-button">▶</div>
            <div class="track-info">
                <div class="track-title">Live Stream</div>
                <div class="track-artist">itsyourradio</div>
            </div>
        </div>
        <input type="range" class="player-volume" min="0" max="100" value="80">
    </div>

    <script>
        // Simple player toggle
        const playButton = document.querySelector('.play-button');
        let isPlaying = false;

        playButton.addEventListener('click', () => {
            isPlaying = !isPlaying;
            playButton.innerHTML = isPlaying ? '❚❚' : '▶';
        });

        // CTA button also toggles player
        const ctaButton = document.querySelector('.cta-button');
        ctaButton.addEventListener('click', () => {
            isPlaying = !isPlaying;
            playButton.innerHTML = isPlaying ? '❚❚' : '▶';
            if (isPlaying) {
                ctaButton.textContent = 'Pause Stream';
            } else {
                ctaButton.textContent = 'Listen Live';
            }
        });
    </script>
</body>
</html>
EOL

# Create README-ASSETS.md
echo -e "${YELLOW}Creating README-ASSETS.md...${NC}"
cat > "$PUBLIC_HTML/README-ASSETS.md" << 'EOL'
# Asset Placement Instructions for itsyourradio

## PWA Icons

Place the following icon files in the `/public_html/icons/` directory:

- `icon-72x72.png` (72x72 pixels)
- `icon-96x96.png` (96x96 pixels)
- `icon-128x128.png` (128x128 pixels)
- `icon-144x144.png` (144x144 pixels)
- `icon-152x152.png` (152x152 pixels)
- `icon-192x192.png` (192x192 pixels)
- `icon-384x384.png` (384x384 pixels)
- `icon-512x512.png` (512x512 pixels)
- `splash-screen.png` (1242x2688 pixels - for iOS splash screen)

All icons should be in PNG format with a transparent background. The design should be consistent across all sizes, with the itsyourradio logo centered.

## Logo Files

Place the following logo files in the `/public_html/` directory:

- `logo.png` - Primary logo (used in the header)
- `favicon.ico` - Website favicon (16x16, 32x32, and 48x48 combined)
- `logo-dark.png` - Dark version of logo (used in emails and light backgrounds)
- `default-album-art.jpg` - Default album art when none is provided (500x500 pixels)

## Media Storage Folders

The following directories will be automatically created for storing uploaded content:

- `/public_html/uploads/profile_images/` - User profile images
- `/public_html/uploads/cover_images/` - Cover images for artists and profiles
- `/public_html/uploads/album_art/` - Album artwork
- `/public_html/uploads/podcast_covers/` - Podcast show artwork
- `/public_html/station/music/` - Uploaded music files (organized by artist/album)
- `/public_html/station/podcasts/` - Uploaded podcast episodes

## Stream Configuration

To configure your Shoutcast/Icecast stream URL:

Edit the server.py file to update the stream_info function with your actual stream URL:

```python
@api_router.get("/stream/info")
async def stream_info():
    """Get information about the radio stream."""
    return {
        "station_name": "itsyourradio",
        "stream_url": "https://your-actual-stream-url:8000/stream",
        "bitrate": "128kbps",
        "format": "audio/mpeg",
        "description": "Your Music, Your Way",
        "status": "online",
        "listeners": 42
    }
```

Replace `https://your-actual-stream-url:8000/stream` with your actual Shoutcast/Icecast server URL.

## Default Admin Account

The default admin account credentials are:

- Email: admin@itsyourradio.com
- Password: IYR_admin_2025!

**Important:** Change these credentials immediately after your first login for security purposes.
EOL

# Set proper permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
chmod -R 755 "$PUBLIC_HTML/uploads"
chmod -R 755 "$PUBLIC_HTML/station"
chown -R "$USER":"$USER" "$PUBLIC_HTML"
success_step "Directory structure and essential files created successfully"

# Step 4: Set up Python virtual environment and install dependencies
echo -e "\n${BLUE}Step 4: Setting up Python virtual environment...${NC}"

# Create virtual environment
echo -e "${YELLOW}Creating Python virtual environment...${NC}"
python3 -m venv "$VENV_PATH" || handle_error "Failed to create virtual environment"

# Install Python dependencies in virtual environment
echo -e "${YELLOW}Installing Python dependencies in virtual environment...${NC}"
"$VENV_PATH/bin/pip" install --upgrade pip || warn "Failed to upgrade pip in virtual environment"
"$VENV_PATH/bin/pip" install fastapi uvicorn sqlalchemy pymysql python-jose[cryptography] passlib[bcrypt] python-multipart python-dotenv email-validator pydantic[email] || handle_error "Failed to install Python dependencies in virtual environment"

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

# Initialize database
echo -e "${YELLOW}Initializing database...${NC}"
cd "$PUBLIC_HTML/backend" || handle_error "Failed to change to backend directory"

# Run database initialization using the virtual environment Python
"$VENV_PATH/bin/python" -c "import sys; sys.path.append('$PUBLIC_HTML/backend'); from utils.db_init import init_db; init_db()" || handle_error "Failed to initialize database"

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

check_file "$PUBLIC_HTML/index.html"
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
echo -e "${GREEN}For more details, refer to README-ASSETS.md${NC}"
echo -e "${GREEN}in the $PUBLIC_HTML directory.${NC}"
echo
echo -e "${BLUE}Python Virtual Environment:${NC}"
echo -e "The application is using a Python virtual environment at: ${YELLOW}$VENV_PATH${NC}"
echo -e "If you need to run Python commands manually, use: ${YELLOW}$VENV_PATH/bin/python${NC}"
