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
