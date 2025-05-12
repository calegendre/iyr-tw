from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from datetime import timedelta
from ..models import User, UserCreate, UserResponse, UserAuth, Token
from ..utils.auth import verify_password, get_password_hash, create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES
from motor.motor_asyncio import AsyncIOMotorClient
import logging

# Create the auth router
router = APIRouter(
    prefix="/auth",
    tags=["authentication"],
    responses={401: {"description": "Unauthorized"}},
)

logger = logging.getLogger(__name__)

@router.post("/register", response_model=UserResponse)
async def register_user(user: UserCreate, db: AsyncIOMotorClient = Depends(lambda: None)):
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

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: AsyncIOMotorClient = Depends(lambda: None)):
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
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["id"], "role": user["role"]},
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=Token)
async def login(user_auth: UserAuth, db: AsyncIOMotorClient = Depends(lambda: None)):
    """Login with email and password."""
    return await login_for_access_token(OAuth2PasswordRequestForm(username=user_auth.email, password=user_auth.password), db)
