# Import all utilities for easy access
import sys
from pathlib import Path

# Add the current directory to the Python path to allow imports
ROOT_DIR = Path(__file__).parent.parent
sys.path.append(str(ROOT_DIR))

# Import auth utilities
from utils.auth import verify_password, get_password_hash, create_access_token, get_current_user, get_user_role, has_role
