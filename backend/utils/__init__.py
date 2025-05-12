# Import utility functions
from utils.auth import (
    verify_password,
    get_password_hash,
    authenticate_user,
    create_access_token,
    get_current_user,
    get_current_active_user,
    is_admin,
    is_staff_or_admin
)

from utils.db_init import init_db