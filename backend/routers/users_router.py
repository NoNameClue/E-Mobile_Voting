from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_
from database import get_db
from models import User

# 🛠️ ADDED IMPORTS for the new update endpoint
from pydantic import BaseModel
from typing import Optional, List
from auth import pwd_context 

router = APIRouter(tags=["Users"])

# 🛠️ ADDED SCHEMA: Defined here so you don't have to touch schemas.py
class UserAdminUpdate(BaseModel):
    course: Optional[str] = None
    password: Optional[str] = None
    is_student_officer: Optional[bool] = None
    permissions: Optional[List[str]] = None


@router.get("/api/users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [{**u.__dict__, "full_name": f"{u.first_name} {u.middle_name} {u.last_name}".replace("  ", " ").strip()} for u in users]


@router.get("/api/admin/students")
def get_paginated_students(
    skip: int = Query(0, description="How many records to skip"),
    limit: int = Query(20, description="How many records to return"),
    search: str = Query(None, description="Search by name or ID"),
    db: Session = Depends(get_db)
):
    # Start the query
    query = db.query(User).filter(User.role == "Student")
    
    # OPTIMIZATION: Perform search on the server using indexes
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                User.student_number.like(search_term),
                User.first_name.like(search_term),
                User.last_name.like(search_term)
            )
        )
    
    # Sort by newest first
    query = query.order_by(User.created_at.desc())
    
    # Get total count for frontend pagination math
    total_count = query.count()
    
    # Apply Limit and Offset (Chunking)
    students = query.offset(skip).limit(limit).all()
    
    # Return lightweight payload
    results = [
        {
            "user_id": s.user_id,
            "full_name": f"{s.first_name} {s.middle_name} {s.last_name}".replace("  ", " ").strip(),
            "student_number": s.student_number,
            "course": s.course,
            "is_active": s.is_active,
            "created_at": s.created_at.isoformat() if s.created_at else None,
            "profile_pic_url": s.profile_pic_url,
            "is_student_officer": getattr(s, 'is_student_officer', False), # 🛠️ Ensured frontend knows if they are an officer
            "permissions": getattr(s, 'permissions', [])
        } for s in students
    ]
    
    return {
        "total": total_count,
        "items": results
    }


@router.put("/api/admin/students/{user_id}/toggle")
async def toggle_student_status(user_id: int, request: Request, db: Session = Depends(get_db)):
    student = db.query(User).filter(User.user_id == user_id, User.role == "Student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    
    try:
        data = await request.json()
        if "is_active" in data:
            student.is_active = bool(data["is_active"])
        elif "status" in data:
            student.is_active = bool(data["status"])
        else:
            student.is_active = not student.is_active
    except Exception:
        student.is_active = not student.is_active

    db.commit()
    return {"message": f"Status updated successfully to {student.is_active}"}


# 🛠️ NEW ENDPOINT: This fixes your 404 error when saving from the Edit Modal
@router.put("/api/admin/users/{user_id}")
def update_user_admin(user_id: int, update_data: UserAdminUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.user_id == user_id).first()
    
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Update only the fields that were provided by the frontend
    if update_data.course is not None:
        db_user.course = update_data.course
        
    if update_data.password: 
        db_user.password_hash = pwd_context.hash(update_data.password)
        
    if update_data.is_student_officer is not None:
        db_user.is_student_officer = update_data.is_student_officer
        
    if update_data.permissions is not None:
        db_user.permissions = update_data.permissions
        
    db.commit()
    return {"message": "User updated successfully"}