from ..database import engine, Base, SessionLocal
from ..models import User
from ..utils.auth import get_password_hash
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