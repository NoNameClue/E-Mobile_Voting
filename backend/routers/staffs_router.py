from fastapi import APIRouter, Depends, HTTPException, File, UploadFile, Form
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timezone
import os, shutil
from database import get_db
from models import User
from schemas import PermissionsUpdate
from auth import pwd_context

router = APIRouter(tags=["Staffs"])

@router.get("/api/officers")
def get_all_staff(db: Session = Depends(get_db)):
    return db.query(User).filter(User.role == "Staff").all()

@router.post("/api/officers")
def create_staff(
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    max_id = db.query(func.max(User.user_id)).scalar() or 0
    dummy_student_number = f"STAFF-{max_id + 1}"

    file_path = None
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/staff_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)

    hashed_password = pwd_context.hash(password)
    new_staff = User(
        full_name=full_name,
        email=email,
        student_number=dummy_student_number,
        course="N/A",
        password_hash=hashed_password,
        role="Staff",
        is_active=True,
        created_at=datetime.now(timezone.utc),
        profile_pic_url=file_path,
        permissions=[]
    )
    db.add(new_staff)
    db.commit()
    return {"message": "Staff created successfully"}

@router.put("/api/officers/{user_id}")
def update_staff(
    user_id: int,
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(None),
    photo: UploadFile = File(None),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")

    if email != user.email and db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already in use")

    user.full_name = full_name
    user.email = email
    
    if password and password.strip():
        user.password_hash = pwd_context.hash(password)
        
    if photo and photo.filename:
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        safe_filename = photo.filename.replace(" ", "_")
        file_path = f"uploads/staff_{timestamp}_{safe_filename}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        user.profile_pic_url = file_path

    db.commit()
    return {"message": "Staff updated successfully"}

@router.delete("/api/officers/{user_id}")
def delete_staff(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")
        
    db.delete(user)
    db.commit()
    return {"message": "Staff deleted successfully"}

@router.put("/api/officers/{user_id}/permissions")
def update_permissions(user_id: int, perms: PermissionsUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id, User.role == "Staff").first()
    if not user:
        raise HTTPException(status_code=404, detail="Staff not found")
    
    user.permissions = perms.permissions
    db.commit()
    return {"message": "Permissions updated successfully"}