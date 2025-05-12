from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
import uuid


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True


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
        orm_mode = True