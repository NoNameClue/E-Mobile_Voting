from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
import os, shutil
from database import get_db
from models import User
from schemas import UserLogin
from auth import pwd_context, create_access_token, get_current_user

router = APIRouter(tags=["Authentication"])

@router.post("/api/register")
def register_user(
    full_name: str = Form(...),
    email: str = Form(...),
    student_number: str = Form(...),
    password: str = Form(...),
    course: str = Form(...),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    # 1. Check for duplicates
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    if db.query(User).filter(User.student_number == student_number).first():
        raise HTTPException(status_code=400, detail="Student ID already registered")

    # 2. Handle Profile Picture Upload
    file_path = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/user_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

    # 3. Hash password and save user
    hashed_password = pwd_context.hash(password)
    new_user = User(
        full_name=full_name,
        email=email,
        student_number=student_number,
        course=course,
        password_hash=hashed_password,
        role="Student",
        created_at=datetime.now(timezone.utc),
        profile_pic_url=file_path
    )
    db.add(new_user)
    db.commit()
    return {"message": "User registered successfully"}

@router.post("/api/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user or not pwd_context.verify(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    if not db_user.is_active:
        raise HTTPException(status_code=403, detail="Account is disabled")

    access_token = create_access_token(
        data={"sub": db_user.email, "role": db_user.role},
        expires_delta=timedelta(hours=24)
    )
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "role": db_user.role,
        "permissions": db_user.permissions
    }

@router.get("/api/users/me")
def get_user_profile(current_user: User = Depends(get_current_user)):
    return {
        "full_name": current_user.full_name,
        "student_number": current_user.student_number,
        "email": current_user.email,
        "role": current_user.role,
        "profile_pic_url": current_user.profile_pic_url
    }