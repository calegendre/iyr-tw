from pydantic import BaseModel, Field
from typing import Optional, List
import uuid
from datetime import datetime

# Album model
class Album(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    artist_id: str
    cover_art_url: Optional[str] = None
    release_date: Optional[datetime] = None
    description: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Album creation model
class AlbumCreate(BaseModel):
    title: str
    artist_id: str
    cover_art_url: Optional[str] = None
    release_date: Optional[datetime] = None
    description: Optional[str] = None

# Song model
class Song(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    artist_id: str
    album_id: Optional[str] = None
    file_path: str
    duration: Optional[float] = None
    track_number: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Song creation model
class SongCreate(BaseModel):
    title: str
    artist_id: str
    album_id: Optional[str] = None
    file_path: str
    duration: Optional[float] = None
    track_number: Optional[int] = None

# Podcast show model
class PodcastShow(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    title: str
    host_id: str
    description: str
    cover_art_url: Optional[str] = None
    category: Optional[str] = None
    is_original: bool = False  # Whether it's an "IYR Original"
    is_classic: bool = False   # Whether it's an "IYR Classic"
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# Podcast show creation model
class PodcastShowCreate(BaseModel):
    title: str
    host_id: str
    description: str
    cover_art_url: Optional[str] = None
    category: Optional[str] = None
    is_original: bool = False
    is_classic: bool = False

# Podcast episode model
class PodcastEpisode(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    show_id: str
    title: str
    description: str
    file_path: str
    duration: Optional[float] = None
    published_at: datetime = Field(default_factory=datetime.utcnow)
    episode_number: Optional[int] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
# Podcast episode creation model
class PodcastEpisodeCreate(BaseModel):
    show_id: str
    title: str
    description: str
    file_path: str
    duration: Optional[float] = None
    published_at: Optional[datetime] = None
    episode_number: Optional[int] = None
