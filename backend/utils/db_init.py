from ..database import engine, Base, SessionLocal
from ..models.sql_models import User
from .auth import get_password_hash
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
    # Create tables
    Base.metadata.create_all(bind=engine)
    
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
    except Exception as e:
        db.rollback()
        print(f"Error creating default admin: {e}")
    finally:
        db.close()
