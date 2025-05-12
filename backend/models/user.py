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
