from pydantic import BaseModel, Field
from typing import Optional, List
import uuid
from datetime import datetime

# Blog post model
class BlogPost(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    content: str
    author_id: str
    featured_image_url: Optional[str] = None
    is_published: bool = True
    published_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
# Blog post creation model
class BlogPostCreate(BaseModel):
    title: str
    content: str
    author_id: str
    featured_image_url: Optional[str] = None
    is_published: bool = True
    published_at: Optional[datetime] = None

# Blog post update model
class BlogPostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    featured_image_url: Optional[str] = None
    is_published: Optional[bool] = None
    published_at: Optional[datetime] = None

# Artist blog post model (for artist mini-blogs)
class ArtistPost(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    artist_id: str
    title: str
    content: str
    featured_image_url: Optional[str] = None
    is_published: bool = True
    published_at: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Artist blog post creation model
class ArtistPostCreate(BaseModel):
    artist_id: str
    title: str
    content: str
    featured_image_url: Optional[str] = None
    is_published: bool = True
    published_at: Optional[datetime] = None

# Artist blog post update model
class ArtistPostUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    featured_image_url: Optional[str] = None
    is_published: Optional[bool] = None
    published_at: Optional[datetime] = None
