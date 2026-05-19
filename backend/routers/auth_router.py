from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone 
import os, shutil, re
from database import get_db
from models import User
from schemas import UserLogin
from auth import pwd_context, create_access_token, get_current_user

router = APIRouter(tags=["Authentication"])

@router.post("/api/register")
def register_user(
    first_name: str = Form(...),
    middle_name: str = Form(""),
    last_name: str = Form(...),
    email: str = Form(...),
    student_number: str = Form(...),
    password: str = Form(...),
    course: str = Form(...),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=409, detail="Email already registered")
    if db.query(User).filter(User.student_number == student_number).first():
        raise HTTPException(status_code=409, detail="Student ID already registered")
    
    if (len(password) < 12 or 
        not re.search(r'[A-Z]', password) or 
        not re.search(r'[a-z]', password) or 
        not re.search(r'[0-9]', password) or 
        not re.search(r'[.,?!@#$%]', password)):
        raise HTTPException(
            status_code=400, 
            detail="Password must be at least 12 characters and include an uppercase letter, lowercase letter, number, and special character."
        )

    file_path = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/user_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

    hashed_password = pwd_context.hash(password)
    new_user = User(
        first_name=first_name,
        middle_name=middle_name,
        last_name=last_name,
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

    # Handle roles if stored as comma-separated string
    roles = []
    if isinstance(db_user.role, str):
        roles = [r.strip() for r in db_user.role.split(",")]
    elif db_user.role:
        roles = [db_user.role]
    else:
        roles = ["Student"]

    # Generate initial token for primary role
    selected_role = roles[0]

    access_token = create_access_token(
        data={
            "sub": db_user.email,
            "role": selected_role
        },
        expires_delta=timedelta(hours=24)
    )
    
    # Combined Return Payload: 
    # Satisfies both the new multi-role logic and the Flutter app's 'is_student_officer' dependency
    return {
        "multi_role": len(roles) > 1,
        "roles": roles,
        "email": db_user.email,
        "access_token": access_token, 
        "token_type": "bearer", 
        "user": {
            "role": db_user.role,
            "is_student_officer": getattr(db_user, 'is_student_officer', False),
            "permissions": getattr(db_user, 'permissions', [])
        }
    }

@router.post("/api/select-role")
def select_role(data: dict, db: Session = Depends(get_db)):
    email = data.get("email")
    selected_role = data.get("role")

    db_user = db.query(User).filter(User.email == email).first()

    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")

    roles = []
    if isinstance(db_user.role, str):
        roles = [r.strip() for r in db_user.role.split(",")]
    elif db_user.role:
        roles = [db_user.role]

    # Temporarily grant authorization if they have the is_student_officer flag
    if getattr(db_user, 'is_student_officer', False):
        if "Staff" not in roles: roles.append("Staff")
        if "Student" not in roles: roles.append("Student")

    if selected_role not in roles:
        raise HTTPException(status_code=403, detail="Invalid role")

    access_token = create_access_token(
        data={
            "sub": db_user.email,
            "role": selected_role
        },
        expires_delta=timedelta(hours=24)
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": selected_role,
        "permissions": getattr(db_user, 'permissions', [])
    }

@router.get("/api/users/me")
def get_user_profile(current_user: User = Depends(get_current_user)):
    full_name = f"{current_user.first_name} {current_user.middle_name} {current_user.last_name}".replace("  ", " ").strip()
    return {
        "first_name": current_user.first_name,
        "middle_name": current_user.middle_name,
        "last_name": current_user.last_name,
        "full_name": full_name,
        "student_number": current_user.student_number,
        "email": current_user.email,
        "role": current_user.role,
        "profile_pic_url": current_user.profile_pic_url
    }