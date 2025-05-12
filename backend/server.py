from fastapi import FastAPI, APIRouter
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import sys
from pathlib import Path

# Add current directory to path
current_dir = Path(__file__).resolve().parent
sys.path.append(str(current_dir))

# Import database and initialization
from database import engine, Base, SessionLocal
from utils.db_init import init_db

# Import routers
from routers import auth, users

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Set up CORS
origins = [
    "*",  # Allow all origins for development
    # Add specific origins for production
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

# Include other routers
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])

# Add API router to app
app.include_router(api_router)

# Root endpoint for API
@app.get("/api/")
async def root():
    return {"message": "Welcome to itsyourradio API"}

# Create tables on startup if they don't exist
@app.on_event("startup")
async def startup_db_client():
    try:
        # Create tables
        Base.metadata.create_all(bind=engine)
        print("Database tables created successfully!")
        
        # Initialize database with admin user
        init_db()
    except Exception as e:
        print(f"Error initializing database: {e}")

# Close database connection on shutdown
@app.on_event("shutdown")
async def shutdown_db_client():
    # No action needed for SQLAlchemy, connections are handled by the session
    pass
