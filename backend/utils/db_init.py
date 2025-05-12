# Direct import without relative imports to avoid ImportError
import sys
import os
from pathlib import Path

# Add the parent directory to the path so we can import from the parent package
# This is needed because this file might be run directly
backend_dir = Path(__file__).resolve().parent.parent
sys.path.append(str(backend_dir))

from database import engine, Base, SessionLocal
from models.models import User
from utils.auth import get_password_hash
import uuid

def init_db():
    """Initialize database, create tables and default admin user"""
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
    
    return "Database initialized successfully!"

if __name__ == "__main__":
    # This allows running the script directly to initialize the database
    init_db()