from fastapi import FastAPI, APIRouter, Depends, HTTPException, status, File, UploadFile
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from typing import List, Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

# Import models
from models.user import User, UserCreate, UserUpdate, UserAuth, UserResponse, Token, TokenData, UserRole
from models.audio import Album, AlbumCreate, Song, SongCreate, PodcastShow, PodcastShowCreate, PodcastEpisode, PodcastEpisodeCreate
from models.blog import BlogPost, BlogPostCreate, BlogPostUpdate, ArtistPost, ArtistPostCreate, ArtistPostUpdate

# Import utilities
from utils.auth import verify_password, get_password_hash, create_access_token, get_current_user, get_user_role, has_role

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ.get('DB_NAME', 'itsyourradio_db')]

# Create the main app without a prefix
app = FastAPI(title="ItsYourRadio API")

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# --------------------------------
# User Authentication Routes
# --------------------------------
@api_router.post("/auth/register", response_model=UserResponse)
async def register_user(user: UserCreate):
    """Register a new user."""
    # Check if user with that email already exists
    existing_user = await db.users.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
        
    # Check if username is already taken
    existing_username = await db.users.find_one({"username": user.username})
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Create the new user
    hashed_password = get_password_hash(user.password)
    user_data = User(
        email=user.email,
        username=user.username,
        role=user.role,
        full_name=user.full_name
    )
    
    # Add the hashed password
    user_dict = user_data.dict()
    user_dict["hashed_password"] = hashed_password
    
    # Insert into database
    await db.users.insert_one(user_dict)
    
    # Return the user without the password
    return UserResponse(**user_dict)

@api_router.post("/auth/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """Generate an access token for a user."""
    # Find the user
    user = await db.users.find_one({"email": form_data.username})
    
    # Check if user exists and password is correct
    if not user or not verify_password(form_data.password, user.get("hashed_password", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=30)  # 30 minutes
    access_token = create_access_token(
        data={"sub": user["id"], "role": user["role"]},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@api_router.post("/auth/login", response_model=Token)
async def login(user_auth: UserAuth):
    """Login with email and password."""
    # Find the user
    user = await db.users.find_one({"email": user_auth.email})
    
    # Check if user exists and password is correct
    if not user or not verify_password(user_auth.password, user.get("hashed_password", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=30)  # 30 minutes
    access_token = create_access_token(
        data={"sub": user["id"], "role": user["role"]},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

# --------------------------------
# User Profile Routes
# --------------------------------
@api_router.get("/users/me", response_model=UserResponse)
async def get_current_user_profile(current_user = Depends(get_current_user)):
    """Get the current user's profile."""
    return current_user

@api_router.put("/users/me", response_model=UserResponse)
async def update_user_profile(user_update: UserUpdate, current_user = Depends(get_current_user)):
    """Update the current user's profile."""
    user_data = {k: v for k, v in user_update.dict().items() if v is not None}
    
    if user_data:
        user_data["updated_at"] = datetime.utcnow()
        await db.users.update_one({"id": current_user["id"]}, {"$set": user_data})
    
    updated_user = await db.users.find_one({"id": current_user["id"]})
    return updated_user

# --------------------------------
# Admin Routes
# --------------------------------
@api_router.get("/admin/users", response_model=List[UserResponse])
async def get_all_users(current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF]))):
    """Get all users (admin/staff only)."""
    users = await db.users.find().to_list(1000)
    return users

@api_router.put("/admin/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str, 
    user_update: UserUpdate, 
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF]))
):
    """Update a user (admin/staff only)."""
    user = await db.users.find_one({"id": user_id})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user_data = {k: v for k, v in user_update.dict().items() if v is not None}
    
    if user_data:
        user_data["updated_at"] = datetime.utcnow()
        await db.users.update_one({"id": user_id}, {"$set": user_data})
    
    updated_user = await db.users.find_one({"id": user_id})
    return updated_user

# --------------------------------
# Artist Routes
# --------------------------------
@api_router.get("/artists", response_model=List[UserResponse])
async def get_artists():
    """Get all artists."""
    artists = await db.users.find({"role": UserRole.ARTIST}).to_list(1000)
    return artists

@api_router.get("/artists/{artist_id}", response_model=UserResponse)
async def get_artist(artist_id: str):
    """Get an artist by ID."""
    artist = await db.users.find_one({"id": artist_id, "role": UserRole.ARTIST})
    if not artist:
        raise HTTPException(status_code=404, detail="Artist not found")
    return artist

@api_router.get("/artists/{artist_id}/albums", response_model=List[Album])
async def get_artist_albums(artist_id: str):
    """Get all albums by an artist."""
    albums = await db.albums.find({"artist_id": artist_id}).to_list(1000)
    return albums

@api_router.post("/artists/{artist_id}/albums", response_model=Album)
async def create_album(
    artist_id: str, 
    album: AlbumCreate, 
    current_user = Depends(get_current_user)
):
    """Create a new album for an artist."""
    # Check if the current user is the artist or an admin/staff
    if current_user["id"] != artist_id and current_user["role"] not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create albums for this artist"
        )
    
    album_data = Album(
        artist_id=artist_id,
        title=album.title,
        cover_art_url=album.cover_art_url,
        release_date=album.release_date,
        description=album.description
    )
    
    await db.albums.insert_one(album_data.dict())
    return album_data

@api_router.get("/artists/{artist_id}/songs", response_model=List[Song])
async def get_artist_songs(artist_id: str):
    """Get all songs by an artist."""
    songs = await db.songs.find({"artist_id": artist_id}).to_list(1000)
    return songs

@api_router.post("/artists/{artist_id}/songs", response_model=Song)
async def create_song(
    artist_id: str, 
    song: SongCreate, 
    current_user = Depends(get_current_user)
):
    """Create a new song for an artist."""
    # Check if the current user is the artist or an admin/staff
    if current_user["id"] != artist_id and current_user["role"] not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create songs for this artist"
        )
    
    song_data = Song(
        artist_id=artist_id,
        title=song.title,
        album_id=song.album_id,
        file_path=song.file_path,
        duration=song.duration,
        track_number=song.track_number
    )
    
    await db.songs.insert_one(song_data.dict())
    return song_data

@api_router.get("/artists/{artist_id}/posts", response_model=List[ArtistPost])
async def get_artist_posts(artist_id: str):
    """Get all blog posts by an artist."""
    posts = await db.artist_posts.find({"artist_id": artist_id, "is_published": True}).to_list(1000)
    return posts

@api_router.post("/artists/{artist_id}/posts", response_model=ArtistPost)
async def create_artist_post(
    artist_id: str, 
    post: ArtistPostCreate, 
    current_user = Depends(get_current_user)
):
    """Create a new blog post for an artist."""
    # Check if the current user is the artist or an admin/staff
    if current_user["id"] != artist_id and current_user["role"] not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create posts for this artist"
        )
    
    post_data = ArtistPost(
        artist_id=artist_id,
        title=post.title,
        content=post.content,
        featured_image_url=post.featured_image_url,
        is_published=post.is_published,
        published_at=post.published_at or datetime.utcnow()
    )
    
    await db.artist_posts.insert_one(post_data.dict())
    return post_data

# --------------------------------
# Podcast Routes
# --------------------------------
@api_router.get("/podcasts", response_model=List[PodcastShow])
async def get_podcasts():
    """Get all podcast shows."""
    podcasts = await db.podcast_shows.find().to_list(1000)
    return podcasts

@api_router.get("/podcasts/originals", response_model=List[PodcastShow])
async def get_original_podcasts():
    """Get all IYR Original podcast shows."""
    podcasts = await db.podcast_shows.find({"is_original": True}).to_list(1000)
    return podcasts

@api_router.get("/podcasts/classics", response_model=List[PodcastShow])
async def get_classic_podcasts():
    """Get all IYR Classic podcast shows."""
    podcasts = await db.podcast_shows.find({"is_classic": True}).to_list(1000)
    return podcasts

@api_router.get("/podcasts/{show_id}", response_model=PodcastShow)
async def get_podcast(show_id: str):
    """Get a podcast show by ID."""
    podcast = await db.podcast_shows.find_one({"id": show_id})
    if not podcast:
        raise HTTPException(status_code=404, detail="Podcast show not found")
    return podcast

@api_router.post("/podcasts", response_model=PodcastShow)
async def create_podcast(
    podcast: PodcastShowCreate, 
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF, UserRole.PODCASTER]))
):
    """Create a new podcast show."""
    podcast_data = PodcastShow(
        host_id=podcast.host_id,
        title=podcast.title,
        description=podcast.description,
        cover_art_url=podcast.cover_art_url,
        category=podcast.category,
        is_original=podcast.is_original,
        is_classic=podcast.is_classic
    )
    
    await db.podcast_shows.insert_one(podcast_data.dict())
    return podcast_data

@api_router.get("/podcasts/{show_id}/episodes", response_model=List[PodcastEpisode])
async def get_podcast_episodes(show_id: str):
    """Get all episodes for a podcast show."""
    episodes = await db.podcast_episodes.find({"show_id": show_id}).to_list(1000)
    return episodes

@api_router.post("/podcasts/{show_id}/episodes", response_model=PodcastEpisode)
async def create_podcast_episode(
    show_id: str,
    episode: PodcastEpisodeCreate,
    current_user = Depends(get_current_user)
):
    """Create a new episode for a podcast show."""
    # Get the podcast show
    show = await db.podcast_shows.find_one({"id": show_id})
    if not show:
        raise HTTPException(status_code=404, detail="Podcast show not found")
    
    # Check if the current user is the podcast host or an admin/staff
    if current_user["id"] != show["host_id"] and current_user["role"] not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create episodes for this podcast"
        )
    
    episode_data = PodcastEpisode(
        show_id=show_id,
        title=episode.title,
        description=episode.description,
        file_path=episode.file_path,
        duration=episode.duration,
        published_at=episode.published_at or datetime.utcnow(),
        episode_number=episode.episode_number
    )
    
    await db.podcast_episodes.insert_one(episode_data.dict())
    return episode_data

# --------------------------------
# Blog Routes
# --------------------------------
@api_router.get("/blog", response_model=List[BlogPost])
async def get_blog_posts():
    """Get all published blog posts."""
    posts = await db.blog_posts.find({"is_published": True}).sort("published_at", -1).to_list(1000)
    return posts

@api_router.get("/blog/{post_id}", response_model=BlogPost)
async def get_blog_post(post_id: str):
    """Get a blog post by ID."""
    post = await db.blog_posts.find_one({"id": post_id})
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
    return post

@api_router.post("/blog", response_model=BlogPost)
async def create_blog_post(
    post: BlogPostCreate, 
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF]))
):
    """Create a new blog post (admin/staff only)."""
    post_data = BlogPost(
        author_id=current_user["id"],
        title=post.title,
        content=post.content,
        featured_image_url=post.featured_image_url,
        is_published=post.is_published,
        published_at=post.published_at or datetime.utcnow()
    )
    
    await db.blog_posts.insert_one(post_data.dict())
    return post_data

@api_router.put("/blog/{post_id}", response_model=BlogPost)
async def update_blog_post(
    post_id: str, 
    post_update: BlogPostUpdate, 
    current_user = Depends(get_current_user)
):
    """Update a blog post."""
    # Get the post
    post = await db.blog_posts.find_one({"id": post_id})
    if not post:
        raise HTTPException(status_code=404, detail="Blog post not found")
    
    # Check if the current user is the author or an admin/staff
    if current_user["id"] != post["author_id"] and current_user["role"] not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this post"
        )
    
    post_data = {k: v for k, v in post_update.dict().items() if v is not None}
    
    if post_data:
        post_data["updated_at"] = datetime.utcnow()
        await db.blog_posts.update_one({"id": post_id}, {"$set": post_data})
    
    updated_post = await db.blog_posts.find_one({"id": post_id})
    return updated_post

# --------------------------------
# File Upload Routes
# --------------------------------
@api_router.post("/upload/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user = Depends(get_current_user)
):
    """Upload a profile image for the current user."""
    # Create directory if it doesn't exist
    upload_dir = Path("public_html/uploads/profile_images")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate a unique filename
    filename = f"{current_user['id']}_{datetime.now().strftime('%Y%m%d%H%M%S')}{Path(file.filename).suffix}"
    file_path = upload_dir / filename
    
    # Save the file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Update the user's profile_image_url
    image_url = f"/uploads/profile_images/{filename}"
    await db.users.update_one(
        {"id": current_user["id"]},
        {"$set": {"profile_image_url": image_url, "updated_at": datetime.utcnow()}}
    )
    
    return {"filename": filename, "url": image_url}

@api_router.post("/upload/cover-image")
async def upload_cover_image(
    file: UploadFile = File(...),
    current_user = Depends(get_current_user)
):
    """Upload a cover image for the current user."""
    # Create directory if it doesn't exist
    upload_dir = Path("public_html/uploads/cover_images")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate a unique filename
    filename = f"{current_user['id']}_{datetime.now().strftime('%Y%m%d%H%M%S')}{Path(file.filename).suffix}"
    file_path = upload_dir / filename
    
    # Save the file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Update the user's cover_image_url
    image_url = f"/uploads/cover_images/{filename}"
    await db.users.update_one(
        {"id": current_user["id"]},
        {"$set": {"cover_image_url": image_url, "updated_at": datetime.utcnow()}}
    )
    
    return {"filename": filename, "url": image_url}

@api_router.post("/upload/album-art")
async def upload_album_art(
    file: UploadFile = File(...),
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF, UserRole.ARTIST]))
):
    """Upload album artwork."""
    # Create directory if it doesn't exist
    upload_dir = Path("public_html/uploads/album_art")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate a unique filename
    filename = f"{current_user['id']}_{datetime.now().strftime('%Y%m%d%H%M%S')}{Path(file.filename).suffix}"
    file_path = upload_dir / filename
    
    # Save the file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Return the URL
    image_url = f"/uploads/album_art/{filename}"
    return {"filename": filename, "url": image_url}

@api_router.post("/upload/podcast-cover")
async def upload_podcast_cover(
    file: UploadFile = File(...),
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF, UserRole.PODCASTER]))
):
    """Upload podcast cover artwork."""
    # Create directory if it doesn't exist
    upload_dir = Path("public_html/uploads/podcast_covers")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate a unique filename
    filename = f"{current_user['id']}_{datetime.now().strftime('%Y%m%d%H%M%S')}{Path(file.filename).suffix}"
    file_path = upload_dir / filename
    
    # Save the file
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Return the URL
    image_url = f"/uploads/podcast_covers/{filename}"
    return {"filename": filename, "url": image_url}

@api_router.post("/upload/music")
async def upload_music(
    file: UploadFile = File(...),
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF, UserRole.ARTIST])),
    artist_name: Optional[str] = None,
    album_name: Optional[str] = None
):
    """Upload music file for an artist."""
    # If no artist_name is provided, use the current user's username
    if not artist_name and current_user["role"] == UserRole.ARTIST:
        artist_name = current_user["username"]
    elif not artist_name:
        raise HTTPException(status_code=400, detail="Artist name is required")
    
    # If no album_name is provided, use "Singles"
    if not album_name:
        album_name = "Singles"
    
    # Create directory structure if it doesn't exist
    upload_dir = Path(f"public_html/station/music/{artist_name}/{album_name}")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Save the file
    file_path = upload_dir / file.filename
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Return the path
    music_path = f"station/music/{artist_name}/{album_name}/{file.filename}"
    return {"filename": file.filename, "path": music_path}

@api_router.post("/upload/podcast")
async def upload_podcast(
    file: UploadFile = File(...),
    show_name: str,
    current_user = Depends(has_role([UserRole.ADMIN, UserRole.STAFF, UserRole.PODCASTER]))
):
    """Upload podcast episode file."""
    # Create directory structure if it doesn't exist
    upload_dir = Path(f"public_html/station/podcasts/{show_name}")
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Save the file
    file_path = upload_dir / file.filename
    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())
    
    # Return the path
    podcast_path = f"station/podcasts/{show_name}/{file.filename}"
    return {"filename": file.filename, "path": podcast_path}

# --------------------------------
# RSS Feed Routes
# --------------------------------
@api_router.get("/podcasts/{show_id}/rss")
async def get_podcast_rss_feed(show_id: str):
    """Get the RSS feed for a podcast show."""
    # Get the podcast show
    show = await db.podcast_shows.find_one({"id": show_id})
    if not show:
        raise HTTPException(status_code=404, detail="Podcast show not found")
    
    # Get the podcast episodes
    episodes = await db.podcast_episodes.find({"show_id": show_id}).sort("published_at", -1).to_list(1000)
    
    # Get the host information
    host = await db.users.find_one({"id": show["host_id"]})
    host_name = host["full_name"] or host["username"] if host else "Unknown Host"
    
    # Build the RSS feed
    rss = f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>{show["title"]}</title>
    <description>{show["description"]}</description>
    <link>{os.environ.get('WEBSITE_URL', 'https://itsyourradio.com')}/podcasts/{show_id}</link>
    <language>en-us</language>
    <itunes:author>{host_name}</itunes:author>
    <itunes:owner>
      <itunes:name>{host_name}</itunes:name>
      <itunes:email>podcasts@itsyourradio.com</itunes:email>
    </itunes:owner>
    <itunes:image href="{show.get('cover_art_url', '')}" />
    <itunes:category text="{show.get('category', 'Music')}" />
    <itunes:explicit>false</itunes:explicit>
    """
    
    # Add episodes
    for episode in episodes:
        published_date = episode["published_at"].strftime("%a, %d %b %Y %H:%M:%S +0000")
        episode_url = f"{os.environ.get('WEBSITE_URL', 'https://itsyourradio.com')}/{episode['file_path']}"
        
        rss += f"""
    <item>
      <title>{episode["title"]}</title>
      <description>{episode["description"]}</description>
      <pubDate>{published_date}</pubDate>
      <enclosure url="{episode_url}" length="0" type="audio/mpeg" />
      <itunes:duration>{episode.get('duration', 0)}</itunes:duration>
      <itunes:explicit>false</itunes:explicit>
      <guid isPermaLink="false">{episode["id"]}</guid>
    </item>
        """
    
    rss += """
  </channel>
</rss>
    """
    
    return {"rss": rss}

# Base route
@api_router.get("/")
async def root():
    return {"message": "Welcome to ItsYourRadio API"}

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

# Shutdown event
@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
