from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text, DateTime, Table
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from datetime import datetime
import sys
from pathlib import Path

# Add the parent directory to the path so we can import from the parent package
backend_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(backend_dir))

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