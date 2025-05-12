"""
Default accounts for itsyourradio.
Only used during initial setup.
"""

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

async def ensure_default_accounts(db):
    """
    Ensure default accounts exist in the database.
    """
    # Check if admin account exists
    existing_admin = await db.users.find_one({"email": DEFAULT_ADMIN["email"]})
    
    # If admin doesn't exist, create it
    if not existing_admin:
        await db.users.insert_one(DEFAULT_ADMIN)
        print("Default admin account created")
